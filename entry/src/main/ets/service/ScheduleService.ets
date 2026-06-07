import { DateUtil } from '../utils/DateUtil';

/**
 * 动态排程服务（复刻参考项目核心逻辑）：
 * 下一次计划日期 = 实际登记日期 + 间隔天数，
 * 据此自动纠偏漏打卡的天数，不堆积欠账。
 */
export class ScheduleService {
  /** 依据某次喂食的实际日期推算下一次喂食日。 */
  static nextFeedDate(checkinDate: string, feedInterval: number): string {
    return DateUtil.addDays(checkinDate, feedInterval);
  }

  /** 依据某次换料的实际日期推算下一次换料日。 */
  static nextSubstrateDate(checkinDate: string, subInterval: number): string {
    return DateUtil.addDays(checkinDate, subInterval);
  }
}
