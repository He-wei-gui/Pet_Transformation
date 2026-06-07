import { TopBar } from '../../components/TopBar';
import { EmptyState } from '../../components/EmptyState';

/** 成长相册页（Phase 4 实现）。 */
@Entry
@Component
struct AlbumPage {
  build() {
    Column() {
      TopBar({ title: $r('app.string.record_album') })
      Column() {
        EmptyState({ emoji: '📷', message: $r('app.string.coming_soon') })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
