import { ChecklistEntry } from '../model/ChecklistEntry';
import { UrgencyInfo } from '../model/Urgency';
import { UrgencyText } from '../utils/UrgencyText';
import { PetAvatar } from './PetAvatar';
import { UrgencyTag } from './UrgencyTag';

/**
 * 今日待办条目：宠物头像 + 名称 + 任务类型(喂食/换料) + 紧急度标签。
 */
@Component
export struct ChecklistItem {
  @Prop entry: ChecklistEntry;
  onTap: () => void = () => {};

  private taskLabel(): ResourceStr {
    return this.entry.kind === 'feed' ? $r('app.string.task_feed') : $r('app.string.task_substrate');
  }

  build() {
    Row() {
      PetAvatar({ avatar: this.entry.petAvatar, diameter: 44 })

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

      UrgencyTag({
        level: this.entry.level,
        text: UrgencyText.label(getContext(this), new UrgencyInfo(this.entry.level, this.entry.days))
      })
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
    .onClick(() => {
      this.onTap();
    })
  }
}
