import { router } from '@kit.ArkUI';
import { ChecklistEntry } from '../../model/ChecklistEntry';
import { Todo } from '../../model/Todo';
import { PetService } from '../../service/PetService';
import { SessionStore } from '../../service/SessionStore';
import { TodoRepository } from '../../repository/TodoRepository';
import { RouteConstants, StorageKeys } from '../../constants/RouteConstants';
import { ChecklistItem } from '../../components/ChecklistItem';
import { DateField } from '../../components/DateField';
import { EmptyState } from '../../components/EmptyState';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';

/**
 * 首页：今日待办。自定义待办（可选日期、完成打勾保留）+ 宠物喂食/换料自动任务
 * （左侧完成圆点，完成后整体变淡并打勾，会话内保持）。
 */
@Component
export struct HomeTab {
  @Prop @Watch('reload') tick: number = 0;
  @State entries: ChecklistEntry[] = [];
  @State todos: Todo[] = [];
  @State completedKeys: string[] = [];
  @State adding: boolean = false;
  @State newTodo: string = '';
  @State newTodoDate: string = DateUtil.today();

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.entries = await PetService.buildChecklist();
      this.todos = await TodoRepository.listByUser(SessionStore.currentUserId());
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
      await TodoRepository.create(
        new Todo(0, SessionStore.currentUserId(), title, this.newTodoDate, 0, DateUtil.today()));
      this.newTodo = '';
      this.newTodoDate = DateUtil.today();
      this.adding = false;
      await this.reload();
    } catch (err) {
      Logger.error(`add todo failed: ${JSON.stringify(err)}`);
    }
  }

  private async toggleTodo(todo: Todo): Promise<void> {
    try {
      await TodoRepository.setDone(todo.id, todo.done === 1 ? 0 : 1);
      await this.reload();
    } catch (err) {
      Logger.error(`toggle todo failed: ${JSON.stringify(err)}`);
    }
  }

  private async deleteTodo(id: number): Promise<void> {
    try {
      await TodoRepository.remove(id);
      await this.reload();
    } catch (err) {
      Logger.error(`delete todo failed: ${JSON.stringify(err)}`);
    }
  }

  private petKey(entry: ChecklistEntry): string {
    return `${entry.petId}-${entry.kind}`;
  }

  private togglePet(entry: ChecklistEntry): void {
    const key: string = this.petKey(entry);
    const next: string[] = [];
    let removed: boolean = false;
    for (let i: number = 0; i < this.completedKeys.length; i++) {
      if (this.completedKeys[i] === key) {
        removed = true;
      } else {
        next.push(this.completedKeys[i]);
      }
    }
    if (!removed) {
      next.push(key);
    }
    this.completedKeys = next;
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
      Stack() {
        Circle({ width: 24, height: 24 })
          .fill(todo.done === 1 ? $r('app.color.brand_primary') : Color.Transparent)
          .stroke($r('app.color.brand_primary'))
          .strokeWidth(2)
        if (todo.done === 1) {
          Text('✓').fontSize(14).fontColor($r('app.color.text_on_brand'))
        }
      }
      .onClick(() => {
        this.toggleTodo(todo);
      })

      Column() {
        Text(todo.title)
          .fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.text_primary'))
          .decoration({ type: todo.done === 1 ? TextDecorationType.LineThrough : TextDecorationType.None })
        Text(todo.date)
          .fontSize($r('app.float.font_small'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: $r('app.float.space_md') })

      Text('🗑')
        .fontSize(14)
        .onClick(() => {
          this.deleteTodo(todo.id);
        })
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
    .opacity(todo.done === 1 ? 0.5 : 1)
  }

  @Builder
  addCard() {
    Column({ space: 12 }) {
      TextInput({ placeholder: $r('app.string.todo_hint'), text: this.newTodo })
        .height(44)
        .backgroundColor($r('app.color.input_background'))
        .borderRadius($r('app.float.radius_button'))
        .onChange((v: string): void => {
          this.newTodo = v;
        })
      DateField({
        label: $r('app.string.date_label'),
        date: this.newTodoDate,
        onPick: (d: string): void => {
          this.newTodoDate = d;
        }
      })
      Button($r('app.string.common_add'))
        .type(ButtonType.Capsule)
        .width('100%')
        .height(44)
        .fontColor($r('app.color.text_on_brand'))
        .backgroundColor($r('app.color.brand_primary'))
        .onClick(() => {
          this.addTodo();
        })
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .margin({ top: $r('app.float.space_md') })
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
          this.addCard()
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
          }, (todo: Todo) => `todo-${todo.id}-${todo.done}`)

          ForEach(this.entries, (item: ChecklistEntry) => {
            ListItem() {
              ChecklistItem({
                entry: item,
                done: this.completedKeys.includes(this.petKey(item)),
                onToggle: (): void => {
                  this.togglePet(item);
                },
                onTap: (): void => {
                  AppStorage.setOrCreate(StorageKeys.CURRENT_PET_ID, item.petId);
                  router.pushUrl({ url: RouteConstants.PET_DETAIL });
                }
              })
            }
          }, (item: ChecklistEntry) => `${item.petId}-${item.kind}-${item.date}-${this.completedKeys.includes(this.petKey(item))}`)
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
