import { DateUtil } from '../utils/DateUtil';

/**
 * 任务紧急度。复刻参考项目的“今日/逾期/未来”三态色彩逻辑。
 */
export enum Urgency {
  TODAY = 'today',
  OVERDUE = 'overdue',
  UPCOMING = 'upcoming'
}

/**
 * 紧急度计算结果，封装等级、展示文案与剩余/逾期天数。
 */
export class UrgencyInfo {
  readonly level: Urgency;
  readonly label: string;
  readonly days: number;

  constructor(level: Urgency, label: string, days: number) {
    this.level = level;
    this.label = label;
    this.days = days;
  }

  /** 根据下一次计划日期（'YYYY-MM-DD'）相对今天计算紧急度。 */
  static evaluate(nextDate: string): UrgencyInfo {
    const delta: number = DateUtil.diffDays(DateUtil.today(), nextDate);
    if (delta === 0) {
      return new UrgencyInfo(Urgency.TODAY, '今日待办', 0);
    }
    if (delta < 0) {
      return new UrgencyInfo(Urgency.OVERDUE, `已逾期 ${-delta} 天`, -delta);
    }
    return new UrgencyInfo(Urgency.UPCOMING, `还有 ${delta} 天`, delta);
  }
}
