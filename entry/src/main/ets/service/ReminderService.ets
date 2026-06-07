import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

/**
 * 本地提醒：把今日待办以系统通知形式推送给用户。
 * 首次会申请通知授权；若用户未开启通知，publish 失败并返回 false 由 UI 提示。
 */
export class ReminderService {
  static async remind(context: common.UIAbilityContext, title: string, body: string): Promise<boolean> {
    try {
      try {
        await notificationManager.requestEnableNotification(context);
      } catch (authErr) {
        Logger.warn(`requestEnableNotification: ${JSON.stringify(authErr)}`);
      }
      const request: notificationManager.NotificationRequest = {
        id: 1,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: body
          }
        }
      };
      await notificationManager.publish(request);
      return true;
    } catch (err) {
      Logger.error(`publish notification failed: ${JSON.stringify(err)}`);
      return false;
    }
  }
}
