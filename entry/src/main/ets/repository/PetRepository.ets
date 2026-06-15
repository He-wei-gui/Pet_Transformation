import { Pet } from '../model/Pet';
import { ApiClient } from '../service/ApiClient';
import { Result } from '../utils/Result';

/** 云端 pet_info 的 JSON 形状（字段名为后端约定，与模型不同）。 */
interface PetDto {
  _id: string;
  user_openid: string;
  name?: string;
  species?: string;
  avatar?: string;
  arrivalDate?: string;
  initialWeight?: number;
  feed_interval?: number;
  sub_interval?: number;
  next_feed_date?: string;
  next_sub_date?: string;
  note?: string;
  created_at?: string;
}

/** 提交给后端的宠物可写字段。 */
interface PetReq {
  name: string;
  species: string;
  avatar: string;
  arrivalDate: string;
  feed_interval: number;
  sub_interval: number;
  next_feed_date: string;
  next_sub_date: string;
  note: string;
}

/**
 * 宠物仓储（在线优先）：所有读写直达云端 /pets，按 token 的 openid 隔离用户。
 * 字段映射：birthDate↔arrivalDate、feedInterval↔feed_interval、subInterval↔sub_interval、
 * nextFeedDate↔next_feed_date、nextSubDate↔next_sub_date；云端 initialWeight 暂忽略。
 */
export class PetRepository {
  private static toPet(d: PetDto): Pet {
    return new Pet(
      d._id,
      d.user_openid ?? '',
      d.name ?? '',
      d.species ?? '',
      d.avatar ?? '',
      d.arrivalDate ?? '',
      d.feed_interval ?? 0,
      d.sub_interval ?? 0,
      d.next_feed_date ?? '',
      d.next_sub_date ?? '',
      d.note ?? ''
    );
  }

  private static toReq(pet: Pet): PetReq {
    return {
      name: pet.name,
      species: pet.species,
      avatar: pet.avatar,
      arrivalDate: pet.birthDate,
      feed_interval: pet.feedInterval,
      sub_interval: pet.subInterval,
      next_feed_date: pet.nextFeedDate,
      next_sub_date: pet.nextSubDate,
      note: pet.note
    };
  }

  /** userId 参数保留以兼容调用方，实际用户由 token 决定。 */
  static async findByUser(userId: string): Promise<Pet[]> {
    const dtos: PetDto[] = ApiClient.unwrap(await ApiClient.get<PetDto[]>('/pets'));
    return (dtos ?? []).map((d: PetDto): Pet => PetRepository.toPet(d));
  }

  static async findById(id: string): Promise<Pet | null> {
    const r: Result<PetDto> = await ApiClient.get<PetDto>(`/pets/${id}`);
    if (!r.success || r.data === null) {
      return null;
    }
    return PetRepository.toPet(r.data);
  }

  /** 新建宠物，返回云端生成的 _id。 */
  static async create(pet: Pet): Promise<string> {
    const dto: PetDto = ApiClient.unwrap(await ApiClient.post<PetDto>('/pets', PetRepository.toReq(pet)));
    return dto._id;
  }

  static async update(pet: Pet): Promise<void> {
    ApiClient.unwrap(await ApiClient.put<PetDto>(`/pets/${pet.id}`, PetRepository.toReq(pet)));
  }

  static async updateNextDates(id: string, nextFeedDate: string, nextSubDate: string): Promise<void> {
    const body: Record<string, string> = {
      'next_feed_date': nextFeedDate,
      'next_sub_date': nextSubDate
    };
    ApiClient.unwrap(await ApiClient.put<PetDto>(`/pets/${id}`, body));
  }

  static async remove(id: string): Promise<void> {
    ApiClient.unwrap(await ApiClient.del<object>(`/pets/${id}`));
  }
}
