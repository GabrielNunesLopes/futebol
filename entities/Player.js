import { CONFIG } from '../config/gameConfig.js';

export class Player {
  constructor({ x, color, controls, facing }) {
    this.spawnX = x;
    this.x = x;
    this.y = CONFIG.groundY - CONFIG.player.height;
    this.vx = 0;
    this.vy = 0;
    this.width = CONFIG.player.width;
    this.height = CONFIG.player.height;
    this.color = color;
    this.controls = controls;
    this.facing = facing;
    this.onGround = true;
    this.kickCooldown = 0;
    this.superCharge = 0;
  }

  reset() {
    this.x = this.spawnX;
    this.y = CONFIG.groundY - this.height;
    this.vx = this.vy = 0;
    this.facing = this.spawnX < CONFIG.width / 2 ? 1 : -1;
    this.superCharge = 0;
    this.kickCooldown = 0;
  }

  update(dt, input) {
    const p = CONFIG.player;
    const left = input.down(this.controls.left);
    const right = input.down(this.controls.right);
    if (left !== right) {
      this.vx += (right ? 1 : -1) * p.acceleration * dt;
      this.facing = right ? 1 : -1;
    } else {
      const dec = p.deceleration * dt;
      if (Math.abs(this.vx) <= dec) this.vx = 0;
      else this.vx -= Math.sign(this.vx) * dec;
    }
    this.vx = Math.max(-p.maxSpeed, Math.min(p.maxSpeed, this.vx));

    if (input.consume(this.controls.jump) && this.onGround) {
      this.vy = -p.jumpSpeed;
      this.onGround = false;
    }

    this.vy += p.gravity * dt;
    this.x += this.vx * dt;
    this.y += this.vy * dt;

    this.x = Math.max(CONFIG.wall, Math.min(CONFIG.width - CONFIG.wall - this.width, this.x));
    const floorY = CONFIG.groundY - this.height;
    if (this.y >= floorY) {
      this.y = floorY;
      this.vy = 0;
      this.onGround = true;
    }
    this.kickCooldown = Math.max(0, this.kickCooldown - dt);
  }

  center() { return { x: this.x + this.width / 2, y: this.y + this.height / 2 }; }

  draw(ctx) {
    ctx.save();
    ctx.globalAlpha = 0.22;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(this.x + this.width / 2, CONFIG.groundY + 8, this.width * .55, 11, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.fillStyle = this.color;
    ctx.fillRect(this.x, this.y + 26, this.width, this.height - 26);
    ctx.beginPath();
    ctx.arc(this.x + this.width / 2, this.y + 25, 27, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#fff';
    ctx.fillRect(this.x + (this.facing > 0 ? 42 : 13), this.y + 20, 8, 8);
    ctx.restore();
  }
}
