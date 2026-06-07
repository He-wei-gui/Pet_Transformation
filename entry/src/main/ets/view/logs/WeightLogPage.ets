import { WeightLog } from '../../model/WeightLog';
import { PetService } from '../../service/PetService';
import { WeightLogRepository } from '../../repository/WeightLogRepository';
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
 * 体重记录页：录入称重 + 历史列表（升序）。
 */
@Entry
@Component
struct WeightLogPage {
  @State logs: WeightLog[] = [];
  @State date: string = DateUtil.today();
  @State weightStr: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;
  private petId: number = 0;

  aboutToAppear(): void {
    this.petId = AppStorage.get<number>(StorageKeys.CURRENT_PET_ID) ?? 0;
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.logs = await WeightLogRepository.listByPet(this.petId);
    } catch (err) {
      Logger.error(`load weight logs failed: ${JSON.stringify(err)}`);
    }
  }

  private async handleAdd(): Promise<void> {
    const check: ValidationResult = Validator.positiveNumber(this.weightStr);
    if (!check.valid) {
      this.errorMsg = I18n.t(getContext(this), check.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    try {
      await PetService.logWeight(this.petId, this.date, Number.parseFloat(this.weightStr));
      this.weightStr = '';
      await this.reload();
    } catch (err) {
      Logger.error(`add weight failed: ${JSON.stringify(err)}`);
    }
    this.loading = false;
  }

  private async remove(id: number): Promise<void> {
    try {
      await WeightLogRepository.remove(id);
      await this.reload();
    } catch (err) {
      Logger.error(`remove weight failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.weight_log_title') })

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
              label: $r('app.string.weight_value'),
              placeholder: '0',
              text: this.weightStr,
              inputType: InputType.NUMBER_DECIMAL,
              onChange: (v: string): void => {
                this.weightStr = v;
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
            EmptyState({ emoji: '⚖️', message: $r('app.string.empty_default') })
          } else {
            Column({ space: 8 }) {
              ForEach(this.logs, (log: WeightLog) => {
                Row() {
                  Text(log.date)
                    .fontSize($r('app.float.font_body'))
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(`${log.weight} g`)
                    .fontSize($r('app.float.font_body'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.brand_primary'))
                  Text('🗑')
                    .fontSize(16)
                    .margin({ left: $r('app.float.space_lg') })
                    .onClick(() => {
                      this.remove(log.id);
                    })
                }
                .width('100%')
                .padding($r('app.float.space_lg'))
                .backgroundColor($r('app.color.surface'))
                .borderRadius($r('app.float.radius_card'))
              }, (log: WeightLog) => `${log.id}`)
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
