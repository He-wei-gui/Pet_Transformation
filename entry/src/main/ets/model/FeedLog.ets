/** 喂食记录。 */
export class FeedLog {
  id: number;
  petId: number;
  date: string;
  foodType: string;
  amount: string;
  note: string;
  createdAt: string;

  constructor(id: number, petId: number, date: string, foodType: string,
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
