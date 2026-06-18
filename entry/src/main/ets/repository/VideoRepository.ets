import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { PetVideo } from '../model/PetVideo';

const TABLE: string = 'video';

/** 成长视频仓储（本地 SQLite）。listByUser 按创建时间倒序（最新在前）。 */
export class VideoRepository {
  private static map(rs: relationalStore.ResultSet): PetVideo {
    return new PetVideo(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getString(rs.getColumnIndex('user_id')),
      rs.getString(rs.getColumnIndex('pet_id')),
      rs.getString(rs.getColumnIndex('uri')),
      rs.getString(rs.getColumnIndex('caption')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async listByUser(userId: string): Promise<PetVideo[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('user_id', userId);
    predicates.orderByDesc('id');
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    const list: PetVideo[] = [];
    while (rs.goToNextRow()) {
      list.push(VideoRepository.map(rs));
    }
    rs.close();
    return list;
  }

  static async create(video: PetVideo): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'user_id': video.userId,
      'pet_id': video.petId,
      'uri': video.uri,
      'caption': video.caption,
      'created_at': video.createdAt
    };
    return Database.getStore().insert(TABLE, vb);
  }

  static async remove(id: number): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().delete(predicates);
  }
}
