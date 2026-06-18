import { AuthService } from '../service/AuthService';
import { Validator, ValidationResult } from '../utils/Validator';
import { Result } from '../utils/Result';
import { I18n } from '../utils/I18n';
import { FormField } from './FormField';

/**
 * 邮箱 + 验证码 输入块：内置「发送验证码」按钮与 60 秒倒计时。
 * 验证码发送/校验在服务器端完成，本组件只负责采集 email/code 并触发发送。
 * purpose: 'register'（注册，邮箱须未注册）| 'reset'（找回，邮箱须已注册）。
 */
@Component
export struct EmailCodeField {
  @Prop purpose: string = 'register';
  @Link email: string;
  @Link code: string;
  @State private sending: boolean = false;
  @State private countdown: number = 0;
  @State private hint: string = '';
  @State private hintIsError: boolean = false;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private localize(key: string): string {
    return I18n.t(getContext(this), key);
  }

  private async sendCode(): Promise<void> {
    const e: ValidationResult = Validator.email(this.email);
    if (!e.valid) {
      this.hintIsError = true;
      this.hint = this.localize(e.messageKey);
      return;
    }
    this.sending = true;
    this.hint = '';
    const r: Result<string> = await AuthService.sendCode(this.email, this.purpose);
    this.sending = false;
    if (!r.success) {
      this.hintIsError = true;
      this.hint = this.localize(r.error);
      return;
    }
    this.hintIsError = false;
    this.hint = this.localize('auth_code_sent');
    this.countdown = 60;
    this.timerId = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0 && this.timerId >= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
      }
    }, 1000);
  }

  private sendLabel(): string {
    if (this.countdown > 0) {
      return `${this.countdown}s`;
    }
    return this.localize('auth_send_code');
  }

  build() {
    Column({ space: 12 }) {
      FormField({
        label: $r('app.string.auth_email'),
        placeholder: $r('app.string.hint_email'),
        text: this.email,
        onChange: (v: string): void => {
          this.email = v;
        }
      })

      Row({ space: 12 }) {
        Column() {
          FormField({
            label: $r('app.string.auth_code'),
            placeholder: $r('app.string.hint_code'),
            text: this.code,
            inputType: InputType.Number,
            onChange: (v: string): void => {
              this.code = v;
            }
          })
        }
        .layoutWeight(1)

        Button(this.sendLabel())
          .fontSize($r('app.float.font_caption'))
          .height($r('app.float.control_height'))
          .backgroundColor(this.countdown > 0 ? $r('app.color.input_background') : $r('app.color.brand_primary'))
          .fontColor(this.countdown > 0 ? $r('app.color.text_secondary') : Color.White)
          .enabled(this.countdown === 0 && !this.sending)
          .onClick(() => {
            this.sendCode();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize($r('app.float.font_small'))
          .fontColor(this.hintIsError ? $r('app.color.urgency_overdue') : $r('app.color.brand_primary'))
          .width('100%')
      }
    }
    .width('100%')
  }
}
