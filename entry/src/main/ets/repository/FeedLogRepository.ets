import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { FeedLog } from '../model/FeedLog';

const TABLE: string = 'feed_log';

/** 喂食记录仓储。listByPet 按日期倒序（最新在前）。 */
export class FeedLogRepository {
  private static map(rs: relationalStore.ResultSet): FeedLog {
    return new FeedLog(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getString(rs.getColumnIndex('food_type')),
      rs.getString(rs.getColumnIndex('amount')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: number): Promise<FeedLog[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: FeedLog[] = [];
    while (rs.goToNextRow()) {
      list.push(FeedLogRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(log: FeedLog): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': log.petId,
      'date': log.date,
      'food_type': log.foodType,
      'amount': log.amount,
      'note': log.note,
      'created_at': log.createdAt
    };
    return Database.getStore().insert(TABLE, vb);
  }

  static async remove(id: number): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().delete(predicates);
  }

  static async removeByPet(petId: number): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    await Database.getStore().delete(predicates);
  }
}
