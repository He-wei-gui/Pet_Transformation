import { router } from '@kit.ArkUI';
import { ChecklistEntry } from '../../model/ChecklistEntry';
import { PetService } from '../../service/PetService';
import { SessionStore } from '../../service/SessionStore';
import { RouteConstants, StorageKeys } from '../../constants/RouteConstants';
import { ChecklistItem } from '../../components/ChecklistItem';
import { EmptyState } from '../../components/EmptyState';
import { Logger } from '../../utils/Logger';

/**
 * 首页：今日待办清单（聚合各宠物喂食/换料任务，按紧急度排序）。
 */
@Component
export struct HomeTab {
  @Prop @Watch('reload') tick: number = 0;
  @State entries: ChecklistEntry[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.entries = await PetService.buildChecklist();
    } catch (err) {
      Logger.error(`load checklist failed: ${JSON.stringify(err)}`);
    }
  }

  private greeting(): string {
    const nickname: string = SessionStore.currentNickname();
    try {
      return getContext(this).resourceManager.getStringByNameSync('greeting_fmt').replace('%s', nickname);
    } catch (err) {
      return nickname;
    }
  }

  build() {
    Column() {
      Column() {
        Text(this.greeting())
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
        Text($r('app.string.checklist_title'))
          .fontSize($r('app.float.font_display'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: $r('app.float.space_xs') })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({
        left: $r('app.float.space_xl'),
        right: $r('app.float.space_xl'),
        top: $r('app.float.space_xxl'),
        bottom: $r('app.float.space_lg')
      })

      if (this.entries.length === 0) {
        EmptyState({ emoji: '🌿', message: $r('app.string.checklist_empty') })
      } else {
        List({ space: 12 }) {
          ForEach(this.entries, (item: ChecklistEntry) => {
            ListItem() {
              ChecklistItem({
                entry: item,
                onTap: (): void => {
                  AppStorage.setOrCreate(StorageKeys.CURRENT_PET_ID, item.petId);
                  router.pushUrl({ url: RouteConstants.PET_DETAIL });
                }
              })
            }
          }, (item: ChecklistEntry) => `${item.petId}-${item.kind}-${item.date}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: $r('app.float.space_xl'), right: $r('app.float.space_xl') })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
