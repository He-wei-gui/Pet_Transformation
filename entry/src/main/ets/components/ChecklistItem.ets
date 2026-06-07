import { ChecklistEntry } from '../model/ChecklistEntry';
import { UrgencyInfo } from '../model/Urgency';
import { UrgencyText } from '../utils/UrgencyText';
import { PetAvatar } from './PetAvatar';
import { UrgencyTag } from './UrgencyTag';

/**
 * 今日待办条目：左侧完成圆点 + 宠物头像 + 名称 + 任务类型(喂食/换料) + 紧急度标签。
 * 完成后整体变淡、标题加删除线、圆点变实心打勾。
 */
@Component
export struct ChecklistItem {
  @Prop entry: ChecklistEntry;
  @Prop done: boolean = false;
  onToggle: () => void = () => {};
  onTap: () => void = () => {};

  private taskLabel(): ResourceStr {
    return this.entry.kind === 'feed' ? $r('app.string.task_feed') : $r('app.string.task_substrate');
  }

  @Builder
  checkCircle() {
    Stack() {
      Circle({ width: 24, height: 24 })
        .fill(this.done ? $r('app.color.brand_primary') : Color.Transparent)
        .stroke($r('app.color.brand_primary'))
        .strokeWidth(2)
      if (this.done) {
        Text('✓')
          .fontSize(14)
          .fontColor($r('app.color.text_on_brand'))
      }
    }
    .onClick(() => {
      this.onToggle();
    })
  }

  build() {
    Row() {
      this.checkCircle()
      PetAvatar({ avatar: this.entry.petAvatar, diameter: 44 })
        .margin({ left: $r('app.float.space_md') })

      Column() {
        Text(this.entry.petName)
          .fontSize($r('app.float.font_body'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Row() {
          Text(this.taskLabel())
            .fontSize($r('app.float.font_small'))
            .fontColor($r('app.color.text_secondary'))
          Text(this.entry.date)
            .fontSize($r('app.float.font_small'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: $r('app.float.space_sm') })
        }
        .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: $r('app.float.space_md') })
      .onClick(() => {
        this.onTap();
      })

      if (this.done) {
        Row() {
          Text('✓')
            .fontSize($r('app.float.font_small'))
            .fontColor($r('app.color.urgency_upcoming'))
          Text($r('app.string.task_done'))
            .fontSize($r('app.float.font_small'))
            .fontColor($r('app.color.urgency_upcoming'))
            .margin({ left: 2 })
        }
      } else {
        UrgencyTag({
          level: this.entry.level,
          text: UrgencyText.label(getContext(this), new UrgencyInfo(this.entry.level, this.entry.days))
        })
      }
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
    .opacity(this.done ? 0.5 : 1)
  }
}
