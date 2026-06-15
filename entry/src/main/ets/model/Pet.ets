/**
 * 宠物实体。id/userId 为云端标识（_id / openid 字符串）。
 * feedInterval/subInterval 为喂食/换料间隔天数，
 * nextFeedDate/nextSubDate 由 ScheduleService 依据“实际登记日 + 间隔”动态推算。
 */
export class Pet {
  id: string;
  userId: string;
  name: string;
  species: string;
  avatar: string;
  birthDate: string;
  feedInterval: number;
  subInterval: number;
  nextFeedDate: string;
  nextSubDate: string;
  note: string;

  constructor(id: string, userId: string, name: string, species: string, avatar: string,
    birthDate: string, feedInterval: number, subInterval: number,
    nextFeedDate: string, nextSubDate: string, note: string) {
    this.id = id;
    this.userId = userId;
    this.name = name;
    this.species = species;
    this.avatar = avatar;
    this.birthDate = birthDate;
    this.feedInterval = feedInterval;
    this.subInterval = subInterval;
    this.nextFeedDate = nextFeedDate;
    this.nextSubDate = nextSubDate;
    this.note = note;
  }
}
