import { MoltLog } from '../../model/MoltLog';
import { MoltLogRepository } from '../../repository/MoltLogRepository';
import { StorageKeys } from '../../constants/RouteConstants';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { DateField } from '../../components/DateField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { EmptyState } from '../../components/EmptyState';
import { Toast, Confirm } from '../../utils/Dialogs';

const STATUS_START: string = 'start';
const STATUS_DONE: string = 'done';

/**
 * 蜕皮记录页：录入蜕皮事件（开始/完成）+ 时间线列表。
 */
@Entry
@Component
struct MoltLogPage {
  @State logs: MoltLog[] = [];
  @State date: string = DateUtil.today();
  @State status: string = STATUS_DONE;
  @State note: string = '';
  @State loading: boolean = false;
  private petId: string = '';

  aboutToAppear(): void {
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.logs = await MoltLogRepository.listByPet(this.petId);
    } catch (err) {
      Logger.error(`load molt logs failed: ${JSON.stringify(err)}`);
    }
  }

  private async handleAdd(): Promise<void> {
    this.loading = true;
    try {
      await MoltLogRepository.create(
        new MoltLog(0, this.petId, this.date, this.status, this.note.trim(), DateUtil.today()));
      this.note = '';
      await this.reload();
      Toast.added();
    } catch (err) {
      Logger.error(`add molt failed: ${JSON.stringify(err)}`);
    }
    this.loading = false;
  }

  private async remove(id: number): Promise<void> {
    try {
      await MoltLogRepository.remove(id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove molt failed: ${JSON.stringify(err)}`);
    }
  }

  private statusLabel(status: string): ResourceStr {
    return status === STATUS_START ? $r('app.string.molt_start') : $r('app.string.molt_done');
  }

  @Builder
  statusToggle() {
    Row({ space: 10 }) {
      Button($r('app.string.molt_start'))
        .layoutWeight(1)
        .height(40)
        .type(ButtonType.Capsule)
        .fontColor(this.status === STATUS_START ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
        .backgroundColor(this.status === STATUS_START ? $r('app.color.brand_primary') : $r('app.color.input_background'))
        .onClick(() => {
          this.status = STATUS_START;
        })
      Button($r('app.string.molt_done'))
        .layoutWeight(1)
        .height(40)
        .type(ButtonType.Capsule)
        .fontColor(this.status === STATUS_DONE ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
        .backgroundColor(this.status === STATUS_DONE ? $r('app.color.brand_primary') : $r('app.color.input_background'))
        .onClick(() => {
          this.status = STATUS_DONE;
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.record_molt') })

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
            Column() {
              Text($r('app.string.molt_status'))
                .fontSize($r('app.float.font_caption'))
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: $r('app.float.space_xs') })
              this.statusToggle()
            }
            .alignItems(HorizontalAlign.Start)
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
            EmptyState({ emoji: '🐍', message: $r('app.string.empty_default') })
          } else {
            Column({ space: 8 }) {
              ForEach(this.logs, (log: MoltLog) => {
                Row() {
                  Text(log.status === STATUS_START ? '🌀' : '✨').fontSize(20)
                  Column() {
                    Text(this.statusLabel(log.status))
                      .fontSize($r('app.float.font_body'))
                      .fontColor($r('app.color.text_primary'))
                    Text(log.date)
                      .fontSize($r('app.float.font_small'))
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: $r('app.float.space_md') })
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
              }, (log: MoltLog) => `${log.id}`)
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
