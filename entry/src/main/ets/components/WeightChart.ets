/**
 * 体重趋势折线图。原生 Canvas 手绘（无第三方库），支持空态。
 * values 为按时间升序排列的体重数组。
 */
@Component
export struct WeightChart {
  @Prop @Watch('redraw') values: number[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;

  private redraw(): void {
    if (this.ready) {
      this.draw();
    }
  }

  private draw(): void {
    const w: number = this.ctx.width;
    const h: number = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const n: number = this.values.length;
    if (n === 0) {
      return;
    }

    const padL: number = 40;
    const padR: number = 14;
    const padT: number = 14;
    const padB: number = 24;
    const plotW: number = w - padL - padR;
    const plotH: number = h - padT - padB;

    let min: number = this.values[0];
    let max: number = this.values[0];
    for (let i: number = 1; i < n; i++) {
      if (this.values[i] < min) {
        min = this.values[i];
      }
      if (this.values[i] > max) {
        max = this.values[i];
      }
    }
    if (max === min) {
      max = min + 1;
      min = min - 1;
    }
    const range: number = max - min;

    // 横向网格 + 纵轴刻度
    this.ctx.strokeStyle = 'rgba(127,127,127,0.22)';
    this.ctx.lineWidth = 1;
    this.ctx.fillStyle = 'rgba(127,127,127,0.9)';
    this.ctx.font = '10vp sans-serif';
    const rows: number = 4;
    for (let r: number = 0; r <= rows; r++) {
      const gy: number = padT + plotH * r / rows;
      this.ctx.beginPath();
      this.ctx.moveTo(padL, gy);
      this.ctx.lineTo(padL + plotW, gy);
      this.ctx.stroke();
      const labelVal: number = max - range * r / rows;
      this.ctx.fillText(`${Math.round(labelVal)}`, 4, gy + 3);
    }

    // 区域填充
    this.ctx.beginPath();
    for (let i: number = 0; i < n; i++) {
      const px: number = n === 1 ? padL + plotW / 2 : padL + plotW * i / (n - 1);
      const py: number = padT + plotH * (1 - (this.values[i] - min) / range);
      if (i === 0) {
        this.ctx.moveTo(px, py);
      } else {
        this.ctx.lineTo(px, py);
      }
    }
    const lastX: number = n === 1 ? padL + plotW / 2 : padL + plotW;
    this.ctx.lineTo(lastX, padT + plotH);
    this.ctx.lineTo(padL, padT + plotH);
    this.ctx.closePath();
    this.ctx.fillStyle = 'rgba(63,160,106,0.15)';
    this.ctx.fill();

    // 折线
    this.ctx.beginPath();
    this.ctx.strokeStyle = '#3FA06A';
    this.ctx.lineWidth = 2;
    for (let i: number = 0; i < n; i++) {
      const px: number = n === 1 ? padL + plotW / 2 : padL + plotW * i / (n - 1);
      const py: number = padT + plotH * (1 - (this.values[i] - min) / range);
      if (i === 0) {
        this.ctx.moveTo(px, py);
      } else {
        this.ctx.lineTo(px, py);
      }
    }
    this.ctx.stroke();

    // 数据点
    this.ctx.fillStyle = '#3FA06A';
    for (let i: number = 0; i < n; i++) {
      const px: number = n === 1 ? padL + plotW / 2 : padL + plotW * i / (n - 1);
      const py: number = padT + plotH * (1 - (this.values[i] - min) / range);
      this.ctx.beginPath();
      this.ctx.arc(px, py, 3, 0, 6.2832);
      this.ctx.fill();
    }
  }

  build() {
    Stack() {
      if (this.values.length === 0) {
        Text($r('app.string.chart_empty'))
          .fontSize($r('app.float.font_caption'))
          .fontColor($r('app.color.text_secondary'))
      }
      Canvas(this.ctx)
        .width('100%')
        .height(200)
        .onReady(() => {
          this.ready = true;
          this.draw();
        })
    }
    .width('100%')
    .height(200)
  }
}
