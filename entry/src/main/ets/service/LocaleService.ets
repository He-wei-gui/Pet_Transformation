import { i18n } from '@kit.LocalizationKit';
import { Logger } from '../utils/Logger';

const LANG_ZH: string = 'zh-Hans';
const LANG_EN: string = 'en-US';

/**
 * 应用内语言切换。setAppPreferredLanguage 会按应用级持久化语言偏好，
 * 切换后 ArkUI 资源（$r）随配置更新自动以新语言重渲染，重启后依然保持。
 */
export class LocaleService {
  static isEnglish(): boolean {
    try {
      const lang: string = i18n.System.getAppPreferredLanguage();
      return lang.toLowerCase().startsWith('en');
    } catch (err) {
      Logger.error(`getAppPreferredLanguage failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static setEnglish(english: boolean): void {
    try {
      i18n.System.setAppPreferredLanguage(english ? LANG_EN : LANG_ZH);
    } catch (err) {
      Logger.error(`setAppPreferredLanguage failed: ${JSON.stringify(err)}`);
    }
  }
}
