# Time Recorder · 鸿蒙（HarmonyOS）封装工程

本工程将单文件网页应用 `Time Recorder.html` 完整封装为鸿蒙手机可安装的 **HAP** 应用，并额外实现：

- **应用内通知**：原 HTML 自带的 `toast()` 提示完整保留，照常显示。
- **鸿蒙系统级通知**：通过 `Web` 组件的 `javaScriptProxy` 把网页侧的 `toast()` 桥接到原生 `notificationManager.publishNotification`，在保留应用内提示的同时，自动弹出系统通知。

> 原 `Time Recorder.html` 文件**未做任何修改**，原样放在 `entry/src/main/resources/rawfile/index.html`，因此所有原有功能、页面内容与交互逻辑 100% 保留。运行时所需的 CDN 依赖（Supabase JS / Chart.js / PDF.js）联网加载，与浏览器中行为一致。

## 目录结构
```
harmony-app/
├─ AppScope/                      # 应用级配置与图标
├─ entry/                         # 入口模块
│  ├─ src/main/ets/
│  │  ├─ entryability/EntryAbility.ts   # 请求通知授权 + 加载页面
│  │  ├─ pages/Index.ets                # Web 组件加载 HTML + 注入通知桥
│  │  ├─ bridge/HarmonyBridge.ets       # 通知桥（发布系统级通知）
│  │  └─ common/Logger.ets              # 统一日志封装（DOMAIN/TAG/错误日志）
│  ├─ src/main/resources/
│  │  ├─ rawfile/index.html            # 原 HTML（未改动）
│  │  ├─ base/media/app_icon.png       # 图标（占位，建议替换为正式图标）
│  │  └─ base/{element,profile}/       # 字符串/颜色/页面声明
│  ├─ module.json5 / build-profile.json5 / hvigorfile.ts / oh-package.json5
├─ build-profile.json5 / hvigorfile.ts / package.json / oh-package.json5 / local.properties
```

## 在本环境无法生成 HAP 的说明
构建并签名 HAP 需要 **DevEco Studio + HarmonyOS SDK + 签名证书**，本机未安装该工具链，因此无法在此直接产出可安装的 `.hap` 二进制。本工程为**可直接在 DevEco Studio 中一键构建**的完整源码。请按以下步骤在你自己的电脑上完成构建与安装。

## 构建与签名步骤（DevEco Studio）
1. **安装 DevEco Studio**（6.1，合一打包版，**自带 HarmonyOS SDK（API 24 / HarmonyOS 6.1.1）**，开箱即用，无需手动下载 SDK）。内置 SDK 位于 `C:\Program Files\Huawei\DevEco Studio\sdk`。
2. 打开 DevEco Studio → `File → Open` → 选择本目录 `harmony-app`。
3. **SDK 路径无需手动配置**（合一打包版自动使用内置 SDK）；若提示找不到 SDK，检查 Settings → OpenHarmony SDK 的路径是否指向 `C:\Program Files\Huawei\DevEco Studio\sdk`。
4. **配置签名**（生成可安装 HAP 必需）：
   - `File → Project Structure → Signing Configs`；
   - 勾选 `Automatically generate signature`（使用华为账号的调试证书，需登录华为开发者账号）；
   - 或 `New` 手动导入你自己的 `.p12` / `.csr` / `.cer` / `.p7b`。
   - 保存后，`build-profile.json5` 的 `signingConfigs` 会被自动填充（名为 `default`）。

> ⚠️ **签名安全说明**：仓库内 `build-profile.json5` 的 `signingConfigs.material` 中 `certpath`/`keyPassword`/`storeFile`/`storePassword` 等字段已**清空为占位**，不包含任何真实签名密钥，避免密钥随仓库泄露。请在 DevEco 本地完成第 4 步签名配置后，由 DevEco 自动填充这些字段再构建。个人签名证书默认生成在本机 `~/.ohos/config/` 目录（已在根 `.gitignore` 排除），不要提交到仓库。
5. **构建 HAP**：菜单 `Build → Build HAP(s) / APP(s) → Build HAP(s)`。产物位于：
   `entry/build/default/outputs/default/entry-default-unsigned.hap`（未签名）或 `entry-default-signed.hap`（已签名）。
6. **安装到手机**：
   - 手机开启「开发者模式 → USB 调试 / 无线调试」；
   - DevEco 连接设备后 `Run 'entry'` 直接安装运行；或用 `hdc install entry-default-signed.hap` 安装。
7. **首次启动**：应用会弹窗请求「允许发送通知」，点击允许后，计时结束、同步异常等场景即会同时出现应用内提示与系统通知。

## 兼容性备注
- 本工程使用 **Stage 模型 + API 24（HarmonyOS 6.1.1）**，导入统一采用归一化 **`@kit.*` 写法**（NEXT 推荐写法）。
  - 已按 **DevEco Studio 6.1.1（合一打包版）** 对齐：`compileSdkVersion`/`compatibleSdkVersion` 均为 `24`，与内置 SDK（`sdk/default/sdk-pkg.json` 里 `apiVersion: 24`）一致，开箱即用、无需额外下载 SDK。
  - 若需兼容更老真机（HarmonyOS 5.1 / API 18），可把 `compatibleSdkVersion` 调低为 `18`（`compileSdkVersion` 保持 `24`），并确保已通过 SDK Manager 正确下载 API 18 SDK。
  - 若需兼容 **API 11（HarmonyOS 4.x）**：请把 `compileSdkVersion`/`compatibleSdkVersion` 改回 `11`，并把各 `.ets/.ts` 的 `@kit.*` 改为 `@ohos.*`（如 `@kit.NotificationKit` → `@ohos.notificationManager`、`@kit.ArkWeb` → `@ohos.web.webview`、`@kit.BasicServicesKit` → `@ohos.base`）。
- `module.json5` 仅声明 `ohos.permission.INTERNET`（网页加载云端脚本与跨设备同步所必需）；普通三方应用发送通知**无需**声明 `NOTIFICATION_CONTROLLER` 系统权限，走 `requestEnableNotification` 用户授权流程即可。
- 通知 id 固定为 `1001`：同类型提醒后发覆盖前一条，避免通知栏堆积。
- 图标 `app_icon.png` 为占位图，建议替换为正式 1024×1024 应用图标后再发布。

## 功能验证清单
- [ ] 应用正常安装、启动，显示与原 HTML 一致的界面。
- [ ] 计时、每日清单、历史、统计、倒数日、AI 助手功能与原版一致。
- [ ] 登录同一账号后，清单/历史/统计跨设备同步正常。
- [ ] 应用内 `toast()` 提示正常显示（应用内通知）。
- [ ] 允许通知授权后，计时结束等事件额外弹出**系统级通知**（鸿蒙通知栏可见）。
