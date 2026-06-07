import { router } from '@kit.ArkUI';
import { ChecklistEntry } from '../../model/ChecklistEntry';
import { Todo } from '../../model/Todo';
import { PetService } from '../../service/PetService';
import { SessionStore } from '../../service/SessionStore';
import { TodoRepository } from '../../repository/TodoRepository';
import { RouteConstants, StorageKeys } from '../../constants/RouteConstants';
import { ChecklistItem } from '../../components/ChecklistItem';
import { EmptyState } from '../../components/EmptyState';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';

/**
 * 首页：今日待办清单（自定义待办 + 各宠物喂食/换料自动任务，按紧急度排序）。
 */
@Component
export struct HomeTab {
  @Prop @Watch('reload') tick: number = 0;
  @State entries: ChecklistEntry[] = [];
  @State todos: Todo[] = [];
  @State adding: boolean = false;
  @State newTodo: string = '';

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.entries = await PetService.buildChecklist();
      this.todos = await TodoRepository.listActiveByUser(SessionStore.currentUserId());
    } catch (err) {
      Logger.error(`load home failed: ${JSON.stringify(err)}`);
    }
  }

  private async addTodo(): Promise<void> {
    const title: string = this.newTodo.trim();
    if (title.length === 0) {
      return;
    }
    try {
      const today: string = DateUtil.today();
      await TodoRepository.create(new Todo(0, SessionStore.currentUserId(), title, today, 0, today));
      this.newTodo = '';
      this.adding = false;
      await this.reload();
    } catch (err) {
      Logger.error(`add todo failed: ${JSON.stringify(err)}`);
    }
  }

  private async completeTodo(id: number): Promise<void> {
    try {
      await TodoRepository.remove(id);
      await this.reload();
    } catch (err) {
      Logger.error(`complete todo failed: ${JSON.stringify(err)}`);
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

  @Builder
  todoRow(todo: Todo) {
    Row() {
      Circle({ width: 22, height: 22 })
        .fill(Color.Transparent)
        .stroke($r('app.color.brand_primary'))
        .strokeWidth(2)
        .onClick(() => {
          this.completeTodo(todo.id);
        })
      Text(todo.title)
        .fontSize($r('app.float.font_body'))
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .margin({ left: $r('app.float.space_md') })
      Text('📝').fontSize(14)
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
  }

  build() {
    Column() {
      Column() {
        Text(this.greeting())
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Text($r('app.string.checklist_title'))
            .fontSize($r('app.float.font_display'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Text('＋')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.brand_primary'))
            .onClick(() => {
              this.adding = !this.adding;
            })
        }
        .width('100%')
        .margin({ top: $r('app.float.space_xs') })

        if (this.adding) {
          Row() {
            TextInput({ placeholder: $r('app.string.todo_hint'), text: this.newTodo })
              .layoutWeight(1)
              .height(44)
              .backgroundColor($r('app.color.input_background'))
              .borderRadius($r('app.float.radius_button'))
              .onChange((v: string): void => {
                this.newTodo = v;
              })
              .onSubmit(() => {
                this.addTodo();
              })
            Button($r('app.string.common_add'))
              .type(ButtonType.Capsule)
              .height(44)
              .fontColor($r('app.color.text_on_brand'))
              .backgroundColor($r('app.color.brand_primary'))
              .margin({ left: $r('app.float.space_md') })
              .onClick(() => {
                this.addTodo();
              })
          }
          .width('100%')
          .margin({ top: $r('app.float.space_md') })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({
        left: $r('app.float.space_xl'),
        right: $r('app.float.space_xl'),
        top: $r('app.float.space_xxl'),
        bottom: $r('app.float.space_lg')
      })

      if (this.todos.length === 0 && this.entries.length === 0) {
        EmptyState({ emoji: '🌿', message: $r('app.string.checklist_empty') })
      } else {
        List({ space: 12 }) {
          ForEach(this.todos, (todo: Todo) => {
            ListItem() {
              this.todoRow(todo)
            }
          }, (todo: Todo) => `todo-${todo.id}`)

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
