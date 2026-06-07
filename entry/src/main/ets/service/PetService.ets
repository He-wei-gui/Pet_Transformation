import { Pet } from '../model/Pet';
import { FeedLog } from '../model/FeedLog';
import { SubstrateLog } from '../model/SubstrateLog';
import { WeightLog } from '../model/WeightLog';
import { ChecklistEntry } from '../model/ChecklistEntry';
import { Urgency, UrgencyInfo } from '../model/Urgency';
import { PetRepository } from '../repository/PetRepository';
import { FeedLogRepository } from '../repository/FeedLogRepository';
import { SubstrateLogRepository } from '../repository/SubstrateLogRepository';
import { WeightLogRepository } from '../repository/WeightLogRepository';
import { MoltLogRepository } from '../repository/MoltLogRepository';
import { EnvLogRepository } from '../repository/EnvLogRepository';
import { PhotoRepository } from '../repository/PhotoRepository';
import { ScheduleService } from './ScheduleService';
import { SessionStore } from './SessionStore';
import { DateUtil } from '../utils/DateUtil';

const FEED: string = 'feed';
const SUBSTRATE: string = 'substrate';

/**
 * 宠物业务服务：聚合仓储与动态排程，向 UI 暴露稳定的用例方法。
 */
export class PetService {
  static async listPets(): Promise<Pet[]> {
    return PetRepository.findByUser(SessionStore.currentUserId());
  }

  static async getPet(id: number): Promise<Pet | null> {
    return PetRepository.findById(id);
  }

  /** 新建（id<=0）或更新宠物，返回宠物 id。 */
  static async savePet(pet: Pet): Promise<number> {
    if (pet.id > 0) {
      await PetRepository.update(pet);
      return pet.id;
    }
    return PetRepository.create(pet);
  }

  /** 删除宠物并级联删除其所有记录。 */
  static async deletePet(id: number): Promise<void> {
    await FeedLogRepository.removeByPet(id);
    await SubstrateLogRepository.removeByPet(id);
    await WeightLogRepository.removeByPet(id);
    await MoltLogRepository.removeByPet(id);
    await EnvLogRepository.removeByPet(id);
    await PhotoRepository.removeByPet(id);
    await PetRepository.remove(id);
  }

  /** 记录喂食并按动态排程重算下一次喂食日。 */
  static async logFeed(petId: number, date: string, foodType: string, amount: string, note: string): Promise<void> {
    await FeedLogRepository.create(new FeedLog(0, petId, date, foodType, amount, note, DateUtil.today()));
    const pet: Pet | null = await PetRepository.findById(petId);
    if (pet !== null) {
      const next: string = ScheduleService.nextFeedDate(date, pet.feedInterval);
      await PetRepository.updateNextDates(petId, next, pet.nextSubDate);
    }
  }

  /** 记录换料并按动态排程重算下一次换料日。 */
  static async logSubstrate(petId: number, date: string, type: string, note: string): Promise<void> {
    await SubstrateLogRepository.create(new SubstrateLog(0, petId, date, type, note, DateUtil.today()));
    const pet: Pet | null = await PetRepository.findById(petId);
    if (pet !== null) {
      const next: string = ScheduleService.nextSubstrateDate(date, pet.subInterval);
      await PetRepository.updateNextDates(petId, pet.nextFeedDate, next);
    }
  }

  static async logWeight(petId: number, date: string, weight: number): Promise<void> {
    await WeightLogRepository.create(new WeightLog(0, petId, date, weight, DateUtil.today()));
  }

  /** 汇总当前用户所有宠物的待办，按“逾期→今日→未来”排序。 */
  static async buildChecklist(): Promise<ChecklistEntry[]> {
    const pets: Pet[] = await PetRepository.findByUser(SessionStore.currentUserId());
    const entries: ChecklistEntry[] = [];
    for (let i: number = 0; i < pets.length; i++) {
      const pet: Pet = pets[i];
      if (pet.nextFeedDate.length > 0) {
        const info: UrgencyInfo = UrgencyInfo.evaluate(pet.nextFeedDate);
        entries.push(new ChecklistEntry(pet.id, pet.name, pet.avatar, FEED, pet.nextFeedDate, info.level, info.days));
      }
      if (pet.nextSubDate.length > 0) {
        const info: UrgencyInfo = UrgencyInfo.evaluate(pet.nextSubDate);
        entries.push(new ChecklistEntry(pet.id, pet.name, pet.avatar, SUBSTRATE, pet.nextSubDate, info.level, info.days));
      }
    }
    entries.sort((a: ChecklistEntry, b: ChecklistEntry): number => PetService.rank(a) - PetService.rank(b));
    return entries;
  }

  private static rank(entry: ChecklistEntry): number {
    if (entry.level === Urgency.OVERDUE) {
      return -1000 - entry.days;
    }
    if (entry.level === Urgency.TODAY) {
      return 0;
    }
    return entry.days;
  }
}
