/**
 * 单条校验结果。ArkTS 不支持 zod，故以显式校验函数替代（项目规则）。
 */
export class ValidationResult {
  readonly valid: boolean;
  readonly message: string;

  constructor(valid: boolean, message: string) {
    this.valid = valid;
    this.message = message;
  }

  static ok(): ValidationResult {
    return new ValidationResult(true, '');
  }

  static fail(message: string): ValidationResult {
    return new ValidationResult(false, message);
  }
}

const USERNAME_PATTERN: RegExp = new RegExp('^[A-Za-z0-9_]{3,20}$');

export class Validator {
  /** 用户名：3-20 位字母、数字或下划线。 */
  static username(value: string): ValidationResult {
    const v: string = value.trim();
    if (v.length === 0) {
      return ValidationResult.fail('请输入用户名');
    }
    if (!USERNAME_PATTERN.test(v)) {
      return ValidationResult.fail('用户名需为 3-20 位字母、数字或下划线');
    }
    return ValidationResult.ok();
  }

  /** 密码：6-32 位。 */
  static password(value: string): ValidationResult {
    if (value.length < 6) {
      return ValidationResult.fail('密码至少 6 位');
    }
    if (value.length > 32) {
      return ValidationResult.fail('密码不能超过 32 位');
    }
    return ValidationResult.ok();
  }

  /** 两次密码一致。 */
  static passwordMatch(password: string, confirm: string): ValidationResult {
    if (password !== confirm) {
      return ValidationResult.fail('两次输入的密码不一致');
    }
    return ValidationResult.ok();
  }

  /** 非空文本，limit 为最大长度。 */
  static requiredText(value: string, fieldName: string, limit: number): ValidationResult {
    const v: string = value.trim();
    if (v.length === 0) {
      return ValidationResult.fail(`请输入${fieldName}`);
    }
    if (v.length > limit) {
      return ValidationResult.fail(`${fieldName}不能超过 ${limit} 个字符`);
    }
    return ValidationResult.ok();
  }

  /** 正数（用于体重、天数、温湿度等）。 */
  static positiveNumber(value: string, fieldName: string): ValidationResult {
    const v: string = value.trim();
    if (v.length === 0) {
      return ValidationResult.fail(`请输入${fieldName}`);
    }
    const n: number = Number.parseFloat(v);
    if (Number.isNaN(n) || n <= 0) {
      return ValidationResult.fail(`${fieldName}需为正数`);
    }
    return ValidationResult.ok();
  }

  /** 间隔天数：1-365 的整数。 */
  static intervalDays(value: string): ValidationResult {
    const n: number = Number.parseInt(value.trim(), 10);
    if (Number.isNaN(n) || n < 1 || n > 365) {
      return ValidationResult.fail('间隔需为 1-365 天');
    }
    return ValidationResult.ok();
  }
}
