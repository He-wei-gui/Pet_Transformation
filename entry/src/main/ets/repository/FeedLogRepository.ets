import { FeedLog } from '../model/FeedLog';
import { ApiClient } from '../service/ApiClient';

/** 云端 feed_logs 的 JSON 形状。 */
interface FeedDto {
  _id: string;
  pet_id: string;
  feed_date?: string;
  food_type?: string;
  amount?: string;
  created_at?: string;
}

/** 提交给后端的喂食可写字段。 */
interface FeedReq {
  pet_id: string;
  feed_date: string;
  food_type: string;
  amount: string;
}

/** 喂食记录仓储（在线优先）。listByPet 按日期倒序（最新在前）。 */
export class FeedLogRepository {
  private static toLog(d: FeedDto): FeedLog {
    return new FeedLog(d._id, d.pet_id, d.feed_date ?? '', d.food_type ?? '', d.amount ?? '', '', d.created_at ?? '');
  }

  static async listByPet(petId: string): Promise<FeedLog[]> {
    const dtos: FeedDto[] =
      ApiClient.unwrap(await ApiClient.get<FeedDto[]>(`/feed-logs?pet_id=${petId}&order_by=feed_date_desc`));
    return (dtos ?? []).map((d: FeedDto): FeedLog => FeedLogRepository.toLog(d));
  }

  static async create(log: FeedLog): Promise<string> {
    const req: FeedReq = { pet_id: log.petId, feed_date: log.date, food_type: log.foodType, amount: log.amount };
    const dto: FeedDto = ApiClient.unwrap(await ApiClient.post<FeedDto>('/feed-logs', req));
    return dto._id;
  }

  static async remove(id: string): Promise<void> {
    ApiClient.unwrap(await ApiClient.del<object>(`/feed-logs/${id}`));
  }

  /** 删除某宠物全部喂食记录（在线优先下宠物删除已由后端级联，此处先列后逐条删以兼容直接调用）。 */
  static async removeByPet(petId: string): Promise<void> {
    const list: FeedLog[] = await FeedLogRepository.listByPet(petId);
    for (const log of list) {
      await FeedLogRepository.remove(log.id);
    }
  }
}
