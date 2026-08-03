import { SayiGame } from './game';

customElements.define('og-sayi', SayiGame);

declare global {
  interface HTMLElementTagNameMap {
    'og-sayi': SayiGame;
  }
}
