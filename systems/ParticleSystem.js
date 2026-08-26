export class ParticleSystem {
  constructor() { this.items = []; }
  burst(x, y, amount = 10) {
    for (let i = 0; i < amount; i++) {
      const a = Math.random() * Math.PI * 2;
      const s = 80 + Math.random() * 220;
      this.items.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: .45 + Math.random() * .25 });
    }
  }
  update(dt) {
    for (const p of this.items) { p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 360 * dt; p.life -= dt; }
    this.items = this.items.filter(p => p.life > 0);
  }
  draw(ctx) {
    ctx.save();
    for (const p of this.items) { ctx.globalAlpha = Math.min(1, p.life * 2); ctx.fillStyle = '#fff'; ctx.fillRect(p.x, p.y, 4, 4); }
    ctx.restore();
  }
}
