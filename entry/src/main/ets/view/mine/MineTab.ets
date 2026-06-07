import { router } from '@kit.ArkUI';
import { PetService } from '../../service/PetService';
import { AuthService } from '../../service/AuthService';
import { SessionStore } from '../../service/SessionStore';
import { RouteConstants } from '../../constants/RouteConstants';
import { Logger } from '../../utils/Logger';

/**
 * 我的：账户信息、统计概览与退出登录。（主题切换在 Phase 5 接入）
 */
@Component
export struct MineTab {
  @Prop @Watch('reload') tick: number = 0;
  @State nickname: string = '';
  @State petCount: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.nickname = SessionStore.currentNickname();
      this.petCount = (await PetService.listPets()).length;
    } catch (err) {
      Logger.error(`load mine failed: ${JSON.stringify(err)}`);
    }
  }

  private async handleLogout(): Promise<void> {
    await AuthService.logout();
    router.replaceUrl({ url: RouteConstants.LOGIN }).catch((err: Object) => {
      Logger.error(`logout nav failed: ${JSON.stringify(err)}`);
    });
  }

  build() {
    Column() {
      Column() {
        Stack() {
          Text('👤').fontSize(44)
        }
        .width(88)
        .height(88)
        .borderRadius(44)
        .backgroundColor($r('app.color.surface'))

        Text(this.nickname)
          .fontSize($r('app.float.font_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_brand'))
          .margin({ top: $r('app.float.space_md') })
      }
      .width('100%')
      .padding({ top: 64, bottom: 32 })
      .backgroundColor($r('app.color.brand_primary'))

      Column() {
        Row() {
          Column() {
            Text(`${this.petCount}`)
              .fontSize($r('app.float.font_title'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.brand_primary'))
            Text($r('app.string.mine_stat_pets'))
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: $r('app.float.space_xs') })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding($r('app.float.space_xl'))
        .margin({ top: $r('app.float.space_lg') })
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.radius_card'))

        Blank()

        Button($r('app.string.mine_logout'))
          .type(ButtonType.Capsule)
          .width('100%')
          .height($r('app.float.control_height'))
          .fontColor($r('app.color.urgency_overdue'))
          .backgroundColor($r('app.color.surface'))
          .borderWidth(1)
          .borderColor($r('app.color.urgency_overdue'))
          .onClick(() => {
            this.handleLogout();
          })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: $r('app.float.space_xl'), right: $r('app.float.space_xl'), bottom: $r('app.float.space_xxl') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
