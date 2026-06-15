import { router } from '@kit.ArkUI';
import { User } from '../../model/User';
import { UserRepository } from '../../repository/UserRepository';
import { AuthService } from '../../service/AuthService';
import { SessionStore } from '../../service/SessionStore';
import { Validator, ValidationResult } from '../../utils/Validator';
import { Result } from '../../utils/Result';
import { I18n } from '../../utils/I18n';
import { Toast } from '../../utils/Dialogs';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { PrimaryButton } from '../../components/PrimaryButton';

const AVATARS: string[] = ['🦎', '🐱', '🐶', '🐰', '🦊', '🐼', '🐯', '😀'];

/**
 * 编辑资料：昵称、头像（emoji）与可选的修改密码。
 */
@Entry
@Component
struct ProfilePage {
  @State nickname: string = '';
  @State avatar: string = '😀';
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;
  private userId: string = '';

  aboutToAppear(): void {
    this.userId = SessionStore.currentUserId();
    this.loadUser();
  }

  private async loadUser(): Promise<void> {
    const user: User | null = await UserRepository.getCurrent();
    if (user !== null) {
      this.nickname = user.nickname;
      this.avatar = user.avatar.length > 0 ? user.avatar : '😀';
    }
  }

  private localize(key: string): string {
    return I18n.t(getContext(this), key);
  }

  private async handleSave(): Promise<void> {
    const nameCheck: ValidationResult = Validator.requiredText(this.nickname, 20);
    if (!nameCheck.valid) {
      this.errorMsg = this.localize(nameCheck.messageKey);
      return;
    }
    const wantPwd: boolean = this.newPwd.length > 0;
    if (wantPwd) {
      const pc: ValidationResult = Validator.password(this.newPwd);
      if (!pc.valid) {
        this.errorMsg = this.localize(pc.messageKey);
        return;
      }
    }
    this.errorMsg = '';
    this.loading = true;

    if (wantPwd) {
      const cp: Result<string> = await AuthService.changePassword(this.userId, this.oldPwd, this.newPwd);
      if (!cp.success) {
        this.errorMsg = this.localize(cp.error);
        this.loading = false;
        return;
      }
    }
    const up: Result<string> = await AuthService.updateProfile(this.userId, this.nickname, this.avatar);
    this.loading = false;
    if (up.success) {
      Toast.saved();
      router.back();
    } else {
      this.errorMsg = this.localize(up.error);
    }
  }

  @Builder
  avatarPicker() {
    Row({ space: 10 }) {
      ForEach(AVATARS, (emoji: string) => {
        Stack() {
          Text(emoji).fontSize(26)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.avatar === emoji ? $r('app.color.urgency_upcoming_bg') : $r('app.color.input_background'))
        .borderWidth(this.avatar === emoji ? 2 : 0)
        .borderColor($r('app.color.brand_primary'))
        .onClick(() => {
          this.avatar = emoji;
        })
      }, (emoji: string) => emoji)
    }
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.profile_edit') })

      Scroll() {
        Column({ space: 16 }) {
          Text($r('app.string.profile_avatar'))
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Scroll() {
            this.avatarPicker()
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          FormField({
            label: $r('app.string.register_nickname'),
            placeholder: $r('app.string.register_nickname'),
            text: this.nickname,
            onChange: (v: string): void => {
              this.nickname = v;
            }
          })

          Column({ space: 12 }) {
            Text($r('app.string.change_password'))
              .fontSize($r('app.float.font_body'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            Text($r('app.string.pwd_optional_hint'))
              .fontSize($r('app.float.font_small'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
            FormField({
              label: $r('app.string.old_password'),
              placeholder: $r('app.string.old_password'),
              text: this.oldPwd,
              isPassword: true,
              onChange: (v: string): void => {
                this.oldPwd = v;
              }
            })
            FormField({
              label: $r('app.string.new_password'),
              placeholder: $r('app.string.new_password'),
              text: this.newPwd,
              isPassword: true,
              onChange: (v: string): void => {
                this.newPwd = v;
              }
            })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))

          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize($r('app.float.font_small'))
              .fontColor($r('app.color.urgency_overdue'))
              .width('100%')
          }

          PrimaryButton({
            label: $r('app.string.common_save'),
            loading: this.loading,
            onTap: (): void => {
              this.handleSave();
            }
          })
        }
        .width('100%')
        .padding($r('app.float.space_xl'))
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
