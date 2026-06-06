/**
 * 区块标题：左侧标题，右侧可选操作文本（如“查看全部 / 添加”）。
 */
@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop action: string = '';
  onAction: () => void = () => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      if (this.action.length > 0) {
        Text(this.action)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.brand_primary'))
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
