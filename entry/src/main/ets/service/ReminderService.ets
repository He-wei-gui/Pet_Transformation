import { notificationManager } from '@kit.NotificationKit';
import { Logger } from '../utils/Logger';

/**
 * 本地提醒：把今日待办以系统通知形式推送给用户。
 * 若系统未授予通知权限，publish 会失败，此处返回 false 由 UI 提示。
 */
export class ReminderService {
  static async remind(title: string, body: string): Promise<boolean> {
    try {
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
