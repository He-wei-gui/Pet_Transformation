/** 环境记录：温度(℃)、湿度(%)、UVB 指数。 */
export class EnvLog {
  id: number;
  petId: string;
  date: string;
  temperature: number;
  humidity: number;
  uvb: number;
  note: string;
  createdAt: string;

  constructor(id: number, petId: string, date: string, temperature: number,
    humidity: number, uvb: number, note: string, createdAt: string) {
    this.id = id;
    this.petId = petId;
    this.date = date;
    this.temperature = temperature;
    this.humidity = humidity;
    this.uvb = uvb;
    this.note = note;
    this.createdAt = createdAt;
  }
}
