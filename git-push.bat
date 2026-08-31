@echo off
REM ============================================================
REM  Time Recorder -> GitHub 覆盖式推送（Windows 双击入口）
REM  双击即用；如需自定义仓库/分支，先编辑 git-push.sh 顶部变量
REM ============================================================
cd /d "%~dp0"
where bash >nul 2>nul
if errorlevel 1 (
  echo [错误] 未找到 Git Bash，请先安装 Git for Windows：https://git-scm.com/
  pause
  exit /b 1
)
echo 开始推送，请稍候...
bash git-push.sh %*
echo.
pause
