# Time Recorder

一款单文件、跨平台的时间记录与任务管理工具：计时（正/倒计时）、每日清单、历史记录、统计图表、倒数日、AI 助手，支持云端多设备同步与任务到点提醒。

一个 `Time Recorder.html` 同时跑在浏览器、Windows 桌面端（exe / 安装包）与鸿蒙 HarmonyOS 手机上——核心逻辑一套代码，外壳分别用 pywebview 与 ArkTS Web 组件封装。

## ✨ 功能特性

- **计时器**：正向计时 / 倒计时 / 目标时长，到点提醒、自动记录
- **每日清单**：计划时间（到点应用内 + 系统级双重提醒）、完成状态、优先级、备注
- **历史记录与统计**：按日期筛选，完成率、优先级分布图表（Chart.js）
- **倒数日**：纪念日 / 考试 / 事件倒计时
- **AI 助手**：基于阿里云 DashScope，支持追问的翻译、信息聚合、文档解析
- **跨设备云同步**：Supabase（PostgreSQL + Realtime），多设备实时同步，离线自动重试
- **记住登录**：Windows 桌面端凭据经系统凭据库（Credential Manager）安全持久化，启动免密、锁屏强制重认证

## 📦 支持平台

| 平台 | 形态 | 说明 |
|---|---|---|
| 浏览器 / 网页 | 单文件 HTML | 直接打开 `Time Recorder.html` 即可运行 |
| Windows | 免安装 exe | pywebview + WebView2，双击即用（见上方「📦 下载」） |
| Windows | 安装包 | NSIS 打包，开始菜单 / 桌面快捷方式 / 卸载程序（需本地自行构建） |
| HarmonyOS | `.hap` | Stage 模型 ArkTS 工程，支持鸿蒙系统级通知（需 DevEco 构建） |

## 🚀 快速开始

- **网页版**：直接打开 `Time Recorder.html`，或访问在线版 **https://shurenzz.github.io/Time-Recorder/**（GitHub Pages 自动部署）。
- **Windows 桌面版**：从 **GitHub Release** 下载免安装 exe（见下方「📦 下载」），双击即用；或按「🛠 开发构建」自行打包。

> 网页版在线地址：https://shurenzz.github.io/Time-Recorder/（GitHub Pages，随仓库 `main` 分支自动更新）
> 仓库地址：https://github.com/shurenzZ/Time-Recorder

## 📦 下载

| 平台 | 版本 | 下载 |
|---|---|---|
| Windows 免安装 exe | v1.0.0 | ⬇ [Time-Recorder-Windows-x64.exe](https://github.com/shurenzZ/Time-Recorder/releases/download/v1.0.0/Time-Recorder-Windows-x64.exe) |
| 全部 Release | — | [Releases 页](https://github.com/shurenzZ/Time-Recorder/releases) |

> ⚠️ Windows 版需系统装有 **Microsoft Edge WebView2 运行时**（Win10/11 多数自带）；exe 为构建产物，不入仓库，随 Release 发布。

## 🔧 技术栈

- **前端**：原生 HTML / CSS / JavaScript（无框架，单文件）+ Chart.js
- **云同步**：Supabase（认证 + PostgreSQL + Realtime subscription）
- **AI**：DashScope 兼容模式（浏览器直连或可选代理）
- **Windows 桌面端**：pywebview（Edge WebView2）+ PyInstaller + NSIS
- **鸿蒙端**：ArkTS（Stage 模型）+ `@kit.ArkWeb` + `@kit.NotificationKit`

## 📁 目录结构

```
├── Time Recorder.html        # 权威源码（单文件应用，三端共用，改动以此为准）
├── supabase-schema.sql       # Supabase 建表脚本（唯一权威，部署请用此版本）
├── dist/index.html           # 网页部署副本（= Time Recorder.html 的复制）
├── windows/                  # Windows 桌面端（wrapper.py / installer.nsi / README）
│   ├── Time Recorder.html    # 桌面端打包用副本（= 权威 HTML 的复制）
│   ├── wrapper.py            # pywebview 桌面封装（打包入口）
│   └── installer.nsi         # NSIS 安装包脚本
├── harmony-app/              # 鸿蒙 ArkTS 工程（构建见其 README）
│   └── .../rawfile/index.html# 鸿蒙端 Web 加载的副本（= 权威 HTML 的复制）
├── gen_manual_pdf.py         # 从手册内容生成「使用手册.pdf」（需 reportlab）
├── Time Recorder 使用手册.pdf# 生成产物（由 gen_manual_pdf.py 生成）
├── sync-html.bat / .sh       # 把权威 HTML 同步到 dist / windows / harmony 三处副本
├── git-push.sh / git-push.bat# GitHub 推送脚本（双击用 .bat）
└── SETUP.md                  # 环境与部署说明
```

> 构建产物（`windows/dist/`、`windows/build/`、`windows/Time Recorder Setup.exe`、`.venv-win`、`.venv-pdf`、`.ohos/` 签名证书等）均被 `.gitignore` 排除，**不入库**。exe 通过 GitHub Release 发布。

> ⚠️ **重要：HTML 唯一权威源**。三端（网页 / Windows / 鸿蒙）共用同一个 HTML，仓库内存在 `dist/index.html`、`windows/Time Recorder.html`、`harmony-app/.../rawfile/index.html` 三份副本，它们必须与 `Time Recorder.html` 保持一致。**修改请只在 `Time Recorder.html` 中进行，然后运行 `sync-html.bat`（Windows）或 `bash sync-html.sh` 同步到其余三处**，避免多端功能不一致。

## 🛠 开发构建

### Windows 免安装 exe

```bash
cd windows
python -m venv .venv-win                              # 首次：创建构建环境
.venv-win\Scripts\pip install pywebview pyinstaller   # 首次：安装依赖
.venv-win\Scripts\pyinstaller --noconfirm --onefile --windowed \
  --name "Time Recorder" --add-data "Time Recorder.html;." \
  --collect-all webview --hidden-import pythonnet --hidden-import clr \
  wrapper.py
# 产物：windows\dist\Time Recorder.exe（构建产物不入库，随 Release 发布）
```

### Windows 安装包（NSIS）

```bash
cd windows
makensis installer.nsi
```

### 鸿蒙 .hap

打开 `harmony-app/` 工程 → DevEco Studio 6.1 → 连真机 → Run。详见 `harmony-app/README.md`。

### 使用手册 PDF（`gen_manual_pdf.py`）

`Time Recorder 使用手册.pdf` 由 `gen_manual_pdf.py` 从应用内手册内容生成。修改手册内容后需重新生成：

```bash
python -m venv .venv-pdf        # 首次：创建本地虚拟环境
.venv-pdf\Scripts\pip install reportlab   # 首次：安装依赖（仅需一次）
.venv-pdf\Scripts\python gen_manual_pdf.py
```

> 说明：`reportlab` 为生成 PDF 的**开发期依赖**，仅生成时用，运行应用无需安装。本项目已准备 `.venv-pdf` 虚拟环境并加入 `.gitignore`。

### 推送到本仓库

```bash
bash git-push.sh "更新说明"       # 普通推送
bash git-push.sh -f "覆盖说明"    # 冲突时强制推送
```

## 📝 说明

- 云同步需自建 Supabase 项目并执行 `supabase-schema.sql`（表：`tasks` / `plans` / `records` / `countdown`）
- AI 助手需在应用设置中填入自有 DashScope API Key
- 桌面端系统通知与记住登录基于 Windows 系统能力（WebView2 / Credential Manager）
- Windows 免安装 exe 为构建产物（不入库），通过 GitHub Release 发布；如需发新版本：本地重新打包 → 在 Releases 页新建 Release 并上传 exe。

---
*个人自用项目，欢迎学习参考。*
