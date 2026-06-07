/**
 * 宠物实体。feedInterval/subInterval 为喂食/换料间隔天数，
 * nextFeedDate/nextSubDate 由 ScheduleService 依据“实际登记日 + 间隔”动态推算。
 */
export class Pet {
  id: number;
  userId: number;
  name: string;
  species: string;
  avatar: string;
  birthDate: string;
  feedInterval: number;
  subInterval: number;
  nextFeedDate: string;
  nextSubDate: string;
  note: string;

  constructor(id: number, userId: number, name: string, species: string, avatar: string,
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
