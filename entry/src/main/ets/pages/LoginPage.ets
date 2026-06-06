import { router } from '@kit.ArkUI';
import { RouteConstants } from '../constants/RouteConstants';
import { Validator, ValidationResult } from '../utils/Validator';
import { AuthService } from '../service/AuthService';
import { Result } from '../utils/Result';
import { FormField } from '../components/FormField';
import { PrimaryButton } from '../components/PrimaryButton';
import { Logger } from '../utils/Logger';

/**
 * 登录页：账号密码 + 本地校验，登录成功跳主页。
 */
@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;

  private async handleLogin(): Promise<void> {
    const u: ValidationResult = Validator.username(this.username);
    if (!u.valid) {
      this.errorMsg = u.message;
      return;
    }
    const p: ValidationResult = Validator.password(this.password);
    if (!p.valid) {
      this.errorMsg = p.message;
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    const res: Result<number> = await AuthService.login(this.username, this.password);
    this.loading = false;
    if (res.success) {
      router.replaceUrl({ url: RouteConstants.MAIN }).catch((err: Object) => {
        Logger.error(`nav main failed: ${JSON.stringify(err)}`);
      });
    } else {
      this.errorMsg = res.error;
    }
  }

  @Builder
  header() {
    Column() {
      Text('🦎').fontSize(64)
      Text($r('app.string.app_name'))
        .fontSize($r('app.float.font_display'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand_primary'))
        .margin({ top: $r('app.float.space_sm') })
      Text($r('app.string.app_slogan'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: $r('app.float.space_xs') })
    }
    .margin({ top: 72, bottom: 40 })
  }

  build() {
    Column() {
      this.header()

      Column() {
        Text($r('app.string.login_title'))
          .fontSize($r('app.float.font_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: $r('app.float.space_xl') })

        FormField({
          label: $r('app.string.login_username'),
          placeholder: '请输入用户名',
          text: this.username,
          onChange: (v: string): void => {
            this.username = v;
          }
        })
          .margin({ bottom: $r('app.float.space_lg') })

        FormField({
          label: $r('app.string.login_password'),
          placeholder: '请输入密码',
          text: this.password,
          isPassword: true,
          onChange: (v: string): void => {
            this.password = v;
          }
        })

        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize($r('app.float.font_small'))
            .fontColor($r('app.color.urgency_overdue'))
            .width('100%')
            .margin({ top: $r('app.float.space_md') })
        }

        PrimaryButton({
          label: $r('app.string.login_submit'),
          loading: this.loading,
          onTap: (): void => {
            this.handleLogin();
          }
        })
          .margin({ top: $r('app.float.space_xxl') })

        Text($r('app.string.login_to_register'))
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand_primary'))
          .margin({ top: $r('app.float.space_xl') })
          .onClick(() => {
            router.pushUrl({ url: RouteConstants.REGISTER });
          })
      }
      .width('100%')
      .padding($r('app.float.space_xxl'))
      .backgroundColor($r('app.color.surface'))
      .borderRadius($r('app.float.radius_card'))
    }
    .width('100%')
    .height('100%')
    .padding({ left: $r('app.float.space_xl'), right: $r('app.float.space_xl') })
    .backgroundColor($r('app.color.page_background'))
    .alignItems(HorizontalAlign.Center)
  }
}
