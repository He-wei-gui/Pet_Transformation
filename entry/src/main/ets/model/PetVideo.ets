/**
 * 成长视频（本地）。视频文件不上云，由用户从图库选取后复制到应用沙箱，
 * uri 存沙箱内的本地文件路径。命名为 PetVideo 以避开 ArkUI 内置 Video 组件。
 */
export class PetVideo {
  id: number;
  userId: string;
  petId: string;
  uri: string;
  caption: string;
  createdAt: string;

  constructor(id: number, userId: string, petId: string, uri: string, caption: string, createdAt: string) {
    this.id = id;
    this.userId = userId;
    this.petId = petId;
    this.uri = uri;
    this.caption = caption;
    this.createdAt = createdAt;
  }
}
