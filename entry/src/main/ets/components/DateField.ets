import { DateUtil } from '../utils/DateUtil';

/**
 * 日期选择项：点击弹出系统日期选择器，选定后通过 onPick 回传 'YYYY-MM-DD'。
 */
@Component
export struct DateField {
  @Prop label: ResourceStr = '';
  @Prop date: string = '';
  onPick: (date: string) => void = () => {};

  private openPicker(): void {
    DatePickerDialog.show({
      start: new Date(2010, 0, 1),
      end: new Date(),
      selected: DateUtil.parse(this.date),
      onDateAccept: (value: Date) => {
        this.onPick(DateUtil.format(value));
      }
    });
  }

  build() {
    Column() {
      Text(this.label)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.space_xs') })
      Row() {
        Text(this.date)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('📅').fontSize(18)
      }
      .width('100%')
      .height($r('app.float.control_height'))
      .padding({ left: $r('app.float.space_lg'), right: $r('app.float.space_lg') })
      .backgroundColor($r('app.color.input_background'))
      .borderRadius($r('app.float.radius_button'))
      .onClick(() => {
        this.openPicker();
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
