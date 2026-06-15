import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { StorageKeys } from '../constants/RouteConstants';
import { Logger } from '../utils/Logger';

const STORE_NAME: string = 'session';
const KEY_OPENID: string = 'openid';
const KEY_NICKNAME: string = 'nickname';
const KEY_TOKEN: string = 'token';

/**
 * 会话存储：用 preferences 持久化登录态，并镜像到 AppStorage 供页面同步读取。
 * 接入云端后，用户标识为云端 openid（字符串），并持有云端鉴权 token。
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

  static async save(openid: string, nickname: string, token: string): Promise<void> {
    const p: preferences.Preferences = SessionStore.store();
    await p.put(KEY_OPENID, openid);
    await p.put(KEY_NICKNAME, nickname);
    await p.put(KEY_TOKEN, token);
    await p.flush();
    AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, openid);
    AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, nickname);
    AppStorage.setOrCreate(StorageKeys.SESSION_TOKEN, token);
  }

  static async clear(): Promise<void> {
    const p: preferences.Preferences = SessionStore.store();
    await p.delete(KEY_OPENID);
    await p.delete(KEY_NICKNAME);
    await p.delete(KEY_TOKEN);
    await p.flush();
    AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, '');
    AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, '');
    AppStorage.setOrCreate(StorageKeys.SESSION_TOKEN, '');
  }

  static async restoreToAppStorage(): Promise<void> {
    try {
      const p: preferences.Preferences = SessionStore.store();
      const openid: string = await p.get(KEY_OPENID, '') as string;
      const nickname: string = await p.get(KEY_NICKNAME, '') as string;
      const token: string = await p.get(KEY_TOKEN, '') as string;
      AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, openid);
      AppStorage.setOrCreate(StorageKeys.SESSION_NICKNAME, nickname);
      AppStorage.setOrCreate(StorageKeys.SESSION_TOKEN, token);
    } catch (err) {
      Logger.error(`restore session failed: ${JSON.stringify(err)}`);
      AppStorage.setOrCreate(StorageKeys.SESSION_USER_ID, '');
      AppStorage.setOrCreate(StorageKeys.SESSION_TOKEN, '');
    }
  }

  /** 当前登录用户的 openid（未登录为空串）。 */
  static currentUserId(): string {
    return AppStorage.get<string>(StorageKeys.SESSION_USER_ID) ?? '';
  }

  static currentNickname(): string {
    return AppStorage.get<string>(StorageKeys.SESSION_NICKNAME) ?? '';
  }

  static currentToken(): string {
    return AppStorage.get<string>(StorageKeys.SESSION_TOKEN) ?? '';
  }

  static isLoggedIn(): boolean {
    return SessionStore.currentUserId().length > 0;
  }
}
