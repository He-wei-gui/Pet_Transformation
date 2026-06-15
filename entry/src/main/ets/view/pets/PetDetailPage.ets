import { router } from '@kit.ArkUI';
import { Pet } from '../../model/Pet';
import { WeightLog } from '../../model/WeightLog';
import { Photo } from '../../model/Photo';
import { UrgencyInfo } from '../../model/Urgency';
import { PetService } from '../../service/PetService';
import { WeightLogRepository } from '../../repository/WeightLogRepository';
import { PhotoRepository } from '../../repository/PhotoRepository';
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
 * 资料用基础类型 @State 承载，onPageShow 重新拉取，保证编辑返回后即时刷新。
 */
@Entry
@Component
struct PetDetailPage {
  @State loaded: boolean = false;
  @State petName: string = '';
  @State petSpecies: string = '';
  @State petAvatar: string = '';
  @State petNote: string = '';
  @State nextFeed: string = '';
  @State nextSub: string = '';
  @State weights: number[] = [];
  @State lengths: number[] = [];
  @State cats: RecordCat[] = [];
  private petId: string = '';

  aboutToAppear(): void {
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
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
      const pet: Pet | null = await PetService.getPet(this.petId);
      if (pet !== null) {
        this.petName = pet.name;
        this.petSpecies = pet.species;
        this.petAvatar = pet.avatar;
        this.petNote = pet.note;
        this.nextFeed = pet.nextFeedDate;
        this.nextSub = pet.nextSubDate;
        this.loaded = true;
      }
      const logs: WeightLog[] = await WeightLogRepository.listByPet(this.petId);
      const values: number[] = [];
      for (let i: number = 0; i < logs.length; i++) {
        values.push(logs[i].weight);
      }
      this.weights = values;

      // 相册按日期倒序，倒着遍历得到升序的体长序列（仅取有体长的记录）
      const photos: Photo[] = await PhotoRepository.listByPet(this.petId);
      const lens: number[] = [];
      for (let i: number = photos.length - 1; i >= 0; i--) {
        if (photos[i].lengthCm > 0) {
          lens.push(photos[i].lengthCm);
        }
      }
      this.lengths = lens;
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
  petHeader() {
    Column() {
      PetAvatar({ avatar: this.petAvatar, diameter: 88 })
      Text(this.petName)
        .fontSize($r('app.float.font_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: $r('app.float.space_md') })
      Text(this.petSpecies)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 2 })

      Row({ space: 8 }) {
        if (this.nextFeed.length > 0) {
          UrgencyTag({
            level: UrgencyInfo.evaluate(this.nextFeed).level,
            text: `${I18n.t(getContext(this), 'next_feed')} · ${UrgencyText.label(getContext(this), UrgencyInfo.evaluate(this.nextFeed))}`
          })
        }
        if (this.nextSub.length > 0) {
          UrgencyTag({
            level: UrgencyInfo.evaluate(this.nextSub).level,
            text: `${I18n.t(getContext(this), 'next_substrate')} · ${UrgencyText.label(getContext(this), UrgencyInfo.evaluate(this.nextSub))}`
          })
        }
      }
      .margin({ top: $r('app.float.space_md') })

      if (this.petNote.length > 0) {
        Text(this.petNote)
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
        title: this.petName,
        actionText: $r('app.string.common_edit_short'),
        showAction: true,
        onAction: (): void => {
          router.pushUrl({ url: RouteConstants.PET_EDIT });
        }
      })

      Scroll() {
        Column({ space: 16 }) {
          if (this.loaded) {
            this.petHeader()
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

          if (this.lengths.length > 0) {
            Column() {
              SectionHeader({ title: $r('app.string.detail_length_trend') })
              WeightChart({ values: this.lengths })
                .margin({ top: $r('app.float.space_md') })
            }
            .width('100%')
            .padding($r('app.float.space_lg'))
            .backgroundColor($r('app.color.surface'))
            .borderRadius($r('app.float.radius_card'))
          }

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
