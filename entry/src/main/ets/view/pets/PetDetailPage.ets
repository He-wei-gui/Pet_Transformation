import { router } from '@kit.ArkUI';
import { Pet } from '../../model/Pet';
import { WeightLog } from '../../model/WeightLog';
import { UrgencyInfo } from '../../model/Urgency';
import { PetService } from '../../service/PetService';
import { WeightLogRepository } from '../../repository/WeightLogRepository';
import { RouteConstants, StorageKeys } from '../../constants/RouteConstants';
import { UrgencyText } from '../../utils/UrgencyText';
import { I18n } from '../../utils/I18n';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { PetAvatar } from '../../components/PetAvatar';
import { UrgencyTag } from '../../components/UrgencyTag';
import { WeightChart } from '../../components/WeightChart';
import { SectionHeader } from '../../components/SectionHeader';

class RecordCat {
  icon: string;
  label: ResourceStr;
  route: string;

  constructor(icon: string, label: ResourceStr, route: string) {
    this.icon = icon;
    this.label = label;
    this.route = route;
  }
}

/**
 * 宠物详情：资料 + 体重趋势曲线 + 记录分类入口 + 删除。
 */
@Entry
@Component
struct PetDetailPage {
  @State pet: Pet | null = null;
  @State weights: number[] = [];
  @State cats: RecordCat[] = [];
  private petId: number = 0;

  aboutToAppear(): void {
    this.petId = AppStorage.get<number>(StorageKeys.CURRENT_PET_ID) ?? 0;
    this.cats = [
      new RecordCat('⚖️', $r('app.string.record_weight'), RouteConstants.WEIGHT_LOG),
      new RecordCat('🍽️', $r('app.string.record_feed'), RouteConstants.FEED_LOG),
      new RecordCat('🪵', $r('app.string.record_substrate'), RouteConstants.SUBSTRATE_LOG),
      new RecordCat('🐍', $r('app.string.record_molt'), RouteConstants.MOLT_LOG),
      new RecordCat('🌡️', $r('app.string.record_env'), RouteConstants.ENV_LOG),
      new RecordCat('📷', $r('app.string.record_album'), RouteConstants.ALBUM)
    ];
  }

  onPageShow(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      this.pet = await PetService.getPet(this.petId);
      const logs: WeightLog[] = await WeightLogRepository.listByPet(this.petId);
      const values: number[] = [];
      for (let i: number = 0; i < logs.length; i++) {
        values.push(logs[i].weight);
      }
      this.weights = values;
    } catch (err) {
      Logger.error(`load detail failed: ${JSON.stringify(err)}`);
    }
  }

  private confirmDelete(): void {
    AlertDialog.show({
      message: $r('app.string.confirm_delete_pet'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: $r('app.string.common_delete'),
        fontColor: $r('app.color.urgency_overdue'),
        action: () => {
          this.doDelete();
        }
      },
      secondaryButton: {
        value: $r('app.string.common_cancel'),
        action: () => {
        }
      }
    });
  }

  private async doDelete(): Promise<void> {
    try {
      await PetService.deletePet(this.petId);
      router.back();
    } catch (err) {
      Logger.error(`delete pet failed: ${JSON.stringify(err)}`);
    }
  }

  @Builder
  petHeader(pet: Pet) {
    Column() {
      PetAvatar({ avatar: pet.avatar, diameter: 88 })
      Text(pet.name)
        .fontSize($r('app.float.font_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: $r('app.float.space_md') })
      Text(pet.species)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 2 })

      Row({ space: 8 }) {
        if (pet.nextFeedDate.length > 0) {
          UrgencyTag({
            level: UrgencyInfo.evaluate(pet.nextFeedDate).level,
            text: `${I18n.t(getContext(this), 'next_feed')} · ${UrgencyText.label(getContext(this), UrgencyInfo.evaluate(pet.nextFeedDate))}`
          })
        }
        if (pet.nextSubDate.length > 0) {
          UrgencyTag({
            level: UrgencyInfo.evaluate(pet.nextSubDate).level,
            text: `${I18n.t(getContext(this), 'next_substrate')} · ${UrgencyText.label(getContext(this), UrgencyInfo.evaluate(pet.nextSubDate))}`
          })
        }
      }
      .margin({ top: $r('app.float.space_md') })

      if (pet.note.length > 0) {
        Text(pet.note)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: $r('app.float.space_md') })
      }
    }
    .width('100%')
    .padding($r('app.float.space_xl'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
  }

  @Builder
  recordGrid() {
    Grid() {
      ForEach(this.cats, (cat: RecordCat) => {
        GridItem() {
          Column() {
            Text(cat.icon).fontSize(28)
            Text(cat.label)
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_primary'))
              .margin({ top: $r('app.float.space_xs') })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))
          .onClick(() => {
            router.pushUrl({ url: cat.route });
          })
        }
      }, (cat: RecordCat) => cat.route)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .width('100%')
    .height(180)
  }

  build() {
    Column() {
      TopBar({
        title: this.pet !== null ? this.pet.name : '',
        actionText: $r('app.string.common_edit_short'),
        showAction: true,
        onAction: (): void => {
          router.pushUrl({ url: RouteConstants.PET_EDIT });
        }
      })

      Scroll() {
        Column({ space: 16 }) {
          if (this.pet !== null) {
            this.petHeader(this.pet)
          }

          Column() {
            SectionHeader({ title: $r('app.string.detail_weight_trend') })
            WeightChart({ values: this.weights })
              .margin({ top: $r('app.float.space_md') })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))

          SectionHeader({ title: $r('app.string.detail_records') })
          this.recordGrid()

          Button($r('app.string.common_delete'))
            .type(ButtonType.Capsule)
            .width('100%')
            .height($r('app.float.control_height'))
            .fontColor($r('app.color.urgency_overdue'))
            .backgroundColor($r('app.color.surface'))
            .borderWidth(1)
            .borderColor($r('app.color.urgency_overdue'))
            .margin({ top: $r('app.float.space_md'), bottom: $r('app.float.space_xxl') })
            .onClick(() => {
              this.confirmDelete();
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
