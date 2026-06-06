import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { Photo } from '../model/Photo';

const TABLE: string = 'photo';

/** 成长相册仓储。listByPet 按日期倒序（最新在前）。 */
export class PhotoRepository {
  private static map(rs: relationalStore.ResultSet): Photo {
    return new Photo(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getLong(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('date')),
      rs.getString(rs.getColumnIndex('uri')),
      rs.getDouble(rs.getColumnIndex('length_cm')),
      rs.getString(rs.getColumnIndex('caption')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByPet(petId: number): Promise<Photo[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('date');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: Photo[] = [];
    while (rs.goToNextRow()) {
      list.push(PhotoRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(photo: Photo): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'pet_id': photo.petId,
      'date': photo.date,
      'uri': photo.uri,
      'length_cm': photo.lengthCm,
      'caption': photo.caption,
      'created_at': photo.createdAt
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
