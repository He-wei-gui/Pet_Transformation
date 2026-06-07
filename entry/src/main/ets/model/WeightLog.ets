/** 体重记录，weight 单位为克(g)。 */
export class WeightLog {
  id: number;
  petId: number;
  date: string;
  weight: number;
  createdAt: string;

  constructor(id: number, petId: number, date: string, weight: number, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.weight = weight;
    this.createdAt = createdAt;
  }
}
