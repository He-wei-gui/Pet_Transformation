/**
 * 统计卡片：emoji + 数值 + 标签。
 */
@Component
export struct StatCard {
  @Prop emoji: string = '';
  @Prop value: string = '';
  @Prop label: ResourceStr = '';

  build() {
    Column() {
      Text(this.emoji).fontSize(24)
      Text(this.value)
        .fontSize($r('app.float.font_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand_primary'))
        .margin({ top: $r('app.float.space_xs') })
      Text(this.label)
        .fontSize($r('app.float.font_small'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 2 })
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
  }
}
