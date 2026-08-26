import './style.css';
import { Game } from '../core/Game.js';

const canvas = document.querySelector('#gameCanvas');
const hud = document.querySelector('#hud');
const overlay = document.querySelector('#overlay');

new Game(canvas, hud, overlay);
