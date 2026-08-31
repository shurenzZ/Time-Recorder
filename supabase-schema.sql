-- =====================================================================
-- Time Recorder · Supabase 数据库结构
-- 在 Supabase 后台 → SQL Editor 中完整粘贴并执行本文件
-- =====================================================================

-- 任务表：每个用户可拥有多个任务，子任务以 jsonb 数组存放
create table if not exists public.tasks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  tag        text not null default '其他',
  subtasks   jsonb not null default '[]'::jsonb,   -- [{ "id": "...", "name": "...", "done": false }]
  done       boolean not null default false,        -- 整个任务是否完成
  created_at timestamptz not null default now()
);
create index if not exists tasks_user_idx on public.tasks(user_id);

-- 已存在的旧表可能没有 done 列：补列（新版安装会被 create table 直接带上，互不影响）
alter table public.tasks add column if not exists done boolean not null default false;
-- 旧表可能缺 note 列（任务备注）：补列。缺它会导致 saveTask 写入失败 → 任务留在本地非 UUID id →
-- 连带 records.task_id 写入 uuid 列失败 → 任务与记录都进不了云端、跨设备不同步。
alter table public.tasks add column if not exists note text not null default '';

-- 记录表：每次计时的结果
create table if not exists public.records (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  task_id      uuid,
  task_name    text not null,
  tag          text not null default '其他',
  subtask      text default '',
  duration_sec integer not null,
  record_date  date not null,                       -- 归属日期（跨天记开始当天）
  start_ts     timestamptz not null,
  end_ts       timestamptz not null,
  created_at   timestamptz not null default now()
);
create index if not exists records_user_idx on public.records(user_id);
create index if not exists records_date_idx on public.records(record_date);

-- 清单 / 每日计划表：用户按日期安排任务，字段均可选（内容/标签/时间/重要程度）
create table if not exists public.plans (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  plan_date   date not null default current_date,
  content     text default '',
  tag         text default '',
  plan_time   text default '',                       -- 具体时间，如 09:30（可选）
  importance  text default '' check (importance in ('', 'high', 'medium', 'low')),
  done        boolean default false,                 -- 是否完成（清单勾选）
  created_at  timestamptz not null default now()
);
create index if not exists plans_user_date_idx on public.plans(user_id, plan_date);

-- 开启行级安全（RLS）：未授权一律看不到
alter table public.tasks   enable row level security;
alter table public.records enable row level security;
alter table public.plans   enable row level security;

-- 策略：只允许本人对自己的数据做全部操作
drop policy if exists "own tasks"   on public.tasks;
drop policy if exists "own records" on public.records;
drop policy if exists "own plans"   on public.plans;

create policy "own tasks" on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own records" on public.records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own plans" on public.plans
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 开启实时订阅（电脑/手机一端改动，另一端秒级刷新）
do $$
begin
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime'
  ) then
    -- 极少数旧项目未建发布，这里兜底（通常已存在，忽略报错即可）
    null;
  end if;
end $$;

-- 把表加入实时发布（幂等：已在发布中则跳过，避免重复执行报 42710 错）
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks'
  ) then
    alter publication supabase_realtime add table public.tasks;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'records'
  ) then
    alter publication supabase_realtime add table public.records;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'plans'
  ) then
    alter publication supabase_realtime add table public.plans;
  end if;
end $$;

-- =====================================================================
-- 倒数日表（支持每个用户多条倒数日：id + 名称 + 目标日期）
-- 若已存在旧版单条结构（user_id 为主键，无 id/name 列），会自动迁移数据
-- =====================================================================

-- 若旧表存在且没有 id 列，则把旧数据迁移到临时表后删除旧表
-- （旧数据会保留默认名称「目标日期」）
do $$
declare
  has_old boolean;
begin
  select exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'countdown'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'countdown' and column_name = 'id'
  ) into has_old;

  if has_old then
    create temp table if not exists _cd_old as
      select user_id, target_date from public.countdown where target_date is not null and target_date <> '';
    drop table public.countdown;
  end if;
end $$;

-- 创建新版倒数日表
create table if not exists public.countdown (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text,
  target_date text,
  updated_at  timestamptz not null default now()
);

create index if not exists countdown_user_idx on public.countdown(user_id);

-- 迁移旧数据（默认名称为「目标日期」）
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'pg_temp' and table_name = '_cd_old') then
    insert into public.countdown (user_id, name, target_date)
      select user_id, '目标日期', target_date from _cd_old;
    drop table if exists _cd_old;
  end if;
end $$;

alter table public.countdown enable row level security;

drop policy if exists "own countdown" on public.countdown;
create policy "own countdown" on public.countdown
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 把倒数日表加入实时发布（电脑/手机一端改动，另一端秒级刷新）
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'countdown'
  ) then
    alter publication supabase_realtime add table public.countdown;
  end if;
end $$;
