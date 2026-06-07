/**
 * 日期工具。全应用统一使用 'YYYY-MM-DD' 字符串表示日期（与参考项目一致），
 * 所有日期运算均落在本地时区零点，避免时区/时分秒带来的偏差。
 */
export class DateUtil {
  private static pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  /** 将 Date 格式化为 'YYYY-MM-DD'。 */
  static format(date: Date): string {
    const y: number = date.getFullYear();
    const m: string = DateUtil.pad(date.getMonth() + 1);
    const d: string = DateUtil.pad(date.getDate());
    return `${y}-${m}-${d}`;
  }

  /** 今天的 'YYYY-MM-DD'。 */
  static today(): string {
    return DateUtil.format(new Date());
  }

  /** 将 'YYYY-MM-DD' 解析为本地零点 Date；非法输入回退到今天。 */
  static parse(dateStr: string): Date {
    const parts: string[] = dateStr.split('-');
    if (parts.length !== 3) {
      return new Date();
    }
    const y: number = Number.parseInt(parts[0], 10);
    const m: number = Number.parseInt(parts[1], 10);
    const d: number = Number.parseInt(parts[2], 10);
    if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d)) {
      return new Date();
    }
    return new Date(y, m - 1, d);
  }

  /** 在 'YYYY-MM-DD' 上增减天数，返回新的 'YYYY-MM-DD'。 */
  static addDays(dateStr: string, days: number): string {
    const base: Date = DateUtil.parse(dateStr);
    const next: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() + days);
    return DateUtil.format(next);
  }

  /** 计算 target - base 的天数（target 晚于 base 为正）。 */
  static diffDays(base: string, target: string): number {
    const oneDay: number = 24 * 60 * 60 * 1000;
    const baseTime: number = DateUtil.parse(base).getTime();
    const targetTime: number = DateUtil.parse(target).getTime();
    return Math.round((targetTime - baseTime) / oneDay);
  }

  /** 校验是否为合法的 'YYYY-MM-DD'。 */
  static isValid(dateStr: string): boolean {
    const parts: string[] = dateStr.split('-');
    if (parts.length !== 3) {
      return false;
    }
    const y: number = Number.parseInt(parts[0], 10);
    const m: number = Number.parseInt(parts[1], 10);
    const d: number = Number.parseInt(parts[2], 10);
    if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d)) {
      return false;
    }
    if (m < 1 || m > 12 || d < 1 || d > 31) {
      return false;
    }
    const probe: Date = new Date(y, m - 1, d);
    return probe.getFullYear() === y && probe.getMonth() === m - 1 && probe.getDate() === d;
  }

  /** 取 'YYYY-MM' 月份前缀。 */
  static monthKey(dateStr: string): string {
    const parts: string[] = dateStr.split('-');
    return parts.length >= 2 ? `${parts[0]}-${parts[1]}` : dateStr;
  }

  /** 友好显示：今天 / 昨天 / 'M月D日'。 */
  static friendly(dateStr: string): string {
    const delta: number = DateUtil.diffDays(dateStr, DateUtil.today());
    if (delta === 0) {
      return '今天';
    }
    if (delta === 1) {
      return '昨天';
    }
    const parts: string[] = dateStr.split('-');
    if (parts.length === 3) {
      return `${Number.parseInt(parts[1], 10)}月${Number.parseInt(parts[2], 10)}日`;
    }
    return dateStr;
  }
}
