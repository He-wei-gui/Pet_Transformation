import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { Pet } from '../model/Pet';

const TABLE: string = 'pet';

/**
 * 宠物仓储。所有查询按 user_id 隔离，保证多用户数据互不可见。
 */
export class PetRepository {
  private static map(rs: relationalStore.ResultSet): Pet {
    return new Pet(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('user_id')),
      rs.getString(rs.getColumnIndex('name')),
      rs.getString(rs.getColumnIndex('species')),
      rs.getString(rs.getColumnIndex('avatar')),
      rs.getString(rs.getColumnIndex('birth_date')),
      rs.getLong(rs.getColumnIndex('feed_interval')),
      rs.getLong(rs.getColumnIndex('sub_interval')),
      rs.getString(rs.getColumnIndex('next_feed_date')),
      rs.getString(rs.getColumnIndex('next_sub_date')),
      rs.getString(rs.getColumnIndex('note'))
    );
  }

  private static toValues(pet: Pet): relationalStore.ValuesBucket {
    const vb: relationalStore.ValuesBucket = {
      'user_id': pet.userId,
      'name': pet.name,
      'species': pet.species,
      'avatar': pet.avatar,
      'birth_date': pet.birthDate,
      'feed_interval': pet.feedInterval,
      'sub_interval': pet.subInterval,
      'next_feed_date': pet.nextFeedDate,
      'next_sub_date': pet.nextSubDate,
      'note': pet.note
    };
    return vb;
  }

  static async findByUser(userId: number): Promise<Pet[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('user_id', userId);
    predicates.orderByAsc('id');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: Pet[] = [];
    while (rs.goToNextRow()) {
      list.push(PetRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async findById(id: number): Promise<Pet | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    let pet: Pet | null = null;
    if (rs.goToFirstRow()) {
      pet = PetRepository.map(rs);
    }
    rs.close();
    return pet;
  }

  static async create(pet: Pet): Promise<number> {
    return Database.getStore().insert(TABLE, PetRepository.toValues(pet));
  }

  static async update(pet: Pet): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', pet.id);
    await Database.getStore().update(PetRepository.toValues(pet), predicates);
  }

  /** 更新动态排程产生的两个 next 日期。 */
  static async updateNextDates(id: number, nextFeedDate: string, nextSubDate: string): Promise<void> {
    const vb: relationalStore.ValuesBucket = {
      'next_feed_date': nextFeedDate,
      'next_sub_date': nextSubDate
    };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().update(vb, predicates);
  }

  static async remove(id: number): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().delete(predicates);
  }
}
