/**
 * 演示数据播种（已停用）。
 * 接入云端后，账户数据由云端管理，不再在本地播种演示宠物。
 * 保留空实现以兼容历史调用方。
 */
export class SeedService {
  static async seedIfEmpty(userId: string): Promise<void> {
    // no-op：在线优先架构下不本地播种
  }
}
