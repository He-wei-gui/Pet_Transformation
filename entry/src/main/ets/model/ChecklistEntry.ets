import { Urgency } from './Urgency';

/** 今日待办条目：某只宠物的一项喂食/换料任务及其紧急度。 */
export class ChecklistEntry {
  petId: string;
  petName: string;
  petAvatar: string;
  kind: string;
  date: string;
  level: Urgency;
  days: number;

  constructor(petId: string, petName: string, petAvatar: string, kind: string,
    date: string, level: Urgency, days: number) {
    this.petId = petId;
    this.petName = petName;
    this.petAvatar = petAvatar;
    this.kind = kind;
    this.date = date;
    this.level = level;
    this.days = days;
  }
}
