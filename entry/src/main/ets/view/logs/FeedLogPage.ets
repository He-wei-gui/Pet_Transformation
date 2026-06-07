import { FeedLog } from '../../model/FeedLog';
import { PetService } from '../../service/PetService';
import { FeedLogRepository } from '../../repository/FeedLogRepository';
import { StorageKeys } from '../../constants/RouteConstants';
import { Validator, ValidationResult } from '../../utils/Validator';
import { DateUtil } from '../../utils/DateUtil';
import { I18n } from '../../utils/I18n';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { DateField } from '../../components/DateField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { EmptyState } from '../../components/EmptyState';

/**
 * 喂食记录页：录入喂食（同步重算下次喂食日）+ 历史列表（倒序）。
 */
@Entry
@Component
struct FeedLogPage {
  @State logs: FeedLog[] = [];
  @State date: string = DateUtil.today();
  @State foodType: string = '';
  @State amount: string = '';
  @State note: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;
  private petId: number = 0;

  aboutToAppear(): void {
    this.petId = AppStorage.get<number>(StorageKeys.CURRENT_PET_ID) ?? 0;
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.logs = await FeedLogRepository.listByPet(this.petId);
    } catch (err) {
      Logger.error(`load feed logs failed: ${JSON.stringify(err)}`);
    }
  }

  private async handleAdd(): Promise<void> {
    const check: ValidationResult = Validator.requiredText(this.foodType, 30);
    if (!check.valid) {
      this.errorMsg = I18n.t(getContext(this), check.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    try {
      await PetService.logFeed(this.petId, this.date, this.foodType.trim(), this.amount.trim(), this.note.trim());
      this.foodType = '';
      this.amount = '';
      this.note = '';
      await this.reload();
    } catch (err) {
      Logger.error(`add feed failed: ${JSON.stringify(err)}`);
    }
    this.loading = false;
  }

  private async remove(id: number): Promise<void> {
    try {
      await FeedLogRepository.remove(id);
      await this.reload();
    } catch (err) {
      Logger.error(`remove feed failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.feed_log_title') })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 12 }) {
            DateField({
              label: $r('app.string.date_label'),
              date: this.date,
              onPick: (d: string): void => {
                this.date = d;
              }
            })
            FormField({
              label: $r('app.string.food_type'),
              placeholder: $r('app.string.food_type'),
              text: this.foodType,
              onChange: (v: string): void => {
                this.foodType = v;
              }
            })
            FormField({
              label: $r('app.string.food_amount'),
              placeholder: $r('app.string.food_amount'),
              text: this.amount,
              onChange: (v: string): void => {
                this.amount = v;
              }
            })
            FormField({
              label: $r('app.string.pet_note'),
              placeholder: $r('app.string.pet_note'),
              text: this.note,
              onChange: (v: string): void => {
                this.note = v;
              }
            })
            if (this.errorMsg.length > 0) {
              Text(this.errorMsg)
                .fontSize($r('app.float.font_small'))
                .fontColor($r('app.color.urgency_overdue'))
                .width('100%')
            }
            PrimaryButton({
              label: $r('app.string.common_add'),
              loading: this.loading,
              onTap: (): void => {
                this.handleAdd();
              }
            })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))

          if (this.logs.length === 0) {
            EmptyState({ emoji: '🍽️', message: $r('app.string.empty_default') })
          } else {
            Column({ space: 8 }) {
              ForEach(this.logs, (log: FeedLog) => {
                Row() {
                  Column() {
                    Text(log.foodType)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                    Text(`${log.date}  ${log.amount}`)
                      .fontSize($r('app.float.font_small'))
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('🗑')
                    .fontSize(16)
                    .onClick(() => {
                      this.remove(log.id);
                    })
                }
                .width('100%')
                .padding($r('app.float.space_lg'))
                .backgroundColor($r('app.color.surface'))
                .borderRadius($r('app.float.radius_card'))
              }, (log: FeedLog) => `${log.id}`)
            }
            .width('100%')
          }
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
