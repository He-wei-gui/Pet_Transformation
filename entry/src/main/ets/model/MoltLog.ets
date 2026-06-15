/** 蜕皮记录。status: 'start' 开始蜕皮 / 'done' 完成蜕皮。 */
export class MoltLog {
  id: number;
  petId: string;
  date: string;
  status: string;
  note: string;
  createdAt: string;

  constructor(id: number, petId: string, date: string, status: string,
    note: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.status = status;
    this.note = note;
    this.createdAt = createdAt;
  }
}
