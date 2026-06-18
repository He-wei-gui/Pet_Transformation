import { router } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Pet } from '../../model/Pet';
import { PetService } from '../../service/PetService';
import { SessionStore } from '../../service/SessionStore';
import { ScheduleService } from '../../service/ScheduleService';
import { ApiClient, UploadResult } from '../../service/ApiClient';
import { StorageKeys } from '../../constants/RouteConstants';
import { Validator, ValidationResult } from '../../utils/Validator';
import { Result } from '../../utils/Result';
import { DateUtil } from '../../utils/DateUtil';
import { I18n } from '../../utils/I18n';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { PetAvatar } from '../../components/PetAvatar';

const AVATARS: string[] = ['🦎', '🐉', '🐍', '🐢', '🦖', '🐸', '🦂', '🐊'];

/**
 * 新增/编辑宠物表单。CURRENT_PET_ID 为 0 表示新增，否则编辑。
 */
@Entry
@Component
struct PetEditPage {
  @State petId: string = '';
  @State name: string = '';
  @State species: string = '';
  @State avatar: string = '🦎';
  @State birthDate: string = DateUtil.today();
  @State feedInterval: string = '3';
  @State subInterval: string = '30';
  @State note: string = '';
  @State errorMsg: string = '';
  @State loading: boolean = false;
  @State avatarPickerOpen: boolean = false;
  @State avatarUploading: boolean = false;
  private origNextFeed: string = '';
  private origNextSub: string = '';
  private userId: string = '';

  aboutToAppear(): void {
    this.userId = SessionStore.currentUserId();
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    if (this.petId.length > 0) {
      this.loadPet();
    }
  }

  private async loadPet(): Promise<void> {
    const pet: Pet | null = await PetService.getPet(this.petId);
    if (pet === null) {
      return;
    }
    this.name = pet.name;
    this.species = pet.species;
    this.avatar = pet.avatar.length > 0 ? pet.avatar : '🦎';
    this.birthDate = pet.birthDate.length > 0 ? pet.birthDate : DateUtil.today();
    this.feedInterval = `${pet.feedInterval}`;
    this.subInterval = `${pet.subInterval}`;
    this.note = pet.note;
    this.origNextFeed = pet.nextFeedDate;
    this.origNextSub = pet.nextSubDate;
    this.userId = pet.userId;
  }

  private openDatePicker(): void {
    DatePickerDialog.show({
      start: new Date(2010, 0, 1),
      end: new Date(),
      selected: DateUtil.parse(this.birthDate),
      onDateAccept: (value: Date) => {
        this.birthDate = DateUtil.format(value);
      }
    });
  }

  private async handleSave(): Promise<void> {
    const nameCheck: ValidationResult = Validator.requiredText(this.name, 20);
    if (!nameCheck.valid) {
      this.errorMsg = I18n.t(getContext(this), nameCheck.messageKey);
      return;
    }
    const feedCheck: ValidationResult = Validator.intervalDays(this.feedInterval);
    if (!feedCheck.valid) {
      this.errorMsg = I18n.t(getContext(this), feedCheck.messageKey);
      return;
    }
    const subCheck: ValidationResult = Validator.intervalDays(this.subInterval);
    if (!subCheck.valid) {
      this.errorMsg = I18n.t(getContext(this), subCheck.messageKey);
      return;
    }
    this.errorMsg = '';
    this.loading = true;

    const fi: number = Number.parseInt(this.feedInterval, 10);
    const si: number = Number.parseInt(this.subInterval, 10);
    const today: string = DateUtil.today();
    const nextFeed: string = this.petId.length > 0 ? this.origNextFeed : ScheduleService.nextFeedDate(today, fi);
    const nextSub: string = this.petId.length > 0 ? this.origNextSub : ScheduleService.nextSubstrateDate(today, si);
    const pet: Pet = new Pet(this.petId, this.userId, this.name.trim(), this.species.trim(),
      this.avatar, this.birthDate, fi, si, nextFeed, nextSub, this.note.trim());

    try {
      await PetService.savePet(pet);
      router.back();
    } catch (err) {
      Logger.error(`save pet failed: ${JSON.stringify(err)}`);
      this.loading = false;
    }
  }

  // 从系统图库选图并上传，成功后把头像设为云端图片 URL
  private async pickAvatarImage(): Promise<void> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      this.avatarUploading = true;
      const up: Result<UploadResult> = await ApiClient.uploadImage(result.photoUris[0]);
      if (!up.success) {
        this.errorMsg = I18n.t(getContext(this), up.error);
        return;
      }
      this.avatar = (up.data as UploadResult).url;
    } catch (err) {
      Logger.error(`pick avatar failed: ${JSON.stringify(err)}`);
      this.errorMsg = I18n.t(getContext(this), (err as Error).message);
    } finally {
      this.avatarUploading = false;
    }
  }

  // 点击大头像后展开的选择面板：上传照片 + emoji 图标
  @Builder
  avatarPicker() {
    Column({ space: 12 }) {
      PrimaryButton({
        label: $r('app.string.avatar_upload'),
        loading: this.avatarUploading,
        onTap: (): void => {
          this.pickAvatarImage();
        }
      })
      Text($r('app.string.avatar_pick_emoji'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Scroll() {
        Row({ space: 10 }) {
          ForEach(AVATARS, (emoji: string) => {
            Stack() {
              Text(emoji).fontSize(26)
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor(this.avatar === emoji ? $r('app.color.urgency_upcoming_bg') : $r('app.color.input_background'))
            .borderWidth(this.avatar === emoji ? 2 : 0)
            .borderColor($r('app.color.brand_primary'))
            .onClick(() => {
              this.avatar = emoji;
            })
          }, (emoji: string) => emoji)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.space_lg'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
  }

  // 当前头像 + 相机角标，点击展开/收起选择面板
  @Builder
  avatarHeader() {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        PetAvatar({ avatar: this.avatar, diameter: 88 })
        Text('📷')
          .fontSize(14)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor($r('app.color.brand_primary'))
      }
      .onClick(() => {
        this.avatarPickerOpen = !this.avatarPickerOpen;
      })
      Text($r('app.string.avatar_tap_hint'))
        .fontSize($r('app.float.font_caption'))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }

  build() {
    Column() {
      TopBar({ title: this.petId.length > 0 ? $r('app.string.pet_edit') : $r('app.string.pet_add') })

      Scroll() {
        Column({ space: 16 }) {
          this.avatarHeader()
          if (this.avatarPickerOpen) {
            this.avatarPicker()
          }

          FormField({
            label: $r('app.string.pet_name'),
            placeholder: $r('app.string.pet_name'),
            text: this.name,
            onChange: (v: string): void => {
              this.name = v;
            }
          })

          FormField({
            label: $r('app.string.pet_species'),
            placeholder: $r('app.string.pet_species'),
            text: this.species,
            onChange: (v: string): void => {
              this.species = v;
            }
          })

          Column() {
            Text($r('app.string.pet_birthdate'))
              .fontSize($r('app.float.font_caption'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ bottom: $r('app.float.space_xs') })
            Row() {
              Text(this.birthDate)
                .fontSize($r('app.float.font_body'))
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Text('📅').fontSize(18)
            }
            .width('100%')
            .height($r('app.float.control_height'))
            .padding({ left: $r('app.float.space_lg'), right: $r('app.float.space_lg') })
            .backgroundColor($r('app.color.input_background'))
            .borderRadius($r('app.float.radius_button'))
            .onClick(() => {
              this.openDatePicker();
            })
          }
          .alignItems(HorizontalAlign.Start)

          FormField({
            label: $r('app.string.pet_feed_interval'),
            placeholder: '3',
            text: this.feedInterval,
            inputType: InputType.Number,
            onChange: (v: string): void => {
              this.feedInterval = v;
            }
          })

          FormField({
            label: $r('app.string.pet_sub_interval'),
            placeholder: '30',
            text: this.subInterval,
            inputType: InputType.Number,
            onChange: (v: string): void => {
              this.subInterval = v;
            }
          })

          FormField({
            label: $r('app.string.pet_note'),
            placeholder: $r('app.string.pet_note'),
            text: this.note,
            onChange: (v: string): void => {
              this.note = v;
            }
          })

          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize($r('app.float.font_small'))
              .fontColor($r('app.color.urgency_overdue'))
              .width('100%')
          }

          PrimaryButton({
            label: $r('app.string.common_save'),
            loading: this.loading,
            onTap: (): void => {
              this.handleSave();
            }
          })
            .margin({ top: $r('app.float.space_md') })
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
