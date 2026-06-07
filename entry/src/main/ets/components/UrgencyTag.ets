import { Urgency } from '../model/Urgency';

/**
 * 紧急度标签：根据 today/overdue/upcoming 三态显示对应的橙/红/绿胶囊。
 */
@Component
export struct UrgencyTag {
  @Prop level: Urgency = Urgency.UPCOMING;
  @Prop text: string = '';

  private fgColor(): Resource {
    if (this.level === Urgency.TODAY) {
      return $r('app.color.urgency_today');
    }
    if (this.level === Urgency.OVERDUE) {
      return $r('app.color.urgency_overdue');
    }
    return $r('app.color.urgency_upcoming');
  }

  private bgColor(): Resource {
    if (this.level === Urgency.TODAY) {
      return $r('app.color.urgency_today_bg');
    }
    if (this.level === Urgency.OVERDUE) {
      return $r('app.color.urgency_overdue_bg');
    }
    return $r('app.color.urgency_upcoming_bg');
  }

  build() {
    Row() {
      Circle({ width: 6, height: 6 }).fill(this.fgColor())
      Text(this.text)
        .fontSize($r('app.float.font_small'))
        .fontColor(this.fgColor())
        .fontWeight(FontWeight.Medium)
        .margin({ left: 4 })
    }
    .padding({
      left: $r('app.float.space_sm'),
      right: $r('app.float.space_sm'),
      top: $r('app.float.space_xs'),
      bottom: $r('app.float.space_xs')
    })
    .backgroundColor(this.bgColor())
    .borderRadius($r('app.float.radius_pill'))
  }
}
