import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { EnvLog } from '../model/EnvLog';

const TABLE: string = 'env_log';

/** 环境记录仓储。listByPet 按日期升序（便于绘制温湿度曲线）。 */
export class EnvLogRepository {
  private static map(rs: relationalStore.ResultSet): EnvLog {
    return new EnvLog(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getDouble(rs.getColumnIndex('temperature')),
      rs.getDouble(rs.getColumnIndex('humidity')),
      rs.getDouble(rs.getColumnIndex('uvb')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: number): Promise<EnvLog[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByAsc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: EnvLog[] = [];
    while (rs.goToNextRow()) {
      list.push(EnvLogRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(log: EnvLog): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': log.petId,
      'date': log.date,
      'temperature': log.temperature,
      'humidity': log.humidity,
      'uvb': log.uvb,
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
