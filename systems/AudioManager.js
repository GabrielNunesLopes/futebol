export class AudioManager {
  constructor() {
    this.enabled = true;
    this.volume = 0.18;
    this.ctx = null;
  }

  play(type = 'kick') {
    if (!this.enabled) return;
    try {
      this.ctx ??= new AudioContext();
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const now = this.ctx.currentTime;
      const freq = type === 'super' ? 115 : type === 'goal' ? 420 : 175;
      osc.frequency.setValueAtTime(freq, now);
      osc.frequency.exponentialRampToValueAtTime(Math.max(55, freq * .55), now + .12);
      gain.gain.setValueAtTime(this.volume, now);
      gain.gain.exponentialRampToValueAtTime(.001, now + .13);
      osc.connect(gain).connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + .14);
    } catch {}
  }
}
