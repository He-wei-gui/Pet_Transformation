/** 换料/换垫材记录。 */
export class SubstrateLog {
  id: number;
  petId: number;
  date: string;
  substrateType: string;
  note: string;
  createdAt: string;

  constructor(id: number, petId: number, date: string, substrateType: string,
    note: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.substrateType = substrateType;
    this.note = note;
    this.createdAt = createdAt;
  }
}
