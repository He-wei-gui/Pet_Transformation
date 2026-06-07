import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { Todo } from '../model/Todo';

const TABLE: string = 'todo';

/** 自定义待办仓储。listActiveByUser 仅返回未完成项，按日期升序。 */
export class TodoRepository {
  private static map(rs: relationalStore.ResultSet): Todo {
    return new Todo(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('user_id')),
      rs.getString(rs.getColumnIndex('title')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getLong(rs.getColumnIndex('done')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  /** 返回该用户全部待办：未完成(done=0)在前，再按日期升序。 */
  static async listByUser(userId: number): Promise<Todo[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('user_id', userId);
    predicates.orderByAsc('done');
    predicates.orderByAsc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: Todo[] = [];
    while (rs.goToNextRow()) {
      list.push(TodoRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async setDone(id: number, done: number): Promise<void> {
    const vb: relationalStore.ValuesBucket = { 'done': done };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().update(vb, predicates);
  }

  static async create(todo: Todo): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'user_id': todo.userId,
      'title': todo.title,
      'date': todo.date,
      'done': todo.done,
      'created_at': todo.createdAt
    };
    return Database.getStore().insert(TABLE, vb);
  }

  static async remove(id: number): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().delete(predicates);
  }
}
