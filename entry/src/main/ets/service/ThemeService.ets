import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { StorageKeys } from '../constants/RouteConstants';
import { Logger } from '../utils/Logger';

const STORE_NAME: string = 'settings';
const KEY_DARK: string = 'dark_mode';

/**
 * 主题服务：浅/深色模式的应用与持久化。
 * 启动时 init() 读取并应用；MineTab 切换时 setDark() 写回并即时生效。
 */
export class ThemeService {
  private static pref: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    try {
      ThemeService.pref = await preferences.getPreferences(context, STORE_NAME);
      const dark: boolean = await ThemeService.pref.get(KEY_DARK, false) as boolean;
      ThemeService.apply(context, dark);
      AppStorage.setOrCreate(StorageKeys.COLOR_MODE, dark);
    } catch (err) {
      Logger.error(`theme init failed: ${JSON.stringify(err)}`);
    }
  }

  private static apply(context: common.Context, dark: boolean): void {
    const mode: ConfigurationConstant.ColorMode = dark
      ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    context.getApplicationContext().setColorMode(mode);
  }

  static async setDark(context: common.Context, dark: boolean): Promise<void> {
    ThemeService.apply(context, dark);
    AppStorage.setOrCreate(StorageKeys.COLOR_MODE, dark);
    if (ThemeService.pref !== null) {
      await ThemeService.pref.put(KEY_DARK, dark);
      await ThemeService.pref.flush();
    }
  }

  static isDark(): boolean {
    return AppStorage.get<boolean>(StorageKeys.COLOR_MODE) ?? false;
  }
}
