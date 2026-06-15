/** 喂食记录。id/petId 为云端标识（字符串）。 */
export class FeedLog {
  id: string;
  petId: string;
  date: string;
  foodType: string;
  amount: string;
  note: string;
  createdAt: string;

  constructor(id: string, petId: string, date: string, foodType: string,
    amount: string, note: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.foodType = foodType;
    this.amount = amount;
    this.note = note;
    this.createdAt = createdAt;
  }
}
