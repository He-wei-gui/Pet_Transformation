import { promptAction } from '@kit.ArkUI';

/**
 * 轻量交互反馈工具：Toast 提示与删除二次确认，统一文案与样式。
 */
export class Toast {
  static added(): void {
    promptAction.showToast({ message: $r('app.string.toast_added') });
  }

  static deleted(): void {
    promptAction.showToast({ message: $r('app.string.toast_deleted') });
  }

  static saved(): void {
    promptAction.showToast({ message: $r('app.string.toast_saved') });
  }

  static msg(message: ResourceStr): void {
    promptAction.showToast({ message: message });
  }
}

export class Confirm {
  /** 删除二次确认，确认后回调 onConfirm。 */
  static remove(onConfirm: () => void): void {
    AlertDialog.show({
      message: $r('app.string.confirm_delete_record'),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      primaryButton: {
        value: $r('app.string.common_delete'),
        fontColor: $r('app.color.urgency_overdue'),
        action: () => {
          onConfirm();
        }
      },
      secondaryButton: {
        value: $r('app.string.common_cancel'),
        action: () => {
        }
      }
    });
  }
}
