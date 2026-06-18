import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { curves } from '@kit.ArkUI';
import { Photo } from '../../model/Photo';
import { PhotoRepository } from '../../repository/PhotoRepository';
import { ApiClient, UploadResult } from '../../service/ApiClient';
import { Result } from '../../utils/Result';
import { StorageKeys } from '../../constants/RouteConstants';
import { DateUtil } from '../../utils/DateUtil';
import { I18n } from '../../utils/I18n';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { DateField } from '../../components/DateField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { EmptyState } from '../../components/EmptyState';
import { Toast, Confirm } from '../../utils/Dialogs';

/**
 * 成长相册页：系统图库选图 → 上传云端 → 记录到云端相册（含日期/体长/说明），多端可见。
 */
@Entry
@Component
struct AlbumPage {
  @State photos: Photo[] = [];
  @State date: string = DateUtil.today();
  @State lengthStr: string = '';
  @State caption: string = '';
  @State loading: boolean = false;
  @State errorMsg: string = '';
  private petId: string = '';

  // ===== 高清缩放查看器状态（生化危机式自由查看：双指缩放 + 拖动 + 双击复位） =====
  @State viewerVisible: boolean = false;
  @State viewerSrc: string = '';
  @State scaleVal: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  // 手势基线：每次手势开始时累加，避免跳变
  private baseScale: number = 1;
  private baseOffsetX: number = 0;
  private baseOffsetY: number = 0;

  private static readonly SCALE_MIN: number = 0.5;
  private static readonly SCALE_MAX: number = 6;

  private openViewer(src: string): void {
    this.scaleVal = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.baseScale = 1;
    this.baseOffsetX = 0;
    this.baseOffsetY = 0;
    this.viewerSrc = src;
    this.viewerVisible = true;
  }

  private closeViewer(): void {
    this.viewerVisible = false;
  }

  private clampScale(v: number): number {
    if (v < AlbumPage.SCALE_MIN) {
      return AlbumPage.SCALE_MIN;
    }
    if (v > AlbumPage.SCALE_MAX) {
      return AlbumPage.SCALE_MAX;
    }
    return v;
  }

  // 双击：在原始大小与 2.5 倍之间切换，带平滑曲线
  private toggleZoom(): void {
    const target: number = this.scaleVal > 1.05 ? 1 : 2.5;
    animateTo({ duration: 280, curve: curves.cubicBezierCurve(0.25, 0.1, 0.25, 1) }, () => {
      this.scaleVal = target;
      if (target === 1) {
        this.offsetX = 0;
        this.offsetY = 0;
      }
    });
    this.baseScale = target;
    this.baseOffsetX = this.offsetX;
    this.baseOffsetY = this.offsetY;
  }

  aboutToAppear(): void {
    this.petId = AppStorage.get<string>(StorageKeys.CURRENT_PET_ID) ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.photos = await PhotoRepository.listByPet(this.petId);
    } catch (err) {
      Logger.error(`load photos failed: ${JSON.stringify(err)}`);
    }
  }

  private async pickAndAdd(): Promise<void> {
    this.errorMsg = '';
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      // 选图后再进入上传态，避免用户取消选择时仍转圈
      this.loading = true;
      const up: Result<UploadResult> = await ApiClient.uploadImage(result.photoUris[0]);
      if (!up.success) {
        this.errorMsg = I18n.t(getContext(this), up.error);
        return;
      }
      const uploaded: UploadResult = up.data as UploadResult;
      const length: number = Number.parseFloat(this.lengthStr.trim());
      await PhotoRepository.create(new Photo('', this.petId, this.date, uploaded.url,
        uploaded.thumb ?? uploaded.url, Number.isNaN(length) ? 0 : length,
        this.caption.trim(), DateUtil.today()));
      this.lengthStr = '';
      this.caption = '';
      await this.reload();
      Toast.added();
    } catch (err) {
      Logger.error(`pick photo failed: ${JSON.stringify(err)}`);
      this.errorMsg = I18n.t(getContext(this), (err as Error).message);
    } finally {
      this.loading = false;
    }
  }

  private async remove(id: string): Promise<void> {
    try {
      await PhotoRepository.remove(id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove photo failed: ${JSON.stringify(err)}`);
      this.errorMsg = I18n.t(getContext(this), (err as Error).message);
    }
  }

  @Builder
  viewerOverlay() {
    Stack() {
      // 背景层：半透明黑底，点击空白处关闭
      Column()
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.closeViewer();
        })

      // 高清图：双指缩放 + 拖动；双击复位/放大
      Image(this.viewerSrc)
        .objectFit(ImageFit.Contain)
        .width('100%')
        .height('100%')
        .alt($r('app.media.startIcon'))
        .scale({ x: this.scaleVal, y: this.scaleVal })
        .translate({ x: this.offsetX, y: this.offsetY })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionUpdate((event: GestureEvent) => {
                this.scaleVal = this.clampScale(this.baseScale * event.scale);
              })
              .onActionEnd(() => {
                this.baseScale = this.scaleVal;
              }),
            PanGesture()
              .onActionUpdate((event: GestureEvent) => {
                this.offsetX = this.baseOffsetX + event.offsetX;
                this.offsetY = this.baseOffsetY + event.offsetY;
              })
              .onActionEnd(() => {
                this.baseOffsetX = this.offsetX;
                this.baseOffsetY = this.offsetY;
              }),
            TapGesture({ count: 2 })
              .onAction(() => {
                this.toggleZoom();
              })
          )
        )

      // 关闭按钮（固定右上角）
      Text('✕')
        .fontSize(22)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.15)')
        .position({ x: '85%', y: '5%' })
        .onClick(() => {
          this.closeViewer();
        })

      // 操作提示（固定底部）
      Text($r('app.string.album_viewer_hint'))
        .fontSize($r('app.float.font_small'))
        .fontColor('rgba(255,255,255,0.6)')
        .width('100%')
        .textAlign(TextAlign.Center)
        .position({ x: 0, y: '92%' })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .transition(TransitionEffect.OPACITY.animation({ duration: 220, curve: curves.cubicBezierCurve(0.25, 0.1, 0.25, 1) }))
  }

  build() {
    Stack() {
    Column() {
      TopBar({ title: $r('app.string.record_album') })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 12 }) {
            DateField({
              label: $r('app.string.date_label'),
              date: this.date,
              onPick: (d: string): void => {
                this.date = d;
              }
            })
            FormField({
              label: $r('app.string.photo_length'),
              placeholder: '0',
              text: this.lengthStr,
              inputType: InputType.NUMBER_DECIMAL,
              onChange: (v: string): void => {
                this.lengthStr = v;
              }
            })
            FormField({
              label: $r('app.string.photo_caption'),
              placeholder: $r('app.string.photo_caption'),
              text: this.caption,
              onChange: (v: string): void => {
                this.caption = v;
              }
            })
            PrimaryButton({
              label: $r('app.string.album_add'),
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

          if (this.photos.length === 0) {
            EmptyState({ emoji: '📷', message: $r('app.string.album_empty') })
          } else {
            Grid() {
              ForEach(this.photos, (photo: Photo) => {
                GridItem() {
                  Column() {
                    Image(photo.thumbUri)
                      .width('100%')
                      .height(140)
                      .borderRadius($r('app.float.radius_button'))
                      .objectFit(ImageFit.Cover)
                      .alt($r('app.media.startIcon'))
                      .onClick(() => {
                        // 点击查看高清原图（非缩略图）
                        this.openViewer(photo.uri);
                      })
                    Row() {
                      Column() {
                        if (photo.caption.length > 0) {
                          Text(photo.caption)
                            .fontSize($r('app.float.font_caption'))
                            .fontColor($r('app.color.text_primary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        Text(photo.lengthCm > 0 ? `${photo.date}  ${photo.lengthCm}cm` : photo.date)
                          .fontSize($r('app.float.font_small'))
                          .fontColor($r('app.color.text_secondary'))
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      Text('🗑')
                        .fontSize(14)
                        .onClick(() => {
                          Confirm.remove(() => {
                            this.remove(photo.id);
                          });
                        })
                    }
                    .width('100%')
                    .margin({ top: $r('app.float.space_xs') })
                  }
                  .padding($r('app.float.space_sm'))
                  .backgroundColor($r('app.color.surface'))
                  .borderRadius($r('app.float.radius_card'))
                }
              }, (photo: Photo) => `${photo.id}`)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')
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

      if (this.viewerVisible) {
        this.viewerOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
