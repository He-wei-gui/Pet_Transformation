/**
 * 单条校验结果。messageKey 为字符串资源名（如 'err_password_min'），
 * 由页面通过 resourceManager 解析为当前语言文案，从而支持中英文 i18n。
 * ArkTS 不支持 zod，故以显式校验函数替代（项目规则）。
 */
export class ValidationResult {
  readonly valid: boolean;
  readonly messageKey: string;

  constructor(valid: boolean, messageKey: string) {
    this.valid = valid;
    this.messageKey = messageKey;
  }

  static ok(): ValidationResult {
    return new ValidationResult(true, '');
  }

  static fail(messageKey: string): ValidationResult {
    return new ValidationResult(false, messageKey);
  }
}

const USERNAME_PATTERN: RegExp = new RegExp('^[A-Za-z0-9_]{3,20}$');

export class Validator {
  /** 用户名：3-20 位字母、数字或下划线。 */
  static username(value: string): ValidationResult {
    const v: string = value.trim();
    if (v.length === 0) {
      return ValidationResult.fail('err_username_required');
    }
    if (!USERNAME_PATTERN.test(v)) {
      return ValidationResult.fail('err_username_format');
    }
    return ValidationResult.ok();
  }

  /** 密码：6-32 位。 */
  static password(value: string): ValidationResult {
    if (value.length < 6) {
      return ValidationResult.fail('err_password_min');
    }
    if (value.length > 32) {
      return ValidationResult.fail('err_password_max');
    }
    return ValidationResult.ok();
  }

  /** 两次密码一致。 */
  static passwordMatch(password: string, confirm: string): ValidationResult {
    if (password !== confirm) {
      return ValidationResult.fail('err_password_mismatch');
    }
    return ValidationResult.ok();
  }

  /** 非空文本，limit 为最大长度。 */
  static requiredText(value: string, limit: number): ValidationResult {
    const v: string = value.trim();
    if (v.length === 0) {
      return ValidationResult.fail('err_required');
    }
    if (v.length > limit) {
      return ValidationResult.fail('err_too_long');
    }
    return ValidationResult.ok();
  }

  /** 正数（用于体重、温湿度等）。 */
  static positiveNumber(value: string): ValidationResult {
    const v: string = value.trim();
    const n: number = Number.parseFloat(v);
    if (v.length === 0 || Number.isNaN(n) || n <= 0) {
      return ValidationResult.fail('err_positive');
    }
    return ValidationResult.ok();
  }

  /** 间隔天数：1-365 的整数。 */
  static intervalDays(value: string): ValidationResult {
    const n: number = Number.parseInt(value.trim(), 10);
    if (Number.isNaN(n) || n < 1 || n > 365) {
      return ValidationResult.fail('err_interval');
    }
    return ValidationResult.ok();
  }
}
