import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { WeightLog } from '../model/WeightLog';

const TABLE: string = 'weight_log';

/** 体重记录仓储。listByPet 按日期升序（便于绘制趋势曲线）。 */
export class WeightLogRepository {
  private static map(rs: relationalStore.ResultSet): WeightLog {
    return new WeightLog(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getDouble(rs.getColumnIndex('weight')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: number): Promise<WeightLog[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByAsc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: WeightLog[] = [];
    while (rs.goToNextRow()) {
      list.push(WeightLogRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(log: WeightLog): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': log.petId,
      'date': log.date,
      'weight': log.weight,
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
