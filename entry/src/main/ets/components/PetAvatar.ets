/**
 * 宠物头像：若 avatar 是图片 URI 则显示图片，否则按 emoji/文字渲染在圆底上。
 */
@Component
export struct PetAvatar {
  @Prop avatar: string = '';
  @Prop diameter: number = 56;

  private isImage(): boolean {
    return this.avatar.startsWith('file:') || this.avatar.startsWith('/') ||
      this.avatar.startsWith('http') || this.avatar.startsWith('data:');
  }

  build() {
    if (this.isImage()) {
      Image(this.avatar)
        .width(this.diameter)
        .height(this.diameter)
        .borderRadius(this.diameter / 2)
        .objectFit(ImageFit.Cover)
    } else {
      Stack() {
        Text(this.avatar.length > 0 ? this.avatar : '🦎')
          .fontSize(this.diameter * 0.5)
      }
      .width(this.diameter)
      .height(this.diameter)
      .borderRadius(this.diameter / 2)
      .backgroundColor($r('app.color.surface_alt'))
    }
  }
}
