import { CONFIG } from '../config/gameConfig.js';

export class Goal {
  constructor(side) { this.side = side; }
  contains(ball) {
    const highEnough = ball.y > CONFIG.groundY - CONFIG.goalHeight;
    if (!highEnough) return false;
    return this.side === 'left'
      ? ball.x + ball.radius < 4
      : ball.x - ball.radius > CONFIG.width - 4;
  }
}
