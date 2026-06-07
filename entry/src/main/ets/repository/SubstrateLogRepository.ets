import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { SubstrateLog } from '../model/SubstrateLog';

const TABLE: string = 'substrate_log';

/** 换料记录仓储。listByPet 按日期倒序（最新在前）。 */
export class SubstrateLogRepository {
  private static map(rs: relationalStore.ResultSet): SubstrateLog {
    return new SubstrateLog(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getString(rs.getColumnIndex('substrate_type')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: number): Promise<SubstrateLog[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: SubstrateLog[] = [];
    while (rs.goToNextRow()) {
      list.push(SubstrateLogRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(log: SubstrateLog): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': log.petId,
      'date': log.date,
      'substrate_type': log.substrateType,
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
