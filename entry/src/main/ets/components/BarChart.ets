/**
 * 柱状图。原生 Canvas 手绘，values 为各柱高度，labels 为底部标签（可选）。
 */
@Component
export struct BarChart {
  @Prop @Watch('redraw') values: number[] = [];
  @Prop labels: string[] = [];
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

    const padT: number = 12;
    const padB: number = 22;
    const padX: number = 8;
    const plotW: number = w - padX * 2;
    const plotH: number = h - padT - padB;

    let max: number = 1;
    for (let i: number = 0; i < n; i++) {
      if (this.values[i] > max) {
        max = this.values[i];
      }
    }

    const slot: number = plotW / n;
    const barW: number = slot * 0.55;
    this.ctx.fillStyle = '#3FA06A';
    this.ctx.font = '10vp sans-serif';

    for (let i: number = 0; i < n; i++) {
      const barH: number = plotH * (this.values[i] / max);
      const x: number = padX + slot * i + (slot - barW) / 2;
      const y: number = padT + plotH - barH;
      this.ctx.fillStyle = '#3FA06A';
      this.ctx.fillRect(x, y, barW, barH);

      this.ctx.fillStyle = 'rgba(127,127,127,0.9)';
      if (this.values[i] > 0) {
        this.ctx.fillText(`${this.values[i]}`, x + barW / 2 - 3, y - 3);
      }
      if (i < this.labels.length) {
        this.ctx.fillText(this.labels[i], x + barW / 2 - 6, padT + plotH + 14);
      }
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(180)
      .onReady(() => {
        this.ready = true;
        this.draw();
      })
  }
}
