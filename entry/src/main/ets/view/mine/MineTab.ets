import { router } from '@kit.ArkUI';
import { PetService } from '../../service/PetService';
import { AuthService } from '../../service/AuthService';
import { SessionStore } from '../../service/SessionStore';
import { ThemeService } from '../../service/ThemeService';
import { LocaleService } from '../../service/LocaleService';
import { RouteConstants } from '../../constants/RouteConstants';
import { UserRepository } from '../../repository/UserRepository';
import { User } from '../../model/User';
import { PetAvatar } from '../../components/PetAvatar';
import { Logger } from '../../utils/Logger';

/**
 * 我的：账户信息、统计概览与退出登录。（主题切换在 Phase 5 接入）
 */
@Component
export struct MineTab {
  @Prop @Watch('reload') tick: number = 0;
  @State nickname: string = '';
  @State petCount: number = 0;
  @State avatar: string = '😀';
  @State darkMode: boolean = false;
  @State english: boolean = false;

  aboutToAppear(): void {
    this.darkMode = ThemeService.isDark();
    this.english = LocaleService.isEnglish();
    this.reload();
  }

  @Builder
  langButton(label: string, isEnglish: boolean) {
    Text(label)
      .fontSize($r('app.float.font_caption'))
      .fontColor(this.english === isEnglish ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius($r('app.float.radius_pill'))
      .backgroundColor(this.english === isEnglish ? $r('app.color.brand_primary') : $r('app.color.input_background'))
      .onClick(() => {
        this.english = isEnglish;
        LocaleService.setEnglish(isEnglish);
      })
  }

  private async reload(): Promise<void> {
    try {
      this.nickname = SessionStore.currentNickname();
      this.petCount = (await PetService.listPets()).length;
      this.darkMode = ThemeService.isDark();
      const user: User | null = await UserRepository.findById(SessionStore.currentUserId());
      this.avatar = (user !== null && user.avatar.length > 0) ? user.avatar : '😀';
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
        PetAvatar({ avatar: this.avatar, diameter: 88 })

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

        Row() {
          Text('✏️')
            .fontSize(18)
          Text($r('app.string.profile_edit'))
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .margin({ left: $r('app.float.space_md') })
          Text('›')
            .fontSize(22)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding($r('app.float.space_lg'))
        .margin({ top: $r('app.float.space_md') })
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.radius_card'))
        .onClick(() => {
          router.pushUrl({ url: RouteConstants.PROFILE });
        })

        Row() {
          Text('🌙')
            .fontSize(18)
          Text($r('app.string.mine_theme'))
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .margin({ left: $r('app.float.space_md') })
          Toggle({ type: ToggleType.Switch, isOn: this.darkMode })
            .selectedColor($r('app.color.brand_primary'))
            .onChange((isOn: boolean) => {
              this.darkMode = isOn;
              ThemeService.setDark(getContext(this), isOn);
            })
        }
        .width('100%')
        .padding($r('app.float.space_lg'))
        .margin({ top: $r('app.float.space_md') })
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.radius_card'))

        Row() {
          Text('🌐')
            .fontSize(18)
          Text($r('app.string.mine_language'))
            .fontSize($r('app.float.font_body'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .margin({ left: $r('app.float.space_md') })
          Row({ space: 8 }) {
            this.langButton('中文', false)
            this.langButton('EN', true)
          }
        }
        .width('100%')
        .padding($r('app.float.space_lg'))
        .margin({ top: $r('app.float.space_md') })
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
