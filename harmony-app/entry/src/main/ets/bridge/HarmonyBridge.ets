import { notificationManager } from '@kit.NotificationKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { logInfo, logError } from '../common/Logger';

// 固定通知 id：后续通知覆盖前一条，避免通知栏堆积多条同类提醒。
const NOTIFICATION_ID: number = 1001;
// Session 持久化键（登录态：一次登录后不退出则一直保持）
const SESSION_KEY: string = 'tr_auth_session';
const PREFS_NAME: string = 'tr_prefs';

// 暴露给网页侧的对象，网页 JS 通过 window.harmonyBridge.* 调用。
export class HarmonyBridge {
  // 由页面在 aboutToAppear 中注入 UIAbilityContext，用于系统偏好存储
  public ctx: common.UIAbilityContext | null = null;
  private pref: preferences.Preferences | null = null;

  // 获取（延迟初始化）系统偏好存储
  private getPref(): preferences.Preferences | null {
    if (this.pref) return this.pref;
    try {
      const context = this.ctx;
      if (!context) return null;
      this.pref = preferences.getPreferencesSync(context, { name: PREFS_NAME });
      return this.pref;
    } catch (e) {
      logError('getPreferencesSync exception: ' + JSON.stringify(e));
      return null;
    }
  }

  // ---- 登录态持久化（网页侧 initAuth / persistSessionToOS 调用）----
  getStoredSession(): string {
    try {
      const p = this.getPref();
      if (!p) return '';
      const v = p.getSync(SESSION_KEY, '') as string;
      return v || '';
    } catch (e) {
      logError('getStoredSession exception: ' + JSON.stringify(e));
      return '';
    }
  }

  saveSession(sessionJson: string): void {
    try {
      const p = this.getPref();
      if (!p || !sessionJson) return;
      p.putSync(SESSION_KEY, sessionJson);
      p.flush().catch((err: BusinessError) => logError('prefs flush failed: ' + JSON.stringify(err)));
    } catch (e) {
      logError('saveSession exception: ' + JSON.stringify(e));
    }
  }

  clearSession(): void {
    try {
      const p = this.getPref();
      if (!p) return;
      p.deleteSync(SESSION_KEY);
      p.flush().catch((err: BusinessError) => logError('prefs flush failed: ' + JSON.stringify(err)));
    } catch (e) {
      logError('clearSession exception: ' + JSON.stringify(e));
    }
  }

  // ---- 系统级通知 ----
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
