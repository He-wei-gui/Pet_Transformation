import { Pet } from '../model/Pet';
import { UrgencyInfo } from '../model/Urgency';
import { UrgencyText } from '../utils/UrgencyText';
import { PetAvatar } from './PetAvatar';
import { UrgencyTag } from './UrgencyTag';

/**
 * 宠物卡片：头像 + 名称/物种 + 下次喂食紧急度标签。
 */
@Component
export struct PetCard {
  @Prop pet: Pet;
  onTap: () => void = () => {};

  build() {
    Row() {
      PetAvatar({ avatar: this.pet.avatar, diameter: 56 })

      Column() {
        Text(this.pet.name)
          .fontSize($r('app.float.font_subtitle'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.pet.species)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: $r('app.float.space_md') })

      if (this.pet.nextFeedDate.length > 0) {
        UrgencyTag({
          level: UrgencyInfo.evaluate(this.pet.nextFeedDate).level,
          text: UrgencyText.label(getContext(this), UrgencyInfo.evaluate(this.pet.nextFeedDate))
        })
      }
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
    .shadow({ radius: 8, color: $r('app.color.shadow'), offsetY: 2 })
    .onClick(() => {
      this.onTap();
    })
  }
}
