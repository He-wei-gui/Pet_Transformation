import { common } from '@kit.AbilityKit';

/**
 * 运行时把字符串资源名解析为当前语言文案，
 * 供校验/服务层返回的 messageKey 在页面落地为中/英文。
 */
export class I18n {
  static t(context: common.Context, key: string): string {
    if (key.length === 0) {
      return '';
    }
    try {
      return context.resourceManager.getStringByNameSync(key);
    } catch (err) {
      return key;
    }
  }
}
