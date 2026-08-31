import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { logInfo, logError } from '../common/Logger';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    logInfo('Ability onCreate');
  }

  onDestroy(): void {
    logInfo('Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 请求用户授权，使应用具备发送系统通知的能力（首次会弹窗，用户允许后生效）。
    try {
      notificationManager.requestEnableNotification(this.context)
        .then(() => logInfo('notification enabled'))
        .catch((err: BusinessError) => {
          logError('requestEnableNotification failed: ' + JSON.stringify(err));
        });
    } catch (e) {
      logError('requestEnableNotification exception: ' + JSON.stringify(e));
    }

    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        logError('Failed to load the content. Cause: ' + JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy(): void {
    // 主窗口销毁，释放 UI 相关资源。
  }

  onForeground(): void {
    // Ability 进入前台。
  }

  onBackground(): void {
    // Ability 进入后台。
  }
}
