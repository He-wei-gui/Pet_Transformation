import { StatsService, StatsSummary } from '../../service/StatsService';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';
import { StatCard } from '../../components/StatCard';
import { BarChart } from '../../components/BarChart';
import { SectionHeader } from '../../components/SectionHeader';
import { EmptyState } from '../../components/EmptyState';

/**
 * 统计仪表盘：概览卡片 + 近 7 天喂食柱状图。
 */
@Component
export struct StatsTab {
  @Prop @Watch('reload') tick: number = 0;
  @State summary: StatsSummary = new StatsSummary(0, 0, 0, 0, [0, 0, 0, 0, 0, 0, 0]);
  @State feedLabels: string[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.summary = await StatsService.build();
      const labels: string[] = [];
      const today: string = DateUtil.today();
      for (let i: number = 6; i >= 0; i--) {
        const d: string = DateUtil.addDays(today, -i);
        const parts: string[] = d.split('-');
        labels.push(parts.length === 3 ? parts[2] : d);
      }
      this.feedLabels = labels;
    } catch (err) {
      Logger.error(`load stats failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      Text($r('app.string.stats_overview'))
        .fontSize($r('app.float.font_display'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({
          left: $r('app.float.space_xl'),
          right: $r('app.float.space_xl'),
          top: $r('app.float.space_xxl'),
          bottom: $r('app.float.space_lg')
        })

      if (this.summary.totalPets === 0) {
        EmptyState({ emoji: '📊', message: $r('app.string.pets_empty') })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Grid() {
              GridItem() {
                StatCard({ emoji: '🦎', value: `${this.summary.totalPets}`, label: $r('app.string.stats_total_pets') })
              }
              GridItem() {
                StatCard({ emoji: '🍽️', value: `${this.summary.totalFeed}`, label: $r('app.string.stats_total_feed') })
              }
              GridItem() {
                StatCard({ emoji: '⚖️', value: `${this.summary.totalWeight}`, label: $r('app.string.stats_total_weight') })
              }
              GridItem() {
                StatCard({ emoji: '⏰', value: `${this.summary.overdue}`, label: $r('app.string.stats_overdue') })
              }
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')
            .height(220)

            Column() {
              SectionHeader({ title: $r('app.string.stats_feed_7d') })
              BarChart({ values: this.summary.feed7d, labels: this.feedLabels })
                .margin({ top: $r('app.float.space_md') })
            }
            .width('100%')
            .padding($r('app.float.space_lg'))
            .backgroundColor($r('app.color.surface'))
            .borderRadius($r('app.float.radius_card'))
          }
          .width('100%')
          .padding({ left: $r('app.float.space_xl'), right: $r('app.float.space_xl'), bottom: $r('app.float.space_xxl') })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
