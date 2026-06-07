import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Pet } from '../../model/Pet';
import { ChecklistEntry } from '../../model/ChecklistEntry';
import { Urgency } from '../../model/Urgency';
import { PetService } from '../../service/PetService';
import { ReminderService } from '../../service/ReminderService';
import { DateUtil } from '../../utils/DateUtil';
import { I18n } from '../../utils/I18n';
import { Logger } from '../../utils/Logger';

class CalCell {
  day: number;
  date: string;
  hasEvent: boolean;
  isToday: boolean;
  isSelected: boolean;

  constructor(day: number, date: string, hasEvent: boolean, isToday: boolean, isSelected: boolean) {
    this.day = day;
    this.date = date;
    this.hasEvent = hasEvent;
    this.isToday = isToday;
    this.isSelected = isSelected;
  }
}

/**
 * 日历视图：月历网格（标注喂食/换料事件）+ 选中日待办 + 本地提醒。
 */
@Component
export struct CalendarTab {
  @Prop @Watch('reload') tick: number = 0;
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth() + 1;
  @State selectedDate: string = DateUtil.today();
  @State cells: CalCell[] = [];
  private eventDates: string[] = [];
  private allEntries: ChecklistEntry[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      const pets: Pet[] = await PetService.listPets();
      const dates: string[] = [];
      for (let i: number = 0; i < pets.length; i++) {
        if (pets[i].nextFeedDate.length > 0) {
          dates.push(pets[i].nextFeedDate);
        }
        if (pets[i].nextSubDate.length > 0) {
          dates.push(pets[i].nextSubDate);
        }
      }
      this.eventDates = dates;
      this.allEntries = await PetService.buildChecklist();
      this.rebuild();
    } catch (err) {
      Logger.error(`load calendar failed: ${JSON.stringify(err)}`);
    }
  }

  private rebuild(): void {
    const list: CalCell[] = [];
    const firstWeekday: number = new Date(this.year, this.month - 1, 1).getDay();
    const daysInMonth: number = new Date(this.year, this.month, 0).getDate();
    const today: string = DateUtil.today();
    for (let i: number = 0; i < firstWeekday; i++) {
      list.push(new CalCell(0, '', false, false, false));
    }
    for (let d: number = 1; d <= daysInMonth; d++) {
      const ds: string = DateUtil.format(new Date(this.year, this.month - 1, d));
      const hasEvent: boolean = this.eventDates.indexOf(ds) >= 0;
      list.push(new CalCell(d, ds, hasEvent, ds === today, ds === this.selectedDate));
    }
    this.cells = list;
  }

  private changeMonth(delta: number): void {
    let m: number = this.month + delta;
    let y: number = this.year;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    this.month = m;
    this.year = y;
    this.rebuild();
  }

  private selectedTasks(): ChecklistEntry[] {
    const result: ChecklistEntry[] = [];
    for (let i: number = 0; i < this.allEntries.length; i++) {
      if (this.allEntries[i].date === this.selectedDate) {
        result.push(this.allEntries[i]);
      }
    }
    return result;
  }

  private weekdayLabels(): string[] {
    return I18n.t(getContext(this), 'weekdays').split(',');
  }

  private async remindToday(): Promise<void> {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    let dueCount: number = 0;
    for (let i: number = 0; i < this.allEntries.length; i++) {
      const level: Urgency = this.allEntries[i].level;
      if (level === Urgency.TODAY || level === Urgency.OVERDUE) {
        dueCount += 1;
      }
    }
    if (dueCount === 0) {
      promptAction.showToast({ message: I18n.t(ctx, 'reminder_none') });
      return;
    }
    const title: string = I18n.t(ctx, 'reminder_title');
    const body: string = I18n.t(ctx, 'reminder_body_fmt').replace('%d', `${dueCount}`);
    const ok: boolean = await ReminderService.remind(ctx, title, body);
    promptAction.showToast({ message: ok ? I18n.t(ctx, 'reminder_sent') : I18n.t(ctx, 'reminder_failed') });
  }

  @Builder
  monthHeader() {
    Row() {
      Text('‹')
        .fontSize(26)
        .fontColor($r('app.color.text_primary'))
        .width(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.changeMonth(-1);
        })
      Text(`${this.year} / ${this.month}`)
        .fontSize($r('app.float.font_subtitle'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('›')
        .fontSize(26)
        .fontColor($r('app.color.text_primary'))
        .width(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.changeMonth(1);
        })
    }
    .width('100%')
  }

  @Builder
  weekRow() {
    Row() {
      ForEach(this.weekdayLabels(), (wd: string) => {
        Text(wd)
          .fontSize($r('app.float.font_small'))
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }, (wd: string, idx: number) => `${idx}`)
    }
    .width('100%')
    .margin({ top: $r('app.float.space_md') })
  }

  // 双色高亮：选中=深绿(brand_primary)，今天=浅绿(urgency_upcoming_bg)，其余透明
  private cellBg(cell: CalCell): ResourceColor {
    if (cell.isSelected) {
      return $r('app.color.brand_primary');
    }
    if (cell.isToday) {
      return $r('app.color.urgency_upcoming_bg');
    }
    return Color.Transparent;
  }

  private cellTextColor(cell: CalCell): ResourceColor {
    if (cell.isSelected) {
      return $r('app.color.text_on_brand');
    }
    if (cell.isToday) {
      return $r('app.color.brand_primary');
    }
    return $r('app.color.text_primary');
  }

  @Builder
  dayCell(cell: CalCell) {
    Column() {
      if (cell.day > 0) {
        Text(`${cell.day}`)
          .fontSize($r('app.float.font_caption'))
          .fontColor(this.cellTextColor(cell))
          .fontWeight(cell.isSelected || cell.isToday ? FontWeight.Bold : FontWeight.Normal)
        Circle({ width: 5, height: 5 })
          .fill(cell.hasEvent ? $r('app.color.urgency_today') : Color.Transparent)
          .margin({ top: 3 })
      }
    }
    .width(36)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .borderRadius(10)
    .backgroundColor(this.cellBg(cell))
    .onClick(() => {
      if (cell.day > 0) {
        this.selectedDate = cell.date;
        this.rebuild();
      }
    })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Column() {
            this.monthHeader()
            this.weekRow()
            Grid() {
              ForEach(this.cells, (cell: CalCell) => {
                GridItem() {
                  this.dayCell(cell)
                }
              }, (cell: CalCell, idx: number) => `${idx}-${cell.date}-${cell.isSelected}`)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .rowsGap(4)
            .width('100%')
            .height(280)
            .margin({ top: $r('app.float.space_sm') })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))

          Column({ space: 8 }) {
            Text(this.selectedDate)
              .fontSize($r('app.float.font_subtitle'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            ForEach(this.selectedTasks(), (entry: ChecklistEntry) => {
              Row() {
                Text(entry.kind === 'feed' ? '🍽️' : '🪵').fontSize(18)
                Text(entry.petName)
                  .fontSize($r('app.float.font_body'))
                  .fontColor($r('app.color.text_primary'))
                  .margin({ left: $r('app.float.space_md') })
                  .layoutWeight(1)
                Text(entry.kind === 'feed' ? $r('app.string.task_feed') : $r('app.string.task_substrate'))
                  .fontSize($r('app.float.font_small'))
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .padding($r('app.float.space_lg'))
              .backgroundColor($r('app.color.surface'))
              .borderRadius($r('app.float.radius_card'))
            }, (entry: ChecklistEntry) => `${entry.petId}-${entry.kind}`)
          }
          .width('100%')

          Button($r('app.string.calendar_reminder'))
            .type(ButtonType.Capsule)
            .width('100%')
            .height($r('app.float.control_height'))
            .fontColor($r('app.color.text_on_brand'))
            .backgroundColor($r('app.color.brand_primary'))
            .onClick(() => {
              this.remindToday();
            })
        }
        .width('100%')
        .padding($r('app.float.space_xl'))
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
