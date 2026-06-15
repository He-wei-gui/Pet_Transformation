/** 体重记录，weight 单位为克(g)。id/petId 为云端标识（字符串）。 */
export class WeightLog {
  id: string;
  petId: string;
  date: string;
  weight: number;
  createdAt: string;

  constructor(id: string, petId: string, date: string, weight: number, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.weight = weight;
    this.createdAt = createdAt;
  }
}
