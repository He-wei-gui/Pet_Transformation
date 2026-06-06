/**
 * 表单输入项：标签 + 输入框 + 错误提示。受控组件，值变更通过 onChange 回传父组件。
 */
@Component
export struct FormField {
  @Prop label: ResourceStr = '';
  @Prop placeholder: ResourceStr = '';
  @Prop text: string = '';
  @Prop error: string = '';
  @Prop isPassword: boolean = false;
  @Prop inputType: InputType = InputType.Normal;
  onChange: (value: string) => void = () => {};

  build() {
    Column() {
      Text(this.label)
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: $r('app.float.space_xs') })

      TextInput({ placeholder: this.placeholder, text: this.text })
        .type(this.isPassword ? InputType.Password : this.inputType)
        .height($r('app.float.control_height'))
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.input_background'))
        .borderRadius($r('app.float.radius_button'))
        .padding({ left: $r('app.float.space_lg'), right: $r('app.float.space_lg') })
        .onChange((value: string) => {
          this.onChange(value);
        })

      if (this.error.length > 0) {
        Text(this.error)
          .fontSize($r('app.float.font_small'))
          .fontColor($r('app.color.urgency_overdue'))
          .margin({ top: $r('app.float.space_xs') })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
