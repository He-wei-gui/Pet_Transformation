/**
 * 主页 Tabs 容器（Phase 0 占位，Phase 3 接入五个 Tab 与 Navigation）。
 */
@Entry
@Component
struct MainPage {
  build() {
    Column() {
      Text($r('app.string.app_name'))
        .fontSize($r('app.float.font_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand_primary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
