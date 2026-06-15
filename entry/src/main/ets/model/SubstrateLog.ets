/** 换料/换垫材记录。id/petId 为云端标识（字符串）。 */
export class SubstrateLog {
  id: string;
  petId: string;
  date: string;
  substrateType: string;
  note: string;
  createdAt: string;

  constructor(id: string, petId: string, date: string, substrateType: string,
    note: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.substrateType = substrateType;
    this.note = note;
    this.createdAt = createdAt;
  }
}
