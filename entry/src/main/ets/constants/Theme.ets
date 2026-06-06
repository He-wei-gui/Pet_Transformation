/**
 * 设计令牌（Design Tokens）。颜色一律走资源 $r('app.color.*') 以支持浅/深主题，
 * 此处仅集中放置不便用资源表达的间距/圆角数值与统一字重，方便组件复用。
 */
export class Spacing {
  static readonly xs: number = 4;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly lg: number = 16;
  static readonly xl: number = 20;
  static readonly xxl: number = 24;
}

export class Radius {
  static readonly card: number = 16;
  static readonly button: number = 12;
  static readonly pill: number = 999;
}

export class FontSize {
  static readonly display: number = 28;
  static readonly title: number = 24;
  static readonly subtitle: number = 18;
  static readonly body: number = 16;
  static readonly caption: number = 14;
  static readonly small: number = 12;
}
