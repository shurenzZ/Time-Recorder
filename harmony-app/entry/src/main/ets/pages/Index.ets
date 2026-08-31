import { webview } from '@kit.ArkWeb';
import { HarmonyBridge } from '../bridge/HarmonyBridge';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: HarmonyBridge = new HarmonyBridge();

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
          methodList: ['showSystemNotification'],
          controller: this.controller
        })
    }
    .width('100%')
    .height('100%')
  }
}
