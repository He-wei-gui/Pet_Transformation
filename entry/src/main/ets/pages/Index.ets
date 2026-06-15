import { router } from '@kit.ArkUI';
import { RouteConstants, StorageKeys } from '../constants/RouteConstants';
import { Logger } from '../utils/Logger';

/**
 * 启动页 / 路由分发：读取会话，已登录跳主页，未登录跳登录页。
 * 会话由 EntryAbility 在启动时从 preferences 载入到 AppStorage。
 */
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    const openid: string = AppStorage.get<string>(StorageKeys.SESSION_USER_ID) ?? '';
    const target: string = openid.length > 0 ? RouteConstants.MAIN : RouteConstants.LOGIN;
    setTimeout(() => {
      router.replaceUrl({ url: target }).catch((err: Object) => {
        Logger.error(`route to ${target} failed: ${JSON.stringify(err)}`);
      });
    }, 500);
  }

  build() {
    Column() {
      Text('🦎')
        .fontSize(72)
      Text($r('app.string.app_name'))
        .fontSize($r('app.float.font_display'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand_primary'))
        .margin({ top: $r('app.float.space_lg') })
      Text($r('app.string.app_slogan'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: $r('app.float.space_sm') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
