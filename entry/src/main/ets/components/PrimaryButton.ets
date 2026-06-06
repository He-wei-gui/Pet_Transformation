/**
 * 主操作按钮：品牌绿填充、统一高度与圆角，支持禁用与加载态。
 */
@Component
export struct PrimaryButton {
  @Prop label: ResourceStr = '';
  @Prop isEnabled: boolean = true;
  @Prop loading: boolean = false;
  onTap: () => void = () => {};

  build() {
    Button() {
      if (this.loading) {
        LoadingProgress()
          .width(22)
          .height(22)
          .color($r('app.color.text_on_brand'))
      } else {
        Text(this.label)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_on_brand'))
          .fontWeight(FontWeight.Medium)
      }
    }
    .type(ButtonType.Capsule)
    .width('100%')
    .height($r('app.float.control_height'))
    .backgroundColor(this.isEnabled ? $r('app.color.brand_primary') : $r('app.color.divider'))
    .enabled(this.isEnabled && !this.loading)
    .onClick(() => {
      this.onTap();
    })
  }
}
