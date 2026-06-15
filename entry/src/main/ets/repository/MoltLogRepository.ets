import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { MoltLog } from '../model/MoltLog';

const TABLE: string = 'molt_log';

/** 蜕皮记录仓储。listByPet 按日期倒序（最新在前）。 */
export class MoltLogRepository {
  private static map(rs: relationalStore.ResultSet): MoltLog {
    return new MoltLog(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getString(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getString(rs.getColumnIndex('status')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: string): Promise<MoltLog[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: MoltLog[] = [];
    while (rs.goToNextRow()) {
      list.push(MoltLogRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(log: MoltLog): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': log.petId,
      'date': log.date,
      'status': log.status,
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

  static async removeByPet(petId: string): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    await Database.getStore().delete(predicates);
  }
}
