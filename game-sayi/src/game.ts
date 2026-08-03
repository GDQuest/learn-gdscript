import { LitElement, html, css } from 'lit';
import { property, state } from 'lit/decorators.js';
import { GameState} from '@octapull-games/core';

type Phase = 'idle' | 'playing' | 'paused' | 'won' | 'fail' | 'ended';

export class SayiGame extends LitElement {
  static styles = css`
 *,*::before,*::after { box-sizing: border-box; }

    :host {
      display: block;
      position: relative;
      font-family: var(--og-font, system-ui, sans-serif);
      background-color: var(--og-surface, hsl(0, 0%, 0%));
      color: var(--og-text, #ff0000);
      padding: 1rem;
      border-radius: var(--og-radius, 8px);
      user-select: none;
      min-width: 300px;
    }
      /* - main screen - */
    .hud {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
      .hud-stat {
      display: flex;
      flex-direction: column;
      align-items: center;
      background: hsl(0, 0%, 100%);
      border: 1px solid #00000042;
      border-radius: 10px;
      padding: .35rem .75rem;
      min-width: 56px;
    }
     .hud-stat .label {
      font-size: .6rem;
      letter-spacing: .08em;
      text-transform: uppercase;
      opacity: .55;
    }
    .hud-stat .value {
      font-size: 1rem;
      font-weight: 700;
      
      color: var(--og-primary, rgb(75, 76, 83));
    }
     
    .board {
    flex: 1;
    padding: 1rem;
    background: var(--og-bg, hsl(0, 0%, 100%));
    }
    /* - start screen - */
      .overlay {
      position: relative;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 1rem;
      padding: 2rem 1rem;
      text-align: center;
      animation: fadeIn .3s ease;
    }
  
    .overlay h2 {
      margin: 0;
      font-size: 1.6rem;
      font-weight: 800;
      background: black;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .overlay p {
      margin: 0;
      opacity: .7;
      font-size: .9rem;
    }
      /* - button - */
    
      button {
        cursor: pointer;
        background-color: var(--og-primary, rgb(23, 22, 22));
        color: white;
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 2px;
        margin-top: 1rem; 
      }
     button:active {
      transform: scale(0.98);
      }
     .btn-primary {
        background: var(--og-primary, hsl(190, 33%, 89%));
        color: rgb(0, 0, 0);
        display: inline-block;
        align-items: center;
      }
     .btn-center {
      display: flex;
      justify-content: center;
      margin-top: 1rem;
      margin-bottom: 1rem;
}
     
    .btn-primary:hover { 
    background: var(--og-primary-hover, hsla(253, 99%, 55%, 0.39));
    }
    
/* - tried number - */
  .tried-box {
    background: hsl(0, 0%, 100%);
    border: 1px solid  #00000042;
    border-radius: 10px;
    padding: 0.5rem 0.75rem;
    min-width: 90px;
    max-height: 220px;
    overflow-y: auto;
    }
  .tried-box .label {
    font-size: .6rem;
    letter-spacing: .08em;
    text-transform: uppercase;
    opacity: .55;
    display: block;
   margin-bottom: .35rem;
  }
  .tried-box ul {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-wrap: wrap;
    gap: 0.3rem;
}
  .tried-box li {
    background: var(--og-primary, hsl(190, 33%, 89%));
    border-radius: 6px;
    padding: 0.15rem 0.45rem;
    font-size: 0.8rem;
    font-weight: 600;
}
  `;
  

  @property({ type: String }) mode: 'levels' | 'random' = 'levels';
  @property({ type: Number }) levelCount = 10;
  @property({ attribute: false }) gameState: GameState | null = null;
  @property({ type: Boolean }) muted = false;
  @property({ type: Number }) seed?: number;

 
  @state() private currentLevel = 0;
  @state() private currentPoint = 0;
 
  @state() private _phase: Phase = 'idle';
  @state() private _secretNumber: number = Math.floor(Math.random() * 100) +1;
  @state() private _movesLeft = 0;
  @state() private _guessValue: number = 0;
  @state() private _message = '';
  @state() private _triedNumbers: number[] = [];

  private _seviyeZor(level: number): number{
  if( level < 3) {
    return 10;
  }
  else if(level < 7){
    return 7;
  }
  else{
    return 5;
  }
} 

private _handleInputChange(e: Event){
  this._guessValue = (e.target as HTMLInputElement).valueAsNumber;
}


  connectedCallback() {
    super.connectedCallback();
    if (this.gameState) {
      this.currentLevel = this.gameState.currentLevel;
    }
    this._dispatch('og-ready', { gameId: 'game-sayi' });
  }
disconnectedCallback() {
    super.disconnectedCallback();
  } 
    // Dispatch ready event
private _startLevel(resetAll: boolean = false) {
  this._audioCtx();
if (resetAll) {
    this.currentLevel = 0;
    this.currentPoint = 0;
  }
  this._guessValue =0;
  this._triedNumbers = [];
  const _secretNumber = Math.floor(Math.random() * 100) +1;
  this._secretNumber = _secretNumber;
 
  this._message ="1 ile 100 arasındaki sayıyı tahmin et.";
  this._phase = 'playing';
  
  this._movesLeft = this._seviyeZor(this.currentLevel);
  

  this._dispatch('og-level-start', {
    gameId: 'game-sayi',
    level: this.currentLevel,
    startedAt: new Date().toISOString(),
  });
}
private _handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    this._handleGuess();
  }
}

  private _handleGuess() {
    if (this._phase !== 'playing') return;

    const guessNumber = Number(this._guessValue);

      if (isNaN(this._guessValue)) {
    this._message = "Geçerli sayı gir.";
    return;       
  }
  if (this._guessValue > 100 || this._guessValue < 1) {
      this._message = "Geçerli aralıkta bir sayı gir.";
      this._guessValue = 0;
      return;
    }
  if(this._triedNumbers.includes(guessNumber)){
    this._message = `${guessNumber} Sayısını daha önce girdin!`
    this._guessValue = 0;
    return;
  }
  this._triedNumbers = [...this._triedNumbers, guessNumber];
   this._guessValue =0;

    if (guessNumber === this._secretNumber) {
      this._phase = 'won';
      this._message = `Doğru Bildin!`;
      this.currentPoint++;
       this.currentLevel++; 
        this._playTone(true);
      this.handleComplete();
      return;
    }
    if (this._movesLeft <= 1){
      this._movesLeft--;
       this._playTone(false);
      this.currentLevel++;
      this._message = `Tahmin Etme Hakkın Kalmadı. Aradığın Sayı: ${this._secretNumber}.`;
      this.handleComplete();

      this._phase = this.currentLevel >= this.levelCount ? 'ended' : 'fail';
      return;
    }
  
  if(guessNumber> 100){
          this._message = "Gerçli aralıkta bir sayı gir.";
        }
  else if (guessNumber < this._secretNumber) {
    this._message = "Aradığın sayı daha büyük!";
       
    this._movesLeft--;
  } 
  else if (guessNumber > this._secretNumber) {
    this._message = "Aradığın sayı daha küçük!";
    this._movesLeft--;
  } 
 
  }
 

 private _nextLevel() {

  this._startLevel();
 
  }

  private handleComplete() {
    const durationMs = 5000; // Example duration
    this._dispatch('og-level-complete', {
        detail: {
          gameId: 'game-sayi',
          level: this.currentLevel,
          durationMs,
          isBest: false,
        },
      });
    // Update state example
    const newState: GameState = {
      version: 1,
      gameId: 'game-sayi',
      currentLevel: this.currentLevel + 1,
      completedLevels: this.gameState?.completedLevels || [],
      bestTimes: this.gameState?.bestTimes || {},
      totalPlayMs: (this.gameState?.totalPlayMs || 0) + durationMs,
    };

    newState.completedLevels.push({
      level: this.currentLevel,
      durationMs,
      completedAt: new Date().toISOString(),
    });

    this._dispatch('og-state-change', {
        bubbles: true,
        composed: true,
        detail: {
          gameId: 'game-sayi',
          state: newState,
        },
      })
    ;
  }  
  private _dispatch(name: string, detail: Record<string, unknown>) {
    this.dispatchEvent(new CustomEvent(name, { bubbles: true, composed: true, detail }));
  }

private _ctx: AudioContext | null = null;
private _audioCtx() {
  if (!this._ctx) this._ctx = new AudioContext();
  return this._ctx;
}

private _playTone(success: boolean) {
  if (this.muted) return;
  try {
    const ctx = this._audioCtx();

    if (success) {
  
      const notes = [523, 659, 784];
      const noteDuration = 0.12;

      notes.forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);

        const startTime = ctx.currentTime + i * noteDuration;
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, startTime);

        gain.gain.setValueAtTime(0.2, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + noteDuration);

        osc.start(startTime);
        osc.stop(startTime + noteDuration);
      });
    } else {
      const beatCount = 3;
      const beatDuration = 0.08;
      const gap = 0.06;

      for (let i = 0; i < beatCount; i++) {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);

        const startTime = ctx.currentTime + i * (beatDuration + gap);
        osc.type = 'square';
        osc.frequency.setValueAtTime(140, startTime);

        gain.gain.setValueAtTime(0.15, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + beatDuration);

        osc.start(startTime);
        osc.stop(startTime + beatDuration);
      }
    }
  } catch (_) {}
}

private _renderHUD() {
return html`
  <div class="hud" part="hud">
    <div class="hud-stat">
     <span class="label">Seviye</span>
     <span class="value">
     ${this.mode == 'levels' ? `${this.currentLevel} ` : '∞'}
     </span>
    </div>
    <div class="hud-stat">
        <span class="label">Puan</span>
        <span class="value">${this.currentPoint}</span>
    </div>
    <div class="hud-stat">
          <span class="label">Kalan Tahmin Hakkı </span>
          <span class="value">${this._movesLeft}</span>             
    </div>
  </div>
    `;
}
private _renderEnded() {
  return html`
    <div class="overlay">
      <h1>Oyun Bitti</h1>
      <h2>Puanın: ${this.currentPoint}</h2>
      <button class="btn-primary" @click=${() => this._startLevel(true)}>
        Tekrar Oyna
      </button>
    </div>
  `;
}
private _renderBoard() {

return html`
<div
  class="board" part="board">
  <p>${this._message}</p>
  <input
  type="number"
  .value= ${this._guessValue === 0 ? '' : String(this._guessValue)}
  @input = ${this._handleInputChange}
  @keydown=${this._handleKeyDown}
  placeholder="Tahmin Et"/>
  <button
  class="btn-primary"
  @click=${this._handleGuess}
  ?disabled = ${this._phase !== 'playing'}
  >
  Tahmin Et
  </button>
 </div>
`;
}
private _renderTriedBox() {
  return html`
  <div class="tried-box">
    <span class="label">Önceden Girdiğin Sayılar</span>
    <ul>
    ${this._triedNumbers.map(n => html`<li>${n}</li>`)}
    </ul>
  </div>
  `;
}

private _renderIdle() {
    return html`
      <div class="overlay">
        <h1>Sayı Bulmaca</h1>
        <h2>Doğru Sayıyı Tahmin Et!</h2>
        <p>Seviye İlerledikçe Tahmin Hakkın Azalıyor!</p>
      <button class="btn-primary" @click=${() => this._startLevel(true)} aria-label="Oyunu başlat">
        Başla
      </button>   
      </div>
     
    
    `;
  }

  render() {
    if(this._phase === 'idle'){
      return this._renderIdle();
    }
     if (this._phase === 'ended') {
      return this._renderEnded();
    }
    return html`
    ${this._renderHUD()}
   
    ${this._renderBoard()}
    ${this._phase === 'playing' ? this._renderTriedBox() : ''}
  
     
      ${ this._phase ==='won' || this._phase === 'fail'
    ? html`
   <div class="btn-center">
        <button class="btn-primary"
        @click=${() => this._nextLevel()}>
          Oynamaya Devam Et!
        </button>
      </div>
    `
    : ''}
     
    `;
  
  }
}
