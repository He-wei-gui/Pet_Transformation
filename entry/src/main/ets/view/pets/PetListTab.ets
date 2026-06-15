import { router } from '@kit.ArkUI';
import { Pet } from '../../model/Pet';
import { PetService } from '../../service/PetService';
import { RouteConstants, StorageKeys } from '../../constants/RouteConstants';
import { PetCard } from '../../components/PetCard';
import { EmptyState } from '../../components/EmptyState';
import { Logger } from '../../utils/Logger';

/**
 * 宠物列表页：卡片列表 + 添加入口，点击进入详情。
 */
@Component
export struct PetListTab {
  @Prop @Watch('reload') tick: number = 0;
  @State pets: Pet[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.pets = await PetService.listPets();
    } catch (err) {
      Logger.error(`load pets failed: ${JSON.stringify(err)}`);
    }
  }

  private gotoEdit(petId: string): void {
    AppStorage.setOrCreate(StorageKeys.CURRENT_PET_ID, petId);
    router.pushUrl({ url: RouteConstants.PET_EDIT });
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.pets_title'))
          .fontSize($r('app.float.font_subtitle'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('＋')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.brand_primary'))
          .onClick(() => {
            this.gotoEdit('');
          })
      }
      .width('100%')
      .padding({
        left: $r('app.float.space_xl'),
        right: $r('app.float.space_xl'),
        top: $r('app.float.space_xxl'),
        bottom: $r('app.float.space_lg')
      })

      if (this.pets.length === 0) {
        EmptyState({
          emoji: '🦎',
          message: $r('app.string.pets_empty'),
          actionLabel: $r('app.string.pet_add'),
          showAction: true,
          onAction: (): void => {
            this.gotoEdit('');
          }
        })
      } else {
        List({ space: 12 }) {
          ForEach(this.pets, (pet: Pet) => {
            ListItem() {
              PetCard({
                pet: pet,
                onTap: (): void => {
                  AppStorage.setOrCreate(StorageKeys.CURRENT_PET_ID, pet.id);
                  router.pushUrl({ url: RouteConstants.PET_DETAIL });
                }
              })
            }
          }, (pet: Pet) => `${pet.id}-${pet.name}-${pet.species}-${pet.avatar}-${pet.nextFeedDate}-${pet.nextSubDate}`)
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
