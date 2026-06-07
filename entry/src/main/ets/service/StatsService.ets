import { Pet } from '../model/Pet';
import { FeedLog } from '../model/FeedLog';
import { WeightLog } from '../model/WeightLog';
import { Urgency, UrgencyInfo } from '../model/Urgency';
import { PetRepository } from '../repository/PetRepository';
import { FeedLogRepository } from '../repository/FeedLogRepository';
import { WeightLogRepository } from '../repository/WeightLogRepository';
import { SessionStore } from './SessionStore';
import { DateUtil } from '../utils/DateUtil';

/** 统计概览数据。 */
export class StatsSummary {
  totalPets: number;
  totalFeed: number;
  totalWeight: number;
  overdue: number;
  feed7d: number[];

  constructor(totalPets: number, totalFeed: number, totalWeight: number,
    overdue: number, feed7d: number[]) {
    this.totalPets = totalPets;
    this.totalFeed = totalFeed;
    this.totalWeight = totalWeight;
    this.overdue = overdue;
    this.feed7d = feed7d;
  }
}

/**
 * 统计服务：聚合当前用户的多维度数据，供仪表盘展示。
 */
export class StatsService {
  static async build(): Promise<StatsSummary> {
    const pets: Pet[] = await PetRepository.findByUser(SessionStore.currentUserId());
    const today: string = DateUtil.today();
    const feed7d: number[] = [0, 0, 0, 0, 0, 0, 0];
    let totalFeed: number = 0;
    let totalWeight: number = 0;
    let overdue: number = 0;

    for (let i: number = 0; i < pets.length; i++) {
      const pet: Pet = pets[i];
      const feeds: FeedLog[] = await FeedLogRepository.listByPet(pet.id);
      totalFeed += feeds.length;
      for (let j: number = 0; j < feeds.length; j++) {
        const diff: number = DateUtil.diffDays(feeds[j].date, today);
        if (diff >= 0 && diff <= 6) {
          feed7d[6 - diff] += 1;
        }
      }
      const weights: WeightLog[] = await WeightLogRepository.listByPet(pet.id);
      totalWeight += weights.length;

      if (pet.nextFeedDate.length > 0 && UrgencyInfo.evaluate(pet.nextFeedDate).level === Urgency.OVERDUE) {
        overdue += 1;
      }
      if (pet.nextSubDate.length > 0 && UrgencyInfo.evaluate(pet.nextSubDate).level === Urgency.OVERDUE) {
        overdue += 1;
      }
    }

    return new StatsSummary(pets.length, totalFeed, totalWeight, overdue, feed7d);
  }
}
