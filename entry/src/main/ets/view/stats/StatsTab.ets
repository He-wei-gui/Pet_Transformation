import { EmptyState } from '../../components/EmptyState';

/**
 * 统计仪表盘（Phase 4 接入体重/喂食/环境多维图表）。
 */
@Component
export struct StatsTab {
  @Prop tick: number = 0;

  build() {
    Column() {
      EmptyState({ emoji: '📊', message: $r('app.string.coming_soon') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
