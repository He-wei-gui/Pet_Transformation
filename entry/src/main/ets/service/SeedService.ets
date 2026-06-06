import { Pet } from '../model/Pet';
import { WeightLog } from '../model/WeightLog';
import { FeedLog } from '../model/FeedLog';
import { EnvLog } from '../model/EnvLog';
import { MoltLog } from '../model/MoltLog';
import { PetRepository } from '../repository/PetRepository';
import { WeightLogRepository } from '../repository/WeightLogRepository';
import { FeedLogRepository } from '../repository/FeedLogRepository';
import { EnvLogRepository } from '../repository/EnvLogRepository';
import { MoltLogRepository } from '../repository/MoltLogRepository';
import { DateUtil } from '../utils/DateUtil';
import { Logger } from '../utils/Logger';

/**
 * 演示数据播种：为新注册用户写入 2 只示例爬宠与历史记录，
 * 便于打开即可看到今日清单、体重曲线、统计等效果。
 */
export class SeedService {
  /** 若该用户尚无宠物，则写入演示数据。 */
  static async seedIfEmpty(userId: number): Promise<void> {
    try {
      const existing: Pet[] = await PetRepository.findByUser(userId);
      if (existing.length > 0) {
        return;
      }
      await SeedService.seedGecko(userId);
      await SeedService.seedDragon(userId);
      Logger.info('Seed demo data done');
    } catch (err) {
      Logger.error(`seed failed: ${JSON.stringify(err)}`);
    }
  }

  private static day(offset: number): string {
    return DateUtil.addDays(DateUtil.today(), offset);
  }

  private static async seedGecko(userId: number): Promise<void> {
    const today: string = DateUtil.today();
    const pet: Pet = new Pet(0, userId, '斑斑', '豹纹守宫', '🦎',
      SeedService.day(-180), 3, 30, today, SeedService.day(12), '性格温顺，偏爱蟋蟀');
    const petId: number = await PetRepository.create(pet);

    await SeedService.addWeights(petId, [42, 45, 47, 50, 52]);
    await FeedLogRepository.create(new FeedLog(0, petId, SeedService.day(-3), '蟋蟀', '5 只', '', today));
    await FeedLogRepository.create(new FeedLog(0, petId, SeedService.day(-6), '蟋蟀', '4 只', '', today));
    await EnvLogRepository.create(new EnvLog(0, petId, SeedService.day(-7), 28, 50, 5, '', today));
    await EnvLogRepository.create(new EnvLog(0, petId, SeedService.day(-3), 30, 55, 5, '', today));
    await EnvLogRepository.create(new EnvLog(0, petId, today, 29, 52, 6, '', today));
    await MoltLogRepository.create(new MoltLog(0, petId, SeedService.day(-10), 'done', '完整蜕皮一次', today));
  }

  private static async seedDragon(userId: number): Promise<void> {
    const today: string = DateUtil.today();
    const pet: Pet = new Pet(0, userId, '小绿', '鬃狮蜥', '🐉',
      SeedService.day(-300), 1, 21, SeedService.day(-1), SeedService.day(6), '活泼好动，喜欢晒灯');
    const petId: number = await PetRepository.create(pet);

    await SeedService.addWeights(petId, [80, 90, 98, 110, 120]);
    await FeedLogRepository.create(new FeedLog(0, petId, SeedService.day(-2), '杜比亚', '3 只', '', today));
    await FeedLogRepository.create(new FeedLog(0, petId, SeedService.day(-3), '蔬菜', '适量', '补钙', today));
    await EnvLogRepository.create(new EnvLog(0, petId, SeedService.day(-5), 35, 40, 10, '', today));
    await EnvLogRepository.create(new EnvLog(0, petId, today, 34, 38, 11, '', today));
  }

  private static async addWeights(petId: number, weights: number[]): Promise<void> {
    const today: string = DateUtil.today();
    const offsets: number[] = [-28, -21, -14, -7, 0];
    for (let i: number = 0; i < weights.length && i < offsets.length; i++) {
      await WeightLogRepository.create(
        new WeightLog(0, petId, SeedService.day(offsets[i]), weights[i], today));
    }
  }
}
