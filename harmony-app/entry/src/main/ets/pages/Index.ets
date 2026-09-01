import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { HarmonyBridge } from '../bridge/HarmonyBridge';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: HarmonyBridge = new HarmonyBridge();

  aboutToAppear(): void {
    // 注入 UIAbilityContext，供 bridge 使用系统偏好存储持久化登录态
    const ctx = getContext(this) as common.UIAbilityContext;
    (this.bridge as unknown as { ctx: common.UIAbilityContext }).ctx = ctx;
  }

  build() {
    Column() {
      Web({ src: $rawfile('index.html'), controller: this.controller })
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .databaseAccess(true)
        .imageAccess(true)
        .javaScriptProxy({
          object: this.bridge,
          name: 'harmonyBridge',
          methodList: ['showSystemNotification', 'getStoredSession', 'saveSession', 'clearSession'],
          controller: this.controller
        })
    }
    .width('100%')
    .height('100%')
  }
}
