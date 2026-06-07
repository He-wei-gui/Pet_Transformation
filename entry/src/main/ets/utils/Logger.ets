import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0001;
const TAG: string = 'PetUI';

/**
 * 统一日志封装，避免在业务代码中直接使用 console.log（项目规则）。
 */
export class Logger {
  static info(message: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', message);
  }

  static warn(message: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', message);
  }

  static error(message: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', message);
  }

  static debug(message: string): void {
    hilog.debug(DOMAIN, TAG, '%{public}s', message);
  }
}
