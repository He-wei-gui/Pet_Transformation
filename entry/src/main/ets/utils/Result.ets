/**
 * 统一的操作结果包装，参考 patterns.md 中的 ApiResponse<T>。
 * 业务层（Service/Repository）返回 Result 以便 UI 统一处理成功/失败，
 * 不向 UI 抛出原始异常。
 */
export class Result<T> {
  readonly success: boolean;
  readonly data: T | null;
  readonly error: string;

  private constructor(success: boolean, data: T | null, error: string) {
    this.success = success;
    this.data = data;
    this.error = error;
  }

  static ok<T>(data: T): Result<T> {
    return new Result<T>(true, data, '');
  }

  static fail<T>(error: string): Result<T> {
    return new Result<T>(false, null, error);
  }
}
