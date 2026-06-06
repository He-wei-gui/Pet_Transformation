import { relationalStore } from '@kit.ArkData';
import { Database } from './Database';
import { User } from '../model/User';

const TABLE: string = 'user';

/**
 * 用户仓储。封装对 user 表的读写，业务层不直接接触 RDB。
 */
export class UserRepository {
  private static map(rs: relationalStore.ResultSet): User {
    return new User(
      rs.getLong(rs.getColumnIndex('id')),
      rs.getString(rs.getColumnIndex('username')),
      rs.getString(rs.getColumnIndex('password_hash')),
      rs.getString(rs.getColumnIndex('salt')),
      rs.getString(rs.getColumnIndex('nickname')),
      rs.getString(rs.getColumnIndex('avatar')),
      rs.getString(rs.getColumnIndex('created_at'))
    );
  }

  static async findByUsername(username: string): Promise<User | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('username', username);
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    let user: User | null = null;
    if (rs.goToFirstRow()) {
      user = UserRepository.map(rs);
    }
    rs.close();
    return user;
  }

  static async findById(id: number): Promise<User | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    const rs: relationalStore.ResultSet = await Database.getStore().query(predicates);
    let user: User | null = null;
    if (rs.goToFirstRow()) {
      user = UserRepository.map(rs);
    }
    rs.close();
    return user;
  }

  static async create(user: User): Promise<number> {
    const vb: relationalStore.ValuesBucket = {
      'username': user.username,
      'password_hash': user.passwordHash,
      'salt': user.salt,
      'nickname': user.nickname,
      'avatar': user.avatar,
      'created_at': user.createdAt
    };
    return Database.getStore().insert(TABLE, vb);
  }

  static async updateProfile(id: number, nickname: string, avatar: string): Promise<void> {
    const vb: relationalStore.ValuesBucket = { 'nickname': nickname, 'avatar': avatar };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE);
    predicates.equalTo('id', id);
    await Database.getStore().update(vb, predicates);
  }
}
