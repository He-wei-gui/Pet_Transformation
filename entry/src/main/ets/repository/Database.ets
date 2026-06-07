import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

const DB_NAME: string = 'pet_tracker.db';

const CREATE_USER: string =
  'CREATE TABLE IF NOT EXISTS user (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'username TEXT NOT NULL UNIQUE, ' +
  'password_hash TEXT NOT NULL, ' +
  'salt TEXT NOT NULL, ' +
  'nickname TEXT, ' +
  'avatar TEXT, ' +
  'created_at TEXT)';

const CREATE_PET: string =
  'CREATE TABLE IF NOT EXISTS pet (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'name TEXT NOT NULL, ' +
  'species TEXT, ' +
  'avatar TEXT, ' +
  'birth_date TEXT, ' +
  'feed_interval INTEGER, ' +
  'sub_interval INTEGER, ' +
  'next_feed_date TEXT, ' +
  'next_sub_date TEXT, ' +
  'note TEXT)';

const CREATE_FEED: string =
  'CREATE TABLE IF NOT EXISTS feed_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, food_type TEXT, amount TEXT, note TEXT, created_at TEXT)';

const CREATE_WEIGHT: string =
  'CREATE TABLE IF NOT EXISTS weight_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, weight REAL, created_at TEXT)';

const CREATE_SUBSTRATE: string =
  'CREATE TABLE IF NOT EXISTS substrate_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, substrate_type TEXT, note TEXT, created_at TEXT)';

const CREATE_MOLT: string =
  'CREATE TABLE IF NOT EXISTS molt_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, status TEXT, note TEXT, created_at TEXT)';

const CREATE_ENV: string =
  'CREATE TABLE IF NOT EXISTS env_log (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, temperature REAL, humidity REAL, uvb REAL, note TEXT, created_at TEXT)';

const CREATE_PHOTO: string =
  'CREATE TABLE IF NOT EXISTS photo (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'pet_id INTEGER NOT NULL, ' +
  'date TEXT, uri TEXT, length_cm REAL, caption TEXT, created_at TEXT)';

const CREATE_TODO: string =
  'CREATE TABLE IF NOT EXISTS todo (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'title TEXT NOT NULL, date TEXT, done INTEGER DEFAULT 0, created_at TEXT)';

/**
 * 本地关系型数据库（SQLite）管理器，单例持有 RdbStore。
 * 须在使用任何 Repository 之前调用 init()（EntryAbility.onCreate 中执行）。
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
    await store.executeSql(CREATE_USER);
    await store.executeSql(CREATE_PET);
    await store.executeSql(CREATE_FEED);
    await store.executeSql(CREATE_WEIGHT);
    await store.executeSql(CREATE_SUBSTRATE);
    await store.executeSql(CREATE_MOLT);
    await store.executeSql(CREATE_ENV);
    await store.executeSql(CREATE_PHOTO);
    await store.executeSql(CREATE_TODO);
  }
}
