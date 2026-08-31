#!/usr/bin/env bash
# ============================================================================
# Time Recorder -> GitHub 覆盖式上传脚本
#
# 功能：
#   - 将本地全部变更（新增/修改/删除）以"覆盖更新"方式推送到 GitHub 远程仓库
#     （git add -A 会追踪同名文件的修改，push 后远程文件即被本地版本覆盖，
#      不是新建副本；若本地删除了文件，远程对应文件也会被删除）
#   - 自动处理：未初始化仓库(init)、无远程(添加 remote)、首次提交、分支命名
#   - 推送策略：默认普通推送（非强制）；遇到远程有本地没有的新提交(冲突)时，
#     提供 --force-with-lease（安全强制，只覆盖自己上次拉取过的远端状态）
#   - 鉴权：自动检测错误并给出指引（HTTPS PAT / SSH / gh CLI）
#   - 结束输出：远程仓库、分支、提交 hash、变更摘要，一目了然
#
# 用法：
#   bash git-push.sh                               # 默认配置
#   bash git-push.sh "本次更新说明"                 # 自定义提交信息
#   bash git-push.sh -f "覆盖远程旧版本"            # 允许安全强制推送
#   bash git-push.sh --repo <URL> --branch <名称>   # 命令行覆盖仓库/分支
#
# 默认配置（改这里或传参数均可）：
# ============================================================================

set -u   # 使用未定义变量时报错（但不 set -e，错误分支自己处理并给出说明）

# ---------------- 可配置默认值 ----------------
REPO_URL="${REPO_URL:-}"      # 目标仓库，如 https://github.com/<user>/<repo>.git
                              # 或 git@github.com:<user>/<repo>.git（SSH）
BRANCH="${BRANCH:-main}"      # 目标分支
REMOTE_NAME="origin"          # 远程名
DEFAULT_MSG="update $(date '+%Y-%m-%d %H:%M')"

FORCE=0
MSG=""

# ---------------- 参数解析 ----------------
while [ $# -gt 0 ]; do
  case "$1" in
    -f|--force)  FORCE=1; shift ;;
    --repo)      REPO_URL="$2"; shift 2 ;;
    --branch)    BRANCH="$2"; shift 2 ;;
    -h|--help)
      echo "用法: bash git-push.sh [-f] [\"提交信息\"] [--repo <URL>] [--branch <名称>]"
      exit 0 ;;
    -*)
      echo "未知参数: $1（用 --help 查看用法）"; exit 1 ;;
    *)
      MSG="$1"; shift ;;
  esac
done
[ -z "$MSG" ] && MSG="$DEFAULT_MSG"

# ---------------- 环境检查 ----------------
command -v git >/dev/null 2>&1 || { echo "❌ 未找到 git，请先安装 Git for Windows"; exit 1; }
cd "$(dirname "$0")" || exit 1
echo "📁 工作目录: $(pwd)"

# ---------------- 1. 初始化仓库（如需要） ----------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "📦 当前目录不是 git 仓库，执行 git init ..."
  git init -q && git branch -M "$BRANCH" 2>/dev/null
fi

# ---------------- 2. 确保远程仓库存在 ----------------
if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  if [ -z "$REPO_URL" ]; then
    echo "❌ 未配置远程仓库。请二选一："
    echo "   1) 编辑本脚本顶部 REPO_URL 变量"
    echo "   2) 命令行: bash git-push.sh --repo https://github.com/<user>/<repo>.git"
    echo "   （仓库需先在 GitHub 上创建；或先运行 git remote add origin <URL>）"
    exit 1
  fi
  git remote add "$REMOTE_NAME" "$REPO_URL" && echo "🔗 已添加远程: $REPO_URL"
else
  echo "🔗 远程: $(git remote get-url "$REMOTE_NAME")"
fi

# ---------------- 3. 暂存全部变更（覆盖更新的关键） ----------------
git add -A
if git diff --cached --quiet; then
  echo "ℹ️  没有待提交的变更（工作区与远程一致，推送内容为空）"
else
  echo "✏️  提交信息: $MSG"
  git commit -q -m "$MSG" || { echo "❌ 提交失败"; exit 1; }
fi

# ---------------- 4. 确保本地分支名正确 ----------------
git branch -M "$BRANCH" 2>/dev/null || true

# ---------------- 5. 推送 ----------------
echo "🚀 正在推送 $BRANCH -> $REMOTE_NAME/$BRANCH ..."
if [ "$FORCE" = 1 ]; then
  # 强制推送：用 --force-with-lease 并提供"期望的远程值"。
  # 期望值通过 ls-remote 实时获取（不依赖本地 remote-tracking 引用——
  # 那个引用在"从未 fetch 过/此前推送失败"时不存在，会让 lease 误判为
  # 空基准而拒绝覆盖，表现为"用了 -f 还是失败"）。
  # 实时值仍能保护：ls-remote 之后若他人抢先推送，期望值不匹配 → 拒绝。
  EXPECT=$(git ls-remote "$REMOTE_NAME" "refs/heads/$BRANCH" 2>/dev/null | cut -f1)
  if [ -n "$EXPECT" ]; then
    ERR=$(git push --force-with-lease="$BRANCH":"$EXPECT" "$REMOTE_NAME" "$BRANCH" 2>&1)
  else
    # 远程还没有这个分支（首次推送），普通推送即可，不存在覆盖问题。
    ERR=$(git push "$REMOTE_NAME" "$BRANCH" 2>&1)
  fi
else
  ERR=$(git push "$REMOTE_NAME" "$BRANCH" 2>&1)
fi
RC=$?

# ---------------- 6. 结果分析 ----------------
if [ $RC -eq 0 ]; then
  echo ""
  echo "✅ 推送成功！"
  echo "   远程仓库: $(git remote get-url "$REMOTE_NAME")"
  echo "   分支    : $BRANCH"
  echo "   提交    : $(git rev-parse --short HEAD) ($(git log -1 --pretty=%s))"
  git log -1 --stat --format='' | sed '/^$/d' | head -15
  exit 0
fi

# ---- 推送失败：分类诊断 ----
echo "$ERR" | grep -qiE "non-fast-forward|rejected|fetch first|have diverged|behind" && CONFLICT=1 || CONFLICT=0
echo "$ERR" | grep -qiE "authentication failed|could not read Username|invalid username|403|remote: Invalid|Permission denied \(publickey\)" && AUTH=1 || AUTH=0
echo "$ERR" | grep -qiE "Repository not found|not found" && NO_REPO=1 || NO_REPO=0

echo "❌ 推送失败，原因如下："
echo "$ERR" | tail -5

if [ "$CONFLICT" = 1 ]; then
  echo ""
  echo "💡 远程分支有本地没有的新提交（冲突）。覆盖远程需要强制推送："
  echo "   bash git-push.sh -f \"$MSG\""
  echo "   （--force-with-lease 是安全强制：仅覆盖你上次拉取过的远端状态，不会误伤他人推送）"
elif [ "$AUTH" = 1 ]; then
  echo ""
  echo "🔑 鉴权失败，按顺序尝试："
  echo "   1) SSH 方式（推荐，一劳永逸）："
  echo "      ssh-keygen -t ed25519 -C \"you@example.com\"   # 生成密钥（回车到底）"
  echo "      复制 ~/.ssh/id_ed25519.pub 内容，粘贴到 GitHub → Settings → SSH and GPG keys → New SSH key"
  echo "      bash git-push.sh --repo git@github.com:<user>/<repo>.git"
  echo "   2) HTTPS + 个人访问令牌(PAT)："
  echo "      GitHub → Settings → Developer settings → Personal access tokens → 勾选 repo 权限生成"
  echo "      git remote set-url origin https://<你的用户名>:<PAT>@github.com/<user>/<repo>.git"
  echo "   3) 若装了 GitHub CLI：gh auth login 后重试"
elif [ "$NO_REPO" = 1 ]; then
  echo ""
  echo "🏠 远程仓库不存在或当前账号无权限，请："
  echo "   1) 到 github.com 创建同名空仓库（不要勾选初始化 README）"
  echo "   2) 或核对 REPO_URL 拼写/账号权限"
else
  echo ""
  echo "ℹ️  未能自动分类的错误，请按上面输出排查；网络代理问题可用: git config --global http.proxy 检查"
fi
exit $RC
