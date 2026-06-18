import { router } from '@kit.ArkUI';
import { Validator, ValidationResult } from '../utils/Validator';
import { AuthService } from '../service/AuthService';
import { Result } from '../utils/Result';
import { FormField } from '../components/FormField';
import { PrimaryButton } from '../components/PrimaryButton';
import { EmailCodeField } from '../components/EmailCodeField';
import { TopBar } from '../components/TopBar';
import { Toast } from '../utils/Dialogs';
import { Logger } from '../utils/Logger';
import { I18n } from '../utils/I18n';

/**
 * 找回密码页：用户名 + 邮箱 + 验证码 + 新密码。
 * 验证码发到注册邮箱（服务器端校验），用户名与邮箱须匹配同一账号后才重置密码。
 */
@Entry
@Component
struct ForgotPasswordPage {
  @State username: string = '';
  @State email: string = '';
  @State code: string = '';
  @State password: string = '';
  @State confirm: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;

  private localize(key: string): string {
    return I18n.t(getContext(this), key);
  }

  private validate(): ValidationResult {
    const u: ValidationResult = Validator.username(this.username);
    if (!u.valid) {
      return u;
    }
    const em: ValidationResult = Validator.email(this.email);
    if (!em.valid) {
      return em;
    }
    const c: ValidationResult = Validator.code(this.code);
    if (!c.valid) {
      return c;
    }
    const p: ValidationResult = Validator.password(this.password);
    if (!p.valid) {
      return p;
    }
    return Validator.passwordMatch(this.password, this.confirm);
  }

  private async handleReset(): Promise<void> {
    const check: ValidationResult = this.validate();
    if (!check.valid) {
      this.errorMsg = this.localize(check.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    const res: Result<string> = await AuthService.resetPassword(this.username, this.email, this.code, this.password);
    this.loading = false;
    if (res.success) {
      Toast.msg($r('app.string.forgot_done'));
      router.back();
    } else {
      this.errorMsg = this.localize(res.error);
    }
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.forgot_title') })

      Scroll() {
        Column({ space: 16 }) {
          Text($r('app.string.forgot_desc'))
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')

          FormField({
            label: $r('app.string.login_username'),
            placeholder: $r('app.string.hint_username'),
            text: this.username,
            onChange: (v: string): void => {
              this.username = v;
            }
          })

          EmailCodeField({ purpose: 'reset', email: this.email, code: this.code })

          FormField({
            label: $r('app.string.forgot_new_password'),
            placeholder: $r('app.string.hint_password_min'),
            text: this.password,
            isPassword: true,
            onChange: (v: string): void => {
              this.password = v;
            }
          })

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
          }

          PrimaryButton({
            label: $r('app.string.forgot_submit'),
            loading: this.loading,
            onTap: (): void => {
              this.handleReset();
            }
          })
            .margin({ top: $r('app.float.space_md') })
        }
        .width('100%')
        .padding($r('app.float.space_xxl'))
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
