import { router } from '@kit.ArkUI';
import { RouteConstants } from '../constants/RouteConstants';
import { Validator, ValidationResult } from '../utils/Validator';
import { AuthService } from '../service/AuthService';
import { Result } from '../utils/Result';
import { FormField } from '../components/FormField';
import { PrimaryButton } from '../components/PrimaryButton';
import { Logger } from '../utils/Logger';
import { I18n } from '../utils/I18n';

/**
 * 注册页：用户名 + 昵称 + 密码 + 确认密码，本地校验；注册成功自动登录并进入主页。
 */
@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State nickname: string = '';
  @State password: string = '';
  @State confirm: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;

  private validate(): ValidationResult {
    const u: ValidationResult = Validator.username(this.username);
    if (!u.valid) {
      return u;
    }
    const p: ValidationResult = Validator.password(this.password);
    if (!p.valid) {
      return p;
    }
    return Validator.passwordMatch(this.password, this.confirm);
  }

  private async handleRegister(): Promise<void> {
    const check: ValidationResult = this.validate();
    if (!check.valid) {
      this.errorMsg = I18n.t(getContext(this), check.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    const res: Result<number> = await AuthService.register(this.username, this.password, this.nickname);
    this.loading = false;
    if (res.success) {
      router.replaceUrl({ url: RouteConstants.MAIN }).catch((err: Object) => {
        Logger.error(`nav main failed: ${JSON.stringify(err)}`);
      });
    } else {
      this.errorMsg = I18n.t(getContext(this), res.error);
    }
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Text('🦎').fontSize(56)
          Text($r('app.string.register_title'))
            .fontSize($r('app.float.font_title'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.brand_primary'))
            .margin({ top: $r('app.float.space_sm') })
        }
        .margin({ top: 56, bottom: 32 })

        Column() {
          FormField({
            label: $r('app.string.login_username'),
            placeholder: $r('app.string.hint_username_rule'),
            text: this.username,
            onChange: (v: string): void => {
              this.username = v;
            }
          })
            .margin({ bottom: $r('app.float.space_lg') })

          FormField({
            label: $r('app.string.register_nickname'),
            placeholder: $r('app.string.hint_nickname'),
            text: this.nickname,
            onChange: (v: string): void => {
              this.nickname = v;
            }
          })
            .margin({ bottom: $r('app.float.space_lg') })

          FormField({
            label: $r('app.string.login_password'),
            placeholder: $r('app.string.hint_password_min'),
            text: this.password,
            isPassword: true,
            onChange: (v: string): void => {
              this.password = v;
            }
          })
            .margin({ bottom: $r('app.float.space_lg') })

          FormField({
            label: $r('app.string.register_password_confirm'),
            placeholder: $r('app.string.hint_password_confirm'),
            text: this.confirm,
            isPassword: true,
            onChange: (v: string): void => {
              this.confirm = v;
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
            label: $r('app.string.register_submit'),
            loading: this.loading,
            onTap: (): void => {
              this.handleRegister();
            }
          })
            .margin({ top: $r('app.float.space_xxl') })

          Text($r('app.string.register_to_login'))
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand_primary'))
            .margin({ top: $r('app.float.space_xl') })
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .padding($r('app.float.space_xxl'))
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.radius_card'))
      }
      .width('100%')
      .padding({ left: $r('app.float.space_xl'), right: $r('app.float.space_xl'), bottom: 40 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .scrollBar(BarState.Off)
  }
}
