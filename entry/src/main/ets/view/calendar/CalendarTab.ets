import { EmptyState } from '../../components/EmptyState';

/**
 * 日历视图（Phase 4 接入月历网格 + 本地提醒）。
 */
@Component
export struct CalendarTab {
  @Prop tick: number = 0;

  build() {
    Column() {
      EmptyState({ emoji: '📅', message: $r('app.string.coming_soon') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
