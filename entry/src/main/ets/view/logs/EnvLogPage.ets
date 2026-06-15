import { EnvLog } from '../../model/EnvLog';
import { EnvLogRepository } from '../../repository/EnvLogRepository';
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
import { WeightChart } from '../../components/WeightChart';
import { SectionHeader } from '../../components/SectionHeader';
import { Toast, Confirm } from '../../utils/Dialogs';

/**
 * 环境记录页：录入温度/湿度/UVB + 温度趋势曲线 + 历史列表。
 */
@Entry
@Component
struct EnvLogPage {
  @State logs: EnvLog[] = [];
  @State temps: number[] = [];
  @State date: string = DateUtil.today();
  @State tempStr: string = '';
  @State humidityStr: string = '';
  @State uvbStr: string = '';
  @State note: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;
  private petId: string = '';

  aboutToAppear(): void {
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.logs = await EnvLogRepository.listByPet(this.petId);
      const values: number[] = [];
      for (let i: number = 0; i < this.logs.length; i++) {
        values.push(this.logs[i].temperature);
      }
      this.temps = values;
    } catch (err) {
      Logger.error(`load env logs failed: ${JSON.stringify(err)}`);
    }
  }

  private toNumber(value: string): number {
    const n: number = Number.parseFloat(value.trim());
    return Number.isNaN(n) ? 0 : n;
  }

  private async handleAdd(): Promise<void> {
    const check: ValidationResult = Validator.positiveNumber(this.tempStr);
    if (!check.valid) {
      this.errorMsg = I18n.t(getContext(this), check.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;
    try {
      await EnvLogRepository.create(new EnvLog(0, this.petId, this.date,
        this.toNumber(this.tempStr), this.toNumber(this.humidityStr), this.toNumber(this.uvbStr),
        this.note.trim(), DateUtil.today()));
      this.tempStr = '';
      this.humidityStr = '';
      this.uvbStr = '';
      this.note = '';
      await this.reload();
      Toast.added();
    } catch (err) {
      Logger.error(`add env failed: ${JSON.stringify(err)}`);
    }
    this.loading = false;
  }

  private async remove(id: number): Promise<void> {
    try {
      await EnvLogRepository.remove(id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove env failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.record_env') })

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
              label: $r('app.string.env_temp'),
              placeholder: '0',
              text: this.tempStr,
              inputType: InputType.NUMBER_DECIMAL,
              onChange: (v: string): void => {
                this.tempStr = v;
              }
            })
            FormField({
              label: $r('app.string.env_humidity'),
              placeholder: '0',
              text: this.humidityStr,
              inputType: InputType.NUMBER_DECIMAL,
              onChange: (v: string): void => {
                this.humidityStr = v;
              }
            })
            FormField({
              label: $r('app.string.env_uvb'),
              placeholder: '0',
              text: this.uvbStr,
              inputType: InputType.NUMBER_DECIMAL,
              onChange: (v: string): void => {
                this.uvbStr = v;
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

          if (this.temps.length > 0) {
            Column() {
              SectionHeader({ title: $r('app.string.env_temp_trend') })
              WeightChart({ values: this.temps })
                .margin({ top: $r('app.float.space_md') })
            }
            .width('100%')
            .padding($r('app.float.space_lg'))
            .backgroundColor($r('app.color.surface'))
            .borderRadius($r('app.float.radius_card'))
          }

          if (this.logs.length === 0) {
            EmptyState({ emoji: '🌡️', message: $r('app.string.empty_default') })
          } else {
            Column({ space: 8 }) {
              ForEach(this.logs, (log: EnvLog) => {
                Row() {
                  Column() {
                    Text(`🌡️ ${log.temperature}℃   💧 ${log.humidity}%   ☀️ ${log.uvb}`)
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                    Text(log.date)
                      .fontSize($r('app.float.font_small'))
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('🗑')
                    .fontSize(16)
                    .onClick(() => {
                      Confirm.remove(() => {
                        this.remove(log.id);
                      });
                    })
                }
                .width('100%')
                .padding($r('app.float.space_lg'))
                .backgroundColor($r('app.color.surface'))
                .borderRadius($r('app.float.radius_card'))
              }, (log: EnvLog) => `${log.id}`)
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
