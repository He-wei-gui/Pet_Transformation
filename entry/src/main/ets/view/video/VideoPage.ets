import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { image } from '@kit.ImageKit';
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
 * 成长视频页（本地）：选视频 → 复制进沙箱 → 抽取第一帧做封面 → 本地 SQLite 记录。
 * 列表展示第一帧封面 + 播放按钮，手动点才就地小窗播放（AVPlayer + XComponent，
 * videoScaleType=FIT 按比例适配不拉伸，可暂停/继续）。视频不上云，仅本机可见。
 */
@Entry
@Component
struct VideoPage {
  @State videos: PetVideo[] = [];
  @State caption: string = '';
  @State loading: boolean = false;
  @State errorMsg: string = '';
  @State activeId: number = -1; // 正在播放的视频 id（-1 表示无）
  @State paused: boolean = false;
  private playingUri: string = '';
  private avPlayer: media.AVPlayer | null = null;
  private surfaceId: string = '';
  private playFd: number = -1;
  private xcc: XComponentController = new XComponentController();
  private userId: string = '';
  private petId: string = '';

  aboutToAppear(): void {
    this.userId = SessionStore.currentUserId();
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    this.reload();
  }

  aboutToDisappear(): void {
    this.releasePlayer();
  }

  private thumbPath(uri: string): string {
    return `${uri}.jpg`;
  }

  private async reload(): Promise<void> {
    try {
      this.videos = await VideoRepository.listByUser(this.userId);
    } catch (err) {
      Logger.error(`load videos failed: ${JSON.stringify(err)}`);
    }
  }

  // 从沙箱视频抽取第一帧，存成 <video>.jpg 作为封面（best-effort，失败不影响导入）
  private async generateThumb(videoPath: string): Promise<void> {
    let gen: media.AVImageGenerator | null = null;
    let srcFile: fs.File | null = null;
    let outFile: fs.File | null = null;
    try {
      srcFile = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      gen = await media.createAVImageGenerator();
      gen.fdSrc = { fd: srcFile.fd };
      const pixel: image.PixelMap = await gen.fetchFrameByTime(0,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, { width: -1, height: -1 });
      const packer: image.ImagePacker = image.createImagePacker();
      const buf: ArrayBuffer = await packer.packing(pixel, { format: 'image/jpeg', quality: 80 });
      outFile = fs.openSync(this.thumbPath(videoPath), fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(outFile.fd, buf);
      await packer.release();
      await pixel.release();
    } catch (err) {
      Logger.error(`gen thumb failed: ${JSON.stringify(err)}`);
    } finally {
      if (outFile !== null) {
        try {
          fs.closeSync(outFile);
        } catch (e) {
        }
      }
      if (gen !== null) {
        try {
          await gen.release();
        } catch (e) {
        }
      }
      if (srcFile !== null) {
        try {
          fs.closeSync(srcFile);
        } catch (e) {
        }
      }
    }
  }

  private async pickAndAdd(): Promise<void> {
    this.errorMsg = '';
    let srcUri: string = '';
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      srcUri = result.photoUris[0];
    } catch (err) {
      Logger.error(`pick video failed: ${JSON.stringify(err)}`);
      this.errorMsg = `选择视频失败：${(err as Error).message}`;
      return;
    }

    this.loading = true;
    const ctx: common.Context = getContext(this) as common.Context;
    const dir: string = `${ctx.filesDir}/videos`;
    const dest: string = `${dir}/v_${Date.now()}.mp4`;
    let srcFile: fs.File | null = null;
    try {
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir);
      }
      srcFile = fs.openSync(srcUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(srcFile.fd, dest);
      fs.closeSync(srcFile);
      srcFile = null;

      await this.generateThumb(dest);
      await VideoRepository.create(new PetVideo(0, this.userId, this.petId, dest,
        this.caption.trim(), DateUtil.today()));
      this.caption = '';
      await this.reload();
      Toast.added();
    } catch (err) {
      Logger.error(`add video failed: ${JSON.stringify(err)}`);
      this.errorMsg = `保存视频失败：${(err as Error).message}`;
      try {
        if (fs.accessSync(dest)) {
          fs.unlinkSync(dest);
        }
      } catch (e) {
      }
    } finally {
      if (srcFile !== null) {
        try {
          fs.closeSync(srcFile);
        } catch (e) {
        }
      }
      this.loading = false;
    }
  }

  private async remove(video: PetVideo): Promise<void> {
    if (this.activeId === video.id) {
      await this.stopPlay();
    }
    for (const p of [video.uri, this.thumbPath(video.uri)]) {
      try {
        if (fs.accessSync(p)) {
          fs.unlinkSync(p);
        }
      } catch (err) {
        Logger.error(`unlink failed: ${JSON.stringify(err)}`);
      }
    }
    try {
      await VideoRepository.remove(video.id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove video failed: ${JSON.stringify(err)}`);
    }
  }

  // 点封面：开始就地小窗播放（卡片内 XComponent 挂载后在 onLoad 起播）
  private async startInline(video: PetVideo): Promise<void> {
    if (this.activeId === video.id) {
      return;
    }
    await this.releasePlayer();
    this.playingUri = video.uri;
    this.paused = false;
    this.activeId = video.id;
  }

  // 点播放中的画面：暂停 / 继续
  private togglePause(): void {
    const player: media.AVPlayer | null = this.avPlayer;
    if (player === null) {
      return;
    }
    if (this.paused) {
      player.play();
      this.paused = false;
    } else {
      player.pause();
      this.paused = true;
    }
  }

  private async stopPlay(): Promise<void> {
    await this.releasePlayer();
    this.paused = false;
    this.activeId = -1;
  }

  private async releasePlayer(): Promise<void> {
    const player: media.AVPlayer | null = this.avPlayer;
    this.avPlayer = null;
    if (player !== null) {
      try {
        await player.reset();
        await player.release();
      } catch (e) {
        Logger.error(`release avplayer failed: ${JSON.stringify(e)}`);
      }
    }
    if (this.playFd >= 0) {
      try {
        fs.closeSync(this.playFd);
      } catch (e) {
      }
      this.playFd = -1;
    }
  }

  private async startPlay(): Promise<void> {
    try {
      const file: fs.File = fs.openSync(this.playingUri, fs.OpenMode.READ_ONLY);
      this.playFd = file.fd;
      const player: media.AVPlayer = await media.createAVPlayer();
      this.avPlayer = player;
      player.on('stateChange', (state: string) => {
        if (state === 'initialized') {
          player.surfaceId = this.surfaceId;
          player.prepare();
        } else if (state === 'prepared') {
          player.videoScaleType = media.VideoScaleType.VIDEO_SCALE_TYPE_FIT; // 按比例适配，不拉伸
          player.loop = false;
          player.play();
        } else if (state === 'completed') {
          this.paused = true; // 播完停在末帧，显示重播按钮
        }
      });
      player.on('error', (err: object) => {
        Logger.error(`avplayer error: ${JSON.stringify(err)}`);
        this.errorMsg = `播放失败：${JSON.stringify(err)}`;
      });
      player.url = `fd://${file.fd}`;
    } catch (err) {
      Logger.error(`start play failed: ${JSON.stringify(err)}`);
      this.errorMsg = `播放失败：${(err as Error).message}`;
    }
  }

  @Builder
  videoCard(video: PetVideo) {
    Column({ space: 8 }) {
      if (this.activeId === video.id) {
        // 小窗播放：黑底 + 按比例适配画面；点画面暂停/继续
        Stack({ alignContent: Alignment.Center }) {
          XComponent({ id: 'petVideoSurface', type: XComponentType.SURFACE, controller: this.xcc })
            .onLoad(() => {
              this.surfaceId = this.xcc.getXComponentSurfaceId();
              this.startPlay();
            })
            .width('100%')
            .height(200)
          if (this.paused) {
            Text('▶')
              .fontSize(48)
              .fontColor(Color.White)
              .opacity(0.9)
          }
        }
        .width('100%')
        .height(200)
        .backgroundColor(Color.Black)
        .borderRadius($r('app.float.radius_button'))
        .onClick(() => {
          this.togglePause();
        })
      } else {
        // 封面：第一帧缩略图（若有）+ 播放按钮
        Stack({ alignContent: Alignment.Center }) {
          if (fs.accessSync(this.thumbPath(video.uri))) {
            Image(this.thumbPath(video.uri))
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)
              .borderRadius($r('app.float.radius_button'))
          } else {
            Column()
              .width('100%')
              .height(180)
              .borderRadius($r('app.float.radius_button'))
              .backgroundColor($r('app.color.input_background'))
          }
          Text('▶')
            .fontSize(46)
            .fontColor(Color.White)
            .opacity(0.95)
        }
        .width('100%')
        .onClick(() => {
          this.startInline(video);
        })
      }

      Row() {
        Text(video.caption.length > 0 ? video.caption : video.createdAt)
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (this.activeId === video.id) {
          Text('⏹ 停止')
            .fontSize($r('app.float.font_caption'))
            .fontColor($r('app.color.brand_primary'))
            .margin({ right: $r('app.float.space_md') })
            .onClick(() => {
              this.stopPlay();
            })
        }
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
            if (this.errorMsg.length > 0) {
              Text(this.errorMsg)
                .fontSize($r('app.float.font_small'))
                .fontColor($r('app.color.urgency_overdue'))
                .width('100%')
            }
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
            }, (video: PetVideo) => `${video.id}-${this.activeId === video.id}`)
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
