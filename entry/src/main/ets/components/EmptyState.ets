/**
 * 空状态占位：插画 emoji + 提示文案 + 可选操作按钮。
 */
@Component
export struct EmptyState {
  @Prop emoji: string = '🦎';
  @Prop message: string = '暂无数据';
  @Prop actionLabel: string = '';
  onAction: () => void = () => {};

  build() {
    Column() {
      Text(this.emoji)
        .fontSize(56)
        .margin({ bottom: $r('app.float.space_md') })
      Text(this.message)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))

      if (this.actionLabel.length > 0) {
        Button(this.actionLabel)
          .type(ButtonType.Capsule)
          .fontColor($r('app.color.text_on_brand'))
          .backgroundColor($r('app.color.brand_primary'))
          .height(40)
          .margin({ top: $r('app.float.space_lg') })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding({ top: 64, bottom: 64 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
