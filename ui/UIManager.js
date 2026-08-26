export class UIManager {
  constructor(hud, overlay) {
    this.hud = hud;
    this.overlay = overlay;
  }
  showMenu(onPlay) {
    this.hud.innerHTML = '';
    this.overlay.className = 'overlay visible';
    this.overlay.innerHTML = `
      <div class="panel">
        <p class="eyebrow">LOCAL MULTIPLAYER</p>
        <h1>1v1 FOOTBALL</h1>
        <p>Vermelho: W A D + S &nbsp; • &nbsp; Azul: ↑ ← → + ↓</p>
        <button id="playBtn">JOGAR</button>
        <div class="help">Primeiro a 3 gols ou maior placar após 3 minutos. Empate = Golden Goal.</div>
      </div>`;
    this.overlay.querySelector('#playBtn').onclick = onPlay;
  }
  hideOverlay() { this.overlay.className = 'overlay'; this.overlay.innerHTML = ''; }
  renderHUD(match, players) {
    this.hud.innerHTML = `
      <div class="score"><span class="red">VERMELHO ${match.red}</span><b>×</b><span class="blue">${match.blue} AZUL</span></div>
      <div class="clock">${match.clock()}</div>
      <div class="supers">
        <div>SUPER P1 <span>${Math.round(players[0].superCharge * 100)}%</span></div>
        <div>SUPER P2 <span>${Math.round(players[1].superCharge * 100)}%</span></div>
      </div>`;
  }
  flashGoal(team) {
    this.overlay.className = 'overlay goal-pop visible';
    this.overlay.innerHTML = `<div class="goal-text">GOOOOOL!<small>${team === 'red' ? 'TIME VERMELHO' : 'TIME AZUL'}</small></div>`;
  }
  showWinner(match, onRematch, onMenu) {
    this.overlay.className = 'overlay visible';
    const name = match.winner === 'red' ? 'TIME VERMELHO' : 'TIME AZUL';
    this.overlay.innerHTML = `<div class="panel"><p class="eyebrow">FIM DE JOGO</p><h1>${name} VENCEU!</h1><h2>${match.red} × ${match.blue}</h2><button id="again">REVANCHE</button><button class="secondary" id="menu">MENU PRINCIPAL</button></div>`;
    this.overlay.querySelector('#again').onclick = onRematch;
    this.overlay.querySelector('#menu').onclick = onMenu;
  }
}
