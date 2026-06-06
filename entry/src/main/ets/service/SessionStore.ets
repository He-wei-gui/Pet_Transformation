import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { StorageKeys } from '../constants/RouteConstants';
import { Logger } from '../utils/Logger';

const STORE_NAME: string = 'session';
const KEY_USER_ID: string = 'user_id';
const KEY_NICKNAME: string = 'nickname';

/**
 * 会话存储：用 preferences 持久化登录态，并镜像到 AppStorage 供页面同步读取。
 * 须在启动时 init() + restoreToAppStorage()（EntryAbility 中执行）。
 */
export class SessionStore {
  private static pref: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    if (SessionStore.pref !== null) {
      return;
    }
    SessionStore.pref = await preferences.getPreferences(context, STORE_NAME);
  }

  private static store(): preferences.Preferences {
    if (SessionStore.pref === null) {
      throw new Error('会话存储尚未初始化');
    }
    return SessionStore.pref;
  }

  static async save(userId: number, nickname: string): Promise<void> {
    const p: preferences.Preferences = SessionStore.store();
    await p.put(KEY_USER_ID, userId);
    await p.put(KEY_NICKNAME, nickname);
    await p.flush();
    AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, userId);
    AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, nickname);
  }

  static async clear(): Promise<void> {
    const p: preferences.Preferences = SessionStore.store();
    await p.delete(KEY_USER_ID);
    await p.delete(KEY_NICKNAME);
    await p.flush();
    AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, 0);
    AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, '');
  }

  static async restoreToAppStorage(): Promise<void> {
    try {
      const p: preferences.Preferences = SessionStore.store();
      const userId: number = await p.get(KEY_USER_ID, 0) as number;
      const nickname: string = await p.get(KEY_NICKNAME, '') as string;
      AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, userId);
      AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, nickname);
    } catch (err) {
      Logger.error(`restore session failed: ${JSON.stringify(err)}`);
      AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, 0);
    }
  }

  static currentUserId(): number {
    return AppStorage.get<number>(StorageKeys.SESSION_USER_ID) ?? 0;
  }

  static currentNickname(): string {
    return AppStorage.get<string>(StorageKeys.SESSION_NICKNAME) ?? '';
  }
}
