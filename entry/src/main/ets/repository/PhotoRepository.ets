import { Photo } from '../model/Photo';
import { ApiClient } from '../service/ApiClient';

/** 云端 pet_photos 的 JSON 形状。length_cm 为本应用新增的可空列（小程序不写）。 */
interface PhotoDto {
  _id: string;
  pet_id: string;
  url?: string;
  thumb_url?: string;
  caption?: string;
  taken_at?: string;
  length_cm?: string | number;
  created_at?: string;
}

/** 提交给后端的相册可写字段。 */
interface PhotoReq {
  pet_id: string;
  url: string;
  thumb_url: string;
  caption: string;
  taken_at: string;
  length_cm: number;
}

/** 成长相册仓储（在线优先）。listByPet 按拍摄时间倒序（最新在前，由后端排序）。 */
export class PhotoRepository {
  private static toPhoto(d: PhotoDto): Photo {
    const url: string = d.url ?? '';
    const thumb: string = d.thumb_url !== undefined && d.thumb_url.length > 0 ? d.thumb_url : url;
    // taken_at 形如 "YYYY-MM-DD HH:MM:SS"，相册只展示日期部分
    const taken: string = d.taken_at ?? '';
    const date: string = taken.length >= 10 ? taken.substring(0, 10) : taken;
    const len: number = d.length_cm === undefined || d.length_cm === null ? 0 : Number.parseFloat(`${d.length_cm}`);
    return new Photo(d._id, d.pet_id, date, url, thumb,
      Number.isNaN(len) ? 0 : len, d.caption ?? '', d.created_at ?? '');
  }

  static async listByPet(petId: string): Promise<Photo[]> {
    const dtos: PhotoDto[] = ApiClient.unwrap(await ApiClient.get<PhotoDto[]>(`/pet-photos?pet_id=${petId}`));
    const photos: Photo[] = (dtos ?? []).map((d: PhotoDto): Photo => PhotoRepository.toPhoto(d));
    // 最新日期在前、越往下越旧；同日按创建时间倒序。不依赖后端排序，前端兜底保证顺序。
    photos.sort((a: Photo, b: Photo): number => {
      if (a.date !== b.date) {
        return a.date < b.date ? 1 : -1;
      }
      if (a.createdAt !== b.createdAt) {
        return a.createdAt < b.createdAt ? 1 : -1;
      }
      return 0;
    });
    return photos;
  }

  static async create(photo: Photo): Promise<string> {
    const req: PhotoReq = {
      pet_id: photo.petId,
      url: photo.uri,
      thumb_url: photo.thumbUri,
      caption: photo.caption,
      taken_at: photo.date,
      length_cm: photo.lengthCm
    };
    const dto: PhotoDto = ApiClient.unwrap(await ApiClient.post<PhotoDto>('/pet-photos', req));
    return dto._id;
  }

  static async remove(id: string): Promise<void> {
    ApiClient.unwrap(await ApiClient.del<object>(`/pet-photos/${id}`));
  }

  /** 删除某宠物全部照片（后端 pets_delete 不级联相册，删宠物前先在此清理）。 */
  static async removeByPet(petId: string): Promise<void> {
    const list: Photo[] = await PhotoRepository.listByPet(petId);
    for (const photo of list) {
      await PhotoRepository.remove(photo.id);
    }
  }
}
