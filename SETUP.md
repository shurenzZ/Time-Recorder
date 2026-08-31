# Time Recorder · 云同步配置说明（Supabase）

按以下步骤把应用接入 Supabase，实现电脑与手机同一账号数据实时共享。

## 1. 创建 Supabase 项目
1. 打开 https://supabase.com ，用 GitHub 注册并登录。
2. 新建项目（New Project）：填名称、设数据库密码（记下），区域选离你近的。
3. 等待项目初始化完成（约 1 分钟）。

## 2. 建表与权限
1. 左侧菜单 → **SQL Editor** → **New query**。
2. 把本目录下的 `supabase-schema.sql` 全部内容粘贴进去，点击 **Run**。
   - 会创建 `tasks`、`records`、`plans` 三张表，开启 RLS（行级安全，别人看不到你的数据），并开启实时订阅。
   - `plans` 为「每日清单」功能所用：存用户按日期安排的任务（内容/标签/时间/重要程度，均可选）。

## 3. 获取密钥
1. 左侧菜单 → **Project Settings**（齿轮）→ **API**。
2. 复制两样东西：
   - **Project URL**（形如 `https://xxxx.supabase.co`）
   - **anon public** 密钥（很长的字符串）

## 4. 填入 HTML
打开 `Time Recorder.html`，在文件顶部 `<script>` 附近找到这两行占位常量，替换成你的真实值：

```js
const SUPABASE_URL = 'https://你的项目.supabase.co';
const SUPABASE_ANON_KEY = '你的anon密钥';
```

> anon key 设计上可公开，真正的安全由 RLS 保证（用户只能读写自己的数据）。

## 5. 关闭"邮件确认"（重要）
默认 Supabase 注册后会发确认邮件，新用户无法立即登录。为简化体验：
1. 左侧菜单 → **Authentication** → **Providers** → **Email**。
2. 关闭 **Confirm email**（确认邮件）开关，Save。
> 这样用"用户名+密码"即可直接注册并登录。若你希望更安全可保留邮件确认。

## 6. 使用
- 用浏览器打开 `Time Recorder.html`（电脑、手机都打开同一个文件 / 同一个网址）。
- 首次输入用户名+密码即自动注册；之后同一用户名在任意设备登录，数据都会同步。
- 一端新增任务或停止计时，另一端几秒内自动出现（实时订阅）。
- 断网时数据暂存本地，恢复网络后自动与云端合并。

## 7. 可选：静态托管（体验最稳）
为避免 `file://` 打开的兼容问题，建议把 `Time Recorder.html` 托管到静态站点，两端用同一网址打开：
- **GitHub Pages** / **Netlify** / **Vercel** / **Cloudflare Pages**：上传单个 HTML 即可。
- 或 Supabase 自带：Storage 上传后设为公开，复制访问链接。

## 常见问题
- **登录提示 invalid API key**：检查第 4 步的 URL / anon key 是否填对、有无多余空格。
- **注册后登录失败**：确认第 5 步已关闭邮件确认；或等待邮件确认后再登。
- **数据不同步**：确认两端登录的是**同一个用户名**；检查网络；刷新页面重试。
- **想导出/备份**：设置页仍提供"导出 Excel(CSV)"与"导出/导入备份 JSON"，作为离线兜底。
