import { HomeTab } from '../view/home/HomeTab';
import { PetListTab } from '../view/pets/PetListTab';
import { CalendarTab } from '../view/calendar/CalendarTab';
import { StatsTab } from '../view/stats/StatsTab';
import { MineTab } from '../view/mine/MineTab';

/**
 * 主页：底部五个 Tab（首页·宠物·日历·统计·我的）。
 * tick 在每次页面重新展示时自增，驱动各 Tab 重新拉取数据。
 */
@Entry
@Component
struct MainPage {
  @State activeIndex: number = 0;
  @State tick: number = 0;

  onPageShow(): void {
    this.tick++;
  }

  @Builder
  bottomTab(index: number, icon: string, label: ResourceStr) {
    Column() {
      Text(icon)
        .fontSize(22)
        .opacity(this.activeIndex === index ? 1 : 0.55)
      Text(label)
        .fontSize(10)
        .margin({ top: 2 })
        .fontColor(this.activeIndex === index ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ index: this.activeIndex, barPosition: BarPosition.End }) {
      TabContent() {
        HomeTab({ tick: this.tick })
      }.tabBar(this.bottomTab(0, '🏠', $r('app.string.tab_home')))

      TabContent() {
        PetListTab({ tick: this.tick })
      }.tabBar(this.bottomTab(1, '🦎', $r('app.string.tab_pets')))

      TabContent() {
        CalendarTab({ tick: this.tick })
      }.tabBar(this.bottomTab(2, '📅', $r('app.string.tab_calendar')))

      TabContent() {
        StatsTab({ tick: this.tick })
      }.tabBar(this.bottomTab(3, '📊', $r('app.string.tab_stats')))

      TabContent() {
        MineTab({ tick: this.tick })
      }.tabBar(this.bottomTab(4, '👤', $r('app.string.tab_mine')))
    }
    .barMode(BarMode.Fixed)
    .barBackgroundColor($r('app.color.surface'))
    .scrollable(false)
    .onChange((index: number) => {
      this.activeIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
