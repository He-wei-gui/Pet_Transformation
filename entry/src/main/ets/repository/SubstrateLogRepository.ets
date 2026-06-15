import { SubstrateLog } from '../model/SubstrateLog';
import { ApiClient } from '../service/ApiClient';

/** 云端 substrate_logs 的 JSON 形状。 */
interface SubstrateDto {
  _id: string;
  pet_id: string;
  change_date?: string;
  sub_type?: string;
  created_at?: string;
}

/** 提交给后端的换料可写字段。 */
interface SubstrateReq {
  pet_id: string;
  change_date: string;
  sub_type: string;
}

/** 换料记录仓储（在线优先）。listByPet 按日期倒序（最新在前）。 */
export class SubstrateLogRepository {
  private static toLog(d: SubstrateDto): SubstrateLog {
    return new SubstrateLog(d._id, d.pet_id, d.change_date ?? '', d.sub_type ?? '', '', d.created_at ?? '');
  }

  static async listByPet(petId: string): Promise<SubstrateLog[]> {
    const dtos: SubstrateDto[] =
      ApiClient.unwrap(await ApiClient.get<SubstrateDto[]>(`/substrate-logs?pet_id=${petId}&order_by=change_date_desc`));
    return (dtos ?? []).map((d: SubstrateDto): SubstrateLog => SubstrateLogRepository.toLog(d));
  }

  static async create(log: SubstrateLog): Promise<string> {
    const req: SubstrateReq = { pet_id: log.petId, change_date: log.date, sub_type: log.substrateType };
    const dto: SubstrateDto = ApiClient.unwrap(await ApiClient.post<SubstrateDto>('/substrate-logs', req));
    return dto._id;
  }

  static async remove(id: string): Promise<void> {
    ApiClient.unwrap(await ApiClient.del<object>(`/substrate-logs/${id}`));
  }

  static async removeByPet(petId: string): Promise<void> {
    const list: SubstrateLog[] = await SubstrateLogRepository.listByPet(petId);
    for (const log of list) {
      await SubstrateLogRepository.remove(log.id);
    }
  }
}
