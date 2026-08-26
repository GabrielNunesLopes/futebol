import { CONFIG } from '../config/gameConfig.js';

export class MatchManager {
  constructor() { this.reset(); }
  reset() {
    this.red = 0;
    this.blue = 0;
    this.time = CONFIG.matchSeconds;
    this.goldenGoal = false;
    this.finished = false;
    this.winner = null;
  }
  update(dt) {
    if (this.finished || this.goldenGoal) return;
    this.time = Math.max(0, this.time - dt);
    if (this.time === 0) {
      if (this.red === this.blue) this.goldenGoal = true;
      else this.finish(this.red > this.blue ? 'red' : 'blue');
    }
  }
  goal(team) {
    if (this.finished) return;
    this[team]++;
    if (this[team] >= CONFIG.goalLimit || this.goldenGoal) this.finish(team);
  }
  finish(team) { this.finished = true; this.winner = team; }
  clock() {
    if (this.goldenGoal) return 'GOLDEN GOAL';
    const total = Math.ceil(this.time);
    return `${String(Math.floor(total / 60)).padStart(2,'0')}:${String(total % 60).padStart(2,'0')}`;
  }
}
