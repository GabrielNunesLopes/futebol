import { CONFIG } from '../config/gameConfig.js';
import { InputManager } from './InputManager.js';
import { MatchManager } from './MatchManager.js';
import { Player } from '../entities/Player.js';
import { Ball } from '../entities/Ball.js';
import { resolvePlayerBall, resolvePlayers, possessionScore, kickBall } from './Physics.js';
import { UIManager } from '../ui/UIManager.js';

export class Game {
  constructor(canvas, hud, overlay) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.input = new InputManager();
    this.ui = new UIManager(hud, overlay);
    this.match = new MatchManager();
    this.players = [
      new Player({ x: 250, color: '#ff3b45', facing: 1, controls: { left:'KeyA', right:'KeyD', jump:'KeyW', kick:'KeyS' } }),
      new Player({ x: 966, color: '#3d7cff', facing: -1, controls: { left:'ArrowLeft', right:'ArrowRight', jump:'ArrowUp', kick:'ArrowDown' } }),
    ];
    this.ball = new Ball();
    this.running = false;
    this.phase = 'menu';
    this.phaseTimer = 0;
    this.shake = 0;
    this.last = performance.now();
    this.loop = this.loop.bind(this);
    this.resize = this.resize.bind(this);
    addEventListener('resize', this.resize);
    this.resize();
    this.ui.showMenu(() => this.startMatch());
    requestAnimationFrame(this.loop);
  }

  resize() {
    const scale = Math.min(innerWidth / CONFIG.width, innerHeight / CONFIG.height);
    this.canvas.style.width = `${CONFIG.width * scale}px`;
    this.canvas.style.height = `${CONFIG.height * scale}px`;
  }

  startMatch() {
    this.match.reset();
    this.players.forEach(p => p.reset());
    this.ball.reset();
    this.phase = 'countdown';
    this.phaseTimer = 3.2;
    this.running = true;
    this.ui.hideOverlay();
  }

  loop(now) {
    const dt = Math.min(.033, (now - this.last) / 1000 || 0);
    this.last = now;
    this.update(dt);
    this.draw();
    this.input.endFrame();
    requestAnimationFrame(this.loop);
  }

  update(dt) {
    if (!this.running) return;
    if (this.phase === 'goal') {
      this.phaseTimer -= dt;
      if (this.phaseTimer <= 0) {
        if (this.match.finished) {
          this.phase = 'finished';
          this.ui.showWinner(this.match, () => this.startMatch(), () => this.returnMenu());
        } else {
          this.resetPositions();
          this.phase = 'countdown';
          this.phaseTimer = 3.2;
          this.ui.hideOverlay();
        }
      }
      return;
    }
    if (this.phase === 'finished') return;
    if (this.phase === 'countdown') {
      this.phaseTimer -= dt;
      if (this.phaseTimer <= 0) this.phase = 'playing';
      return;
    }

    this.match.update(dt);
    if (this.match.finished) {
      this.phase = 'finished';
      this.ui.showWinner(this.match, () => this.startMatch(), () => this.returnMenu());
      return;
    }

    for (const p of this.players) p.update(dt, this.input);
    resolvePlayers(this.players[0], this.players[1]);
    this.ball.update(dt);
    this.handleFieldCollision();
    for (const p of this.players) resolvePlayerBall(p, this.ball);
    this.updatePossession(dt);
    this.handleKicks();
    this.checkGoal();
    this.shake = Math.max(0, this.shake - dt * 3);
    this.ui.renderHUD(this.match, this.players);
  }

  updatePossession(dt) {
    this.players.forEach((p, i) => {
      const score = possessionScore(p, this.ball, this.players[1 - i]);
      if (score > .3) p.superCharge = Math.min(1, p.superCharge + dt / CONFIG.super.chargeSeconds * score);
      else p.superCharge = Math.max(0, p.superCharge - dt * CONFIG.super.drainPerSecond);
    });
  }

  handleKicks() {
    for (const p of this.players) {
      if (!this.input.consume(p.controls.kick)) continue;
      const superReady = p.superCharge >= .999;
      if (kickBall(p, this.ball, superReady)) {
        if (superReady) this.shake = .55;
      }
    }
  }

  handleFieldCollision() {
    const b = this.ball;
    const topOfGoal = CONFIG.groundY - CONFIG.goalHeight;
    if (b.y - b.radius < topOfGoal) {
      if (b.x - b.radius < CONFIG.wall) { b.x = CONFIG.wall + b.radius; b.vx = Math.abs(b.vx) * .78; }
      if (b.x + b.radius > CONFIG.width - CONFIG.wall) { b.x = CONFIG.width - CONFIG.wall - b.radius; b.vx = -Math.abs(b.vx) * .78; }
    }
    const hitCrossbar = Math.abs((b.y + b.radius) - topOfGoal) < 16 && (b.x < CONFIG.wall + 35 || b.x > CONFIG.width - CONFIG.wall - 35);
    if (hitCrossbar && b.vy > 0) { b.y = topOfGoal - b.radius; b.vy *= -.72; }
  }

  checkGoal() {
    const b = this.ball;
    const insideHeight = b.y > CONFIG.groundY - CONFIG.goalHeight + b.radius * .2;
    if (!insideHeight) return;
    if (b.x + b.radius < 4) this.score('blue');
    else if (b.x - b.radius > CONFIG.width - 4) this.score('red');
  }

  score(team) {
    this.match.goal(team);
    this.phase = 'goal';
    this.phaseTimer = 1.45;
    this.shake = .75;
    this.ui.renderHUD(this.match, this.players);
    this.ui.flashGoal(team);
  }

  resetPositions() {
    this.players.forEach(p => p.reset());
    this.ball.reset();
  }

  returnMenu() {
    this.running = false;
    this.phase = 'menu';
    this.ui.showMenu(() => this.startMatch());
  }

  draw() {
    const ctx = this.ctx;
    ctx.clearRect(0, 0, CONFIG.width, CONFIG.height);
    ctx.save();
    if (this.shake > 0) ctx.translate((Math.random() - .5) * 12 * this.shake, (Math.random() - .5) * 8 * this.shake);
    this.drawBackground(ctx);
    this.drawGoals(ctx);
    this.players.forEach(p => p.draw(ctx));
    this.ball.draw(ctx);
    this.drawSuperBars(ctx);
    ctx.restore();
    if (this.phase === 'countdown') this.drawCountdown(ctx);
  }

  drawBackground(ctx) {
    const sky = ctx.createLinearGradient(0, 0, 0, CONFIG.groundY);
    sky.addColorStop(0, '#11192e'); sky.addColorStop(1, '#283b56');
    ctx.fillStyle = sky; ctx.fillRect(0, 0, CONFIG.width, CONFIG.groundY);
    ctx.fillStyle = '#162339';
    for (let x = 0; x < CONFIG.width; x += 32) ctx.fillRect(x, 325 + (x % 64 ? 7 : 0), 24, 70);
    ctx.fillStyle = '#178b4b'; ctx.fillRect(0, 395, CONFIG.width, CONFIG.height - 395);
    for (let x = 0; x < CONFIG.width; x += 160) { ctx.fillStyle = x % 320 ? '#198e4e' : '#158347'; ctx.fillRect(x, 395, 160, CONFIG.groundY - 395); }
    ctx.strokeStyle = 'rgba(255,255,255,.78)'; ctx.lineWidth = 5;
    ctx.beginPath(); ctx.moveTo(CONFIG.width / 2, 395); ctx.lineTo(CONFIG.width / 2, CONFIG.groundY); ctx.stroke();
    ctx.beginPath(); ctx.arc(CONFIG.width / 2, CONFIG.groundY - 105, 92, 0, Math.PI * 2); ctx.stroke();
    ctx.fillStyle = '#112d20'; ctx.fillRect(0, CONFIG.groundY, CONFIG.width, CONFIG.height - CONFIG.groundY);
  }

  drawGoals(ctx) {
    const top = CONFIG.groundY - CONFIG.goalHeight;
    ctx.save(); ctx.strokeStyle = '#f5f5f5'; ctx.lineWidth = 9;
    ctx.beginPath(); ctx.moveTo(CONFIG.wall, CONFIG.groundY); ctx.lineTo(CONFIG.wall, top); ctx.lineTo(0, top); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(CONFIG.width - CONFIG.wall, CONFIG.groundY); ctx.lineTo(CONFIG.width - CONFIG.wall, top); ctx.lineTo(CONFIG.width, top); ctx.stroke();
    ctx.strokeStyle = 'rgba(255,255,255,.24)'; ctx.lineWidth = 2;
    for (let y = top + 18; y < CONFIG.groundY; y += 24) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(CONFIG.wall,y); ctx.moveTo(CONFIG.width-CONFIG.wall,y); ctx.lineTo(CONFIG.width,y); ctx.stroke(); }
    ctx.restore();
  }

  drawSuperBars(ctx) {
    this.players.forEach(p => {
      const w = 92, h = 9, x = p.x + p.width / 2 - w / 2, y = p.y - 24;
      ctx.fillStyle = 'rgba(0,0,0,.45)'; ctx.fillRect(x, y, w, h);
      ctx.fillStyle = p.superCharge >= .999 ? '#ffe36b' : p.color; ctx.fillRect(x, y, w * p.superCharge, h);
    });
  }

  drawCountdown(ctx) {
    const n = Math.ceil(this.phaseTimer);
    ctx.save(); ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.font = '900 86px system-ui'; ctx.fillStyle = '#fff'; ctx.shadowColor = '#000'; ctx.shadowBlur = 18;
    ctx.fillText(n <= 0 ? 'VAI!' : n, CONFIG.width / 2, CONFIG.height / 2 - 50); ctx.restore();
  }
}
