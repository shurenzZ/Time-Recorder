# Time Recorder · Windows 桌面封装

本目录将单文件网页应用 `Time Recorder.html` 封装为 Windows 可运行的 **exe**（基于 pywebview + Edge WebView2）。

- 原 `Time Recorder.html` **未做任何修改**，功能/页面/交互 100% 保留。
- **应用内通知**：网页自带 `toast()` 照常显示。
- **Windows 系统级通知**（增强）：`toast()` 通过 `window.pywebview.api.notify` 桥接到 Windows Toast（PowerShell + `Windows.UI.Notifications`，**免第三方依赖**，兼容 Win10/11）。

## 运行依赖
- Windows 10 / 11，且已安装 **Microsoft Edge WebView2 运行时**（Win10/11 多数已自带；若缺失，启动时会提示，到微软官网下载安装即可）。
- 两种交付形态：
  - `dist/Time Recorder.exe`：**免安装单文件程序**，双击即运行，无需安装；
  - `Time Recorder Setup.exe`：**正式安装包**（NSIS 打包），带开始菜单/桌面快捷方式与卸载程序，已在本环境构建完成。

## 在本环境已完成的构建
构建命令（已用受管 venv 执行）：
```
pyinstaller --noconfirm --onefile --windowed ^
  --name "Time Recorder" ^
  --add-data "Time Recorder.html;." ^
  --collect-all webview --hidden-import pythonnet --hidden-import clr ^
  wrapper.py
```
产物：`windows/dist/Time Recorder.exe`。

安装包（NSIS）：
```
makensis installer.nsi
```
产物：`windows/Time Recorder Setup.exe`。本环境把免安装版 NSIS 3.10 保留在工作区 `_nsis/src/nsis-3.10/`（`Bin/makensis.exe`），网络不便时可直接用它重建。

## 如需在本机自行重建
1. 安装依赖（Python 3.13）：
   ```
   python -m venv venv
   venv\Scripts\pip install pywebview pyinstaller
   ```
2. 运行上面的 `pyinstaller` 命令（在 `windows/` 目录下）。
3. 安装 NSIS（https://nsis.sourceforge.io/）后运行 `makensis installer.nsi`。

> 注意：`installer.nsi` 必须保持 **纯 ASCII**（勿加中文注释），NSIS 按 ANSI 解析脚本，UTF-8 中文注释会报 `Bad text encoding`；界面中文由 `MUI_LANGUAGE "SimpChinese"` 自动提供。

## 功能验证清单
- [ ] 双击 `Time Recorder.exe` 能启动并显示与原 HTML 一致的界面。
- [ ] 运行 `Time Recorder Setup.exe` 可安装；安装后开始菜单/桌面出现「Time Recorder」快捷方式，且可在「设置-应用」中卸载。
- [ ] 计时、清单、历史、统计、倒数日、AI 助手功能与原版一致。
- [ ] 登录同一账号后，清单/历史/统计跨设备同步正常。
- [ ] 应用内 `toast()` 提示正常显示。
- [ ] （增强）计时结束等事件额外弹出 Windows 系统通知。
