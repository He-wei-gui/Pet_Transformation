import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

const DB_NAME: string = 'pet_tracker.db';

// 接入云端后，user/pet/feed/weight/substrate 走云端 API，本地只保留尚未上云的模块。
// pet_id / user_id 为云端标识字符串，故用 TEXT。

const CREATE_MOLT: string =
  'CREATE TABLE IF NOT EXISTS molt_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id TEXT NOT NULL, ' +
  'date TEXT, status TEXT, note TEXT, created_at TEXT)';

const CREATE_ENV: string =
  'CREATE TABLE IF NOT EXISTS env_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id TEXT NOT NULL, ' +
  'date TEXT, temperature REAL, humidity REAL, uvb REAL, note TEXT, created_at TEXT)';

const CREATE_TODO: string =
  'CREATE TABLE IF NOT EXISTS todo (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id TEXT NOT NULL, ' +
  'title TEXT NOT NULL, date TEXT, done INTEGER DEFAULT 0, created_at TEXT)';

/**
 * 本地关系型数据库（SQLite）管理器，单例持有 RdbStore。
 * 接入云端后仅承载尚未上云的本地模块（蜕皮/环境/待办；相册已上云）。
 * 须在使用任何本地 Repository 之前调用 init()（EntryAbility.onWindowStageCreate 中执行）。
 */
export class Database {
  private static store: relationalStore.RdbStore | null = null;

  static async init(context: common.Context): Promise<void> {
    if (Database.store !== null) {
      return;
    }
    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
      await Database.createTables(store);
      Database.store = store;
      Logger.info('Database initialized');
    } catch (err) {
      Logger.error(`Database init failed: ${JSON.stringify(err)}`);
      throw new Error('数据库初始化失败');
    }
  }

  static getStore(): relationalStore.RdbStore {
    if (Database.store === null) {
      throw new Error('数据库尚未初始化');
    }
    return Database.store;
  }

  private static async createTables(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(CREATE_MOLT);
    await store.executeSql(CREATE_ENV);
    await store.executeSql(CREATE_TODO);
  }
}
