import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Photo } from '../../model/Photo';
import { PhotoRepository } from '../../repository/PhotoRepository';
import { StorageKeys } from '../../constants/RouteConstants';
import { DateUtil } from '../../utils/DateUtil';
import { Logger } from '../../utils/Logger';
import { TopBar } from '../../components/TopBar';
import { FormField } from '../../components/FormField';
import { DateField } from '../../components/DateField';
import { PrimaryButton } from '../../components/PrimaryButton';
import { EmptyState } from '../../components/EmptyState';
import { Toast, Confirm } from '../../utils/Dialogs';

/**
 * 成长相册页：系统图库选图 → 复制进应用沙箱 → 记录到相册表（含日期/体长/说明）。
 */
@Entry
@Component
struct AlbumPage {
  @State photos: Photo[] = [];
  @State date: string = DateUtil.today();
  @State lengthStr: string = '';
  @State caption: string = '';
  @State loading: boolean = false;
  private petId: number = 0;

  aboutToAppear(): void {
    this.petId = AppStorage.get<number>(StorageKeys.CURRENT_PET_ID) ?? 0;
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.photos = await PhotoRepository.listByPet(this.petId);
    } catch (err) {
      Logger.error(`load photos failed: ${JSON.stringify(err)}`);
    }
  }

  /** 将图库 uri 复制到应用沙箱，返回沙箱内绝对路径。 */
  private copyToSandbox(srcUri: string): string {
    const dir: string = getContext(this).filesDir;
    const dest: string = `${dir}/pet_${this.petId}_${Date.now()}.jpg`;
    const destFile: fs.File = fs.openSync(dest, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    const srcFile: fs.File = fs.openSync(srcUri, fs.OpenMode.READ_ONLY);
    fs.copyFileSync(srcFile.fd, destFile.fd);
    fs.closeSync(srcFile);
    fs.closeSync(destFile);
    return dest;
  }

  private async pickAndAdd(): Promise<void> {
    this.loading = true;
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      if (result.photoUris.length > 0) {
        const stored: string = this.copyToSandbox(result.photoUris[0]);
        const length: number = Number.parseFloat(this.lengthStr.trim());
        await PhotoRepository.create(new Photo(0, this.petId, this.date, stored,
          Number.isNaN(length) ? 0 : length, this.caption.trim(), DateUtil.today()));
        this.lengthStr = '';
        this.caption = '';
        await this.reload();
        Toast.added();
      }
    } catch (err) {
      Logger.error(`pick photo failed: ${JSON.stringify(err)}`);
    }
    this.loading = false;
  }

  private async remove(id: number): Promise<void> {
    try {
      await PhotoRepository.remove(id);
      await this.reload();
      Toast.deleted();
    } catch (err) {
      Logger.error(`remove photo failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
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
                    Image(photo.uri)
                      .width('100%')
                      .height(140)
                      .borderRadius($r('app.float.radius_button'))
                      .objectFit(ImageFit.Cover)
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
  }
}
