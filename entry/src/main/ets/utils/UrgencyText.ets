import { common } from '@kit.AbilityKit';
import { Urgency, UrgencyInfo } from '../model/Urgency';

/**
 * 将紧急度格式化为当前语言文案（带天数占位符 %d）。
 */
export class UrgencyText {
  static label(context: common.Context, info: UrgencyInfo): string {
    try {
      if (info.level === Urgency.TODAY) {
        return context.resourceManager.getStringByNameSync('urgency_today');
      }
      if (info.level === Urgency.OVERDUE) {
        return context.resourceManager.getStringByNameSync('urgency_overdue_fmt').replace('%d', `${info.days}`);
      }
      return context.resourceManager.getStringByNameSync('urgency_upcoming_fmt').replace('%d', `${info.days}`);
    } catch (err) {
      return '';
    }
  }
}
