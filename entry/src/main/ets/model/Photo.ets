/** 成长相册照片。uri 指向应用沙箱内复制后的图片，lengthCm 为可选体长(cm，0 表示未记录)。 */
export class Photo {
  id: number;
  petId: number;
  date: string;
  uri: string;
  lengthCm: number;
  caption: string;
  createdAt: string;

  constructor(id: number, petId: number, date: string, uri: string,
    lengthCm: number, caption: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.uri = uri;
    this.lengthCm = lengthCm;
    this.caption = caption;
    this.createdAt = createdAt;
  }
}
