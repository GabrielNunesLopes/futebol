import { CONFIG } from '../config/gameConfig.js';

export class Ball {
  constructor() { this.radius = CONFIG.ball.radius; this.reset(); }
  reset() {
    this.x = CONFIG.width / 2;
    this.y = CONFIG.groundY - 160;
    this.vx = 0;
    this.vy = 0;
    this.rotation = 0;
    this.superTrail = 0;
  }
  update(dt) {
    const b = CONFIG.ball;
    this.vy += b.gravity * dt;
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.rotation += this.vx * dt / this.radius;
    this.vx *= Math.pow(b.airDrag, dt * 60);
    const speed = Math.hypot(this.vx, this.vy);
    if (speed > b.maxSpeed) {
      const k = b.maxSpeed / speed;
      this.vx *= k; this.vy *= k;
    }
    if (this.y + this.radius > CONFIG.groundY) {
      this.y = CONFIG.groundY - this.radius;
      if (this.vy > 70) this.vy *= -b.bounce; else this.vy = 0;
      this.vx *= Math.pow(b.groundFriction, dt * 60);
    }
    if (this.y - this.radius < 45) { this.y = 45 + this.radius; this.vy = Math.abs(this.vy) * .7; }
    this.superTrail = Math.max(0, this.superTrail - dt);
  }
  draw(ctx) {
    if (this.superTrail > 0) {
      ctx.save(); ctx.globalAlpha = .24; ctx.fillStyle = '#fff08a';
      for (let i = 1; i <= 5; i++) { ctx.beginPath(); ctx.arc(this.x - Math.sign(this.vx || 1) * i * 22, this.y, Math.max(4, this.radius - i * 4), 0, Math.PI * 2); ctx.fill(); }
      ctx.restore();
    }
    ctx.save(); ctx.translate(this.x, this.y); ctx.rotate(this.rotation);
    ctx.fillStyle = '#fff'; ctx.strokeStyle = '#111'; ctx.lineWidth = 4;
    ctx.beginPath(); ctx.arc(0, 0, this.radius, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    ctx.fillStyle = '#111'; ctx.beginPath(); ctx.arc(0, 0, 8, 0, Math.PI * 2); ctx.fill(); ctx.restore();
  }
}
