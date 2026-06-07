import { router } from '@kit.ArkUI';

/**
 * 通用顶部栏：返回按钮 + 居中标题 + 可选右侧操作。
 */
@Component
export struct TopBar {
  @Prop title: ResourceStr = '';
  @Prop actionText: ResourceStr = '';
  @Prop showAction: boolean = false;
  onAction: () => void = () => {};

  build() {
    Row() {
      Text('‹')
        .fontSize(30)
        .fontColor($r('app.color.text_primary'))
        .width(40)
        .textAlign(TextAlign.Start)
        .onClick(() => {
          router.back();
        })

      Text(this.title)
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      if (this.showAction) {
        Text(this.actionText)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand_primary'))
          .width(40)
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.onAction();
          })
      } else {
        Text('').width(40)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: $r('app.float.space_lg'), right: $r('app.float.space_lg') })
    .backgroundColor($r('app.color.surface'))
  }
}
