/** 用户自定义待办（与宠物喂食/换料的自动任务并列显示在首页）。 */
export class Todo {
  id: number;
  userId: number;
  title: string;
  date: string;
  done: number;
  createdAt: string;

  constructor(id: number, userId: number, title: string, date: string, done: number, createdAt: string) {
    this.id = id;
    this.userId = userId;
    this.title = title;
    this.date = date;
    this.done = done;
    this.createdAt = createdAt;
  }
}
