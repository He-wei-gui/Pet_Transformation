import { WeightLog } from '../model/WeightLog';
import { ApiClient } from '../service/ApiClient';

/** 云端 weight_logs 的 JSON 形状。 */
interface WeightDto {
  _id: string;
  pet_id: string;
  weight?: number;
  record_date?: string;
  created_at?: string;
}

/** 提交给后端的体重可写字段。 */
interface WeightReq {
  pet_id: string;
  weight: number;
  record_date: string;
}

/** 体重记录仓储（在线优先）。listByPet 按日期升序（便于绘制趋势曲线）。 */
export class WeightLogRepository {
  private static toLog(d: WeightDto): WeightLog {
    return new WeightLog(d._id, d.pet_id, d.record_date ?? '', d.weight ?? 0, d.created_at ?? '');
  }

  static async listByPet(petId: string): Promise<WeightLog[]> {
    // 后端默认按 record_date ASC 返回，正好用于趋势曲线
    const dtos: WeightDto[] = ApiClient.unwrap(await ApiClient.get<WeightDto[]>(`/weight-logs?pet_id=${petId}`));
    return (dtos ?? []).map((d: WeightDto): WeightLog => WeightLogRepository.toLog(d));
  }

  static async create(log: WeightLog): Promise<string> {
    const req: WeightReq = { pet_id: log.petId, weight: log.weight, record_date: log.date };
    const dto: WeightDto = ApiClient.unwrap(await ApiClient.post<WeightDto>('/weight-logs', req));
    return dto._id;
  }

  static async remove(id: string): Promise<void> {
    ApiClient.unwrap(await ApiClient.del<object>(`/weight-logs/${id}`));
  }

  static async removeByPet(petId: string): Promise<void> {
    const list: WeightLog[] = await WeightLogRepository.listByPet(petId);
    for (const log of list) {
      await WeightLogRepository.remove(log.id);
    }
  }
}
