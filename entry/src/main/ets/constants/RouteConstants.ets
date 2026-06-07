/**
 * 全局路由常量。所有页面均通过 @ohos.router 以 url 跳转，
 * 这些 url 同时需要在 resources/base/profile/main_pages.json 中登记。
 */
export class RouteConstants {
  static readonly INDEX: string = 'pages/Index';
  static readonly LOGIN: string = 'pages/LoginPage';
  static readonly REGISTER: string = 'pages/RegisterPage';
  static readonly MAIN: string = 'pages/MainPage';

  static readonly PET_DETAIL: string = 'view/pets/PetDetailPage';
  static readonly PET_EDIT: string = 'view/pets/PetEditPage';
  static readonly PROFILE: string = 'view/mine/ProfilePage';

  static readonly WEIGHT_LOG: string = 'view/logs/WeightLogPage';
  static readonly FEED_LOG: string = 'view/logs/FeedLogPage';
  static readonly SUBSTRATE_LOG: string = 'view/logs/SubstrateLogPage';
  static readonly MOLT_LOG: string = 'view/logs/MoltLogPage';
  static readonly ENV_LOG: string = 'view/logs/EnvLogPage';
  static readonly ALBUM: string = 'view/album/AlbumPage';
}

/**
 * AppStorage / 跨页持久化中使用的键名常量，集中管理避免硬编码字符串。
 */
export class StorageKeys {
  static readonly SESSION_USER_ID: string = 'session_user_id';
  static readonly SESSION_NICKNAME: string = 'session_nickname';
  static readonly CURRENT_PET_ID: string = 'current_pet_id';
  static readonly COLOR_MODE: string = 'pref_color_mode';
}
