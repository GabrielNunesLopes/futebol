export class InputManager {
  constructor() {
    this.keys = new Set();
    this.pressed = new Set();
    addEventListener('keydown', e => {
      if (!this.keys.has(e.code)) this.pressed.add(e.code);
      this.keys.add(e.code);
      if (['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','KeyW','KeyA','KeyS','KeyD'].includes(e.code)) e.preventDefault();
    });
    addEventListener('keyup', e => this.keys.delete(e.code));
    addEventListener('blur', () => { this.keys.clear(); this.pressed.clear(); });
  }
  down(code) { return this.keys.has(code); }
  consume(code) { const hit = this.pressed.has(code); this.pressed.delete(code); return hit; }
  endFrame() { this.pressed.clear(); }
}
