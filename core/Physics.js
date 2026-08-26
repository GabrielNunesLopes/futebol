import { CONFIG } from '../config/gameConfig.js';

export function resolvePlayerBall(player, ball) {
  const cx = Math.max(player.x, Math.min(ball.x, player.x + player.width));
  const cy = Math.max(player.y, Math.min(ball.y, player.y + player.height));
  let dx = ball.x - cx, dy = ball.y - cy;
  let dist = Math.hypot(dx, dy);
  if (dist >= ball.radius) return false;
  if (dist < 0.001) { dx = player.facing; dy = -.2; dist = 1; }
  const nx = dx / dist, ny = dy / dist;
  const push = ball.radius - dist;
  ball.x += nx * push;
  ball.y += ny * push;
  const rel = (player.vx - ball.vx) * nx + (player.vy - ball.vy) * ny;
  if (rel > -30) {
    const impulse = Math.max(35, Math.abs(rel) * .8 + Math.abs(player.vx) * .24);
    ball.vx += nx * impulse;
    ball.vy += ny * impulse;
  }
  return true;
}

export function resolvePlayers(a, b) {
  const ax = a.x + a.width / 2, bx = b.x + b.width / 2;
  const overlapX = (a.width + b.width) / 2 - Math.abs(ax - bx);
  const overlapY = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y);
  if (overlapX <= 0 || overlapY <= 0) return;
  const dir = ax < bx ? -1 : 1;
  a.x += dir * overlapX * .5;
  b.x -= dir * overlapX * .5;
  const avg = (a.vx + b.vx) * .5;
  a.vx = avg * .75; b.vx = avg * .75;
}

export function possessionScore(player, ball, opponent) {
  const c = player.center();
  const d = Math.hypot(ball.x - c.x, ball.y - (c.y + 15));
  const relSpeed = Math.hypot(ball.vx - player.vx, ball.vy - player.vy);
  const inFront = (ball.x - c.x) * player.facing > -28;
  if (d > CONFIG.super.possessionDistance || relSpeed > CONFIG.super.maxRelativeSpeed || !inFront) return 0;
  const oc = opponent.center();
  const od = Math.hypot(ball.x - oc.x, ball.y - oc.y);
  if (od < d + 15) return .25;
  return 1 - d / (CONFIG.super.possessionDistance * 1.35);
}

export function kickBall(player, ball, isSuper) {
  if (player.kickCooldown > 0) return false;
  const c = player.center();
  const dx = ball.x - c.x, dy = ball.y - c.y;
  if (Math.hypot(dx, dy) > CONFIG.kick.range) return false;
  const power = CONFIG.kick.normal * (isSuper ? CONFIG.kick.superMultiplier : 1);
  const verticalFactor = Math.max(-.65, Math.min(.45, dy / 90));
  ball.vx = player.facing * power + player.vx * .42;
  ball.vy = verticalFactor * power - CONFIG.kick.lift - Math.max(0, -player.vy * .35);
  ball.superTrail = isSuper ? .48 : 0;
  player.kickCooldown = CONFIG.player.kickCooldown;
  if (isSuper) player.superCharge = 0;
  return true;
}
