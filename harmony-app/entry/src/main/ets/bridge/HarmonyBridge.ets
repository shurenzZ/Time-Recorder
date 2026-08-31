import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { logInfo, logError } from '../common/Logger';

// 固定通知 id：后续通知覆盖前一条，避免通知栏堆积多条同类提醒。
const NOTIFICATION_ID: number = 1001;

// 暴露给网页侧的对象，网页 JS 通过 window.harmonyBridge.showSystemNotification 调用。
export class HarmonyBridge {
  showSystemNotification(title: string, content: string): void {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title || 'Time Recorder',
            text: content || '',
            additionalText: ''
          }
        }
      };
      notificationManager.publish(notificationRequest)
        .then(() => logInfo('notification published'))
        .catch((err: BusinessError) => {
          logError('publish failed: ' + JSON.stringify(err));
        });
    } catch (e) {
      logError('showSystemNotification exception: ' + JSON.stringify(e));
    }
  }
}
