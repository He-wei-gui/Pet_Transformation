import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { PetVideo } from '../../model/PetVideo';
import { VideoRepository } from '../../repository/VideoRepository';
import { SessionStore } from '../../service/SessionStore';
import { StorageKeys } from '../../constants/RouteConstants';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { EmptyState } from '../../components/EmptyState';
import { Toast, Confirm } from '../../utils/Dialogs';

/**
 * 成长视频页（本地）：从图库选视频 → 复制到应用沙箱 → 本地 SQLite 记录 → 内置 Video 组件播放。
 * 视频不上云（作业场景，轻量化），仅本机可见。
 */
@Entry
@Component
struct VideoPage {
  @State videos: PetVideo[] = [];
  @State caption: string = '';
  @State loading: boolean = false;
  private userId: string = '';
  private petId: string = '';

  aboutToAppear(): void {
    this.userId = SessionStore.currentUserId();
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.videos = await VideoRepository.listByUser(this.userId);
    } catch (err) {
      Logger.error(`load videos failed: ${JSON.stringify(err)}`);
    }
  }

  /** 选视频 → 复制到沙箱 filesDir/videos → 本地记录。 */
  private async pickAndAdd(): Promise<void> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      this.loading = true;
      const ctx: common.Context = getContext(this) as common.Context;
      const dir: string = `${ctx.filesDir}/videos`;
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir);
      }
      const dest: string = `${dir}/v_${Date.now()}.mp4`;
      fs.copyFileSync(result.photoUris[0], dest);

      await VideoRepository.create(new PetVideo(0, this.userId, this.petId, dest,
        this.caption.trim(), DateUtil.today()));
      this.caption = '';
      await this.reload();
      Toast.added();
    } catch (err) {
      Logger.error(`add video failed: ${JSON.stringify(err)}`);
    } finally {
      this.loading = false;
    }
  }

  /** 删除：移除沙箱文件 + 本地记录。 */
  private async remove(video: PetVideo): Promise<void> {
    try {
      if (fs.accessSync(video.uri)) {
        fs.unlinkSync(video.uri);
      }
    } catch (err) {
      Logger.error(`unlink video failed: ${JSON.stringify(err)}`);
    }
    try {
      await VideoRepository.remove(video.id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove video failed: ${JSON.stringify(err)}`);
    }
  }

  @Builder
  videoCard(video: PetVideo) {
    Column({ space: 8 }) {
      Video({ src: video.uri })
        .width('100%')
        .height(200)
        .controls(true)
        .objectFit(ImageFit.Contain)
        .borderRadius($r('app.float.radius_button'))
      Row() {
        Text(video.caption.length > 0 ? video.caption : video.createdAt)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('🗑')
          .fontSize(14)
          .onClick(() => {
            Confirm.remove(() => {
              this.remove(video);
            });
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.space_sm'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_card'))
  }

  build() {
    Column() {
      TopBar({ title: $r('app.string.video_title') })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 12 }) {
            FormField({
              label: $r('app.string.video_caption'),
              placeholder: $r('app.string.video_caption'),
              text: this.caption,
              onChange: (v: string): void => {
                this.caption = v;
              }
            })
            PrimaryButton({
              label: $r('app.string.video_add'),
              loading: this.loading,
              onTap: (): void => {
                this.pickAndAdd();
              }
            })
          }
          .width('100%')
          .padding($r('app.float.space_lg'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.radius_card'))

          if (this.videos.length === 0) {
            EmptyState({ emoji: '🎬', message: $r('app.string.video_empty') })
          } else {
            ForEach(this.videos, (video: PetVideo) => {
              this.videoCard(video)
            }, (video: PetVideo) => `${video.id}`)
          }
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
