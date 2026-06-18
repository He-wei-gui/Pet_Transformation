/**
 * 成长相册照片（在线优先，存于云端 pet_photos）。
 * - id 为云端 32-hex 主键（空串表示尚未落库）。
 * - uri 为云端可访问的图片 URL（原图）；thumbUri 为缩略图 URL（网格秒开，缺省回退原图）。
 * - lengthCm 为可选体长(cm，0 表示未记录)，喂给详情页体长曲线。
 */
export class Photo {
  id: string;
  petId: string;
  date: string;
  uri: string;
  thumbUri: string;
  lengthCm: number;
  caption: string;
  createdAt: string;

  constructor(id: string, petId: string, date: string, uri: string, thumbUri: string,
    lengthCm: number, caption: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.uri = uri;
    this.thumbUri = thumbUri;
    this.lengthCm = lengthCm;
    this.caption = caption;
    this.createdAt = createdAt;
  }
}
