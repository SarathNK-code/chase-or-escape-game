import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Toaster } from "@/components/ui/sonner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Coins, Loader2, Shield, Timer, Trophy, Zap, Play, Gamepad2, Target, Sparkles, Heart, ArrowRight, ArrowLeft, X, SkipForward } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { useActor } from "./hooks/useActor";

// ========================
// CONSTANTS
// ========================
const TILE_SIZE = 40;
const CANVAS_W = 800;
const CANVAS_H = 600;
const MAP_COLS = CANVAS_W / TILE_SIZE; // 20
const MAP_ROWS = CANVAS_H / TILE_SIZE; // 15
const PLAYER_RADIUS = 14;
const COIN_RADIUS = 7;
const DECOY_RADIUS = 10;
const FOOTPRINT_RADIUS = 5;
const FOOTPRINT_INTERVAL = 8;
const FOOTPRINT_FADE_MS = 3000;
const CATCH_DISTANCE = 24;
const DECOY_DISTRACT_DIST = 200;
const DECOY_LIFESPAN = 5000; // ms — decoy lasts 5 seconds
const GAME_DURATION = 90;
const PLAYER_SPEED = 160;
const AI_SPEED = 125;
const MAX_DECOYS = 3;
const NUM_COINS = 15;
const COIN_VALUE = 10;
const BONUS_COIN_VALUE = 25; // Extra points for bonus coins
const BONUS_COIN_INTERVAL = 8000; // Change bonus coin every 8 seconds
const EXPLOSION_DURATION = 600; // Animation duration for coin explosions
const AI_LAG_INTERVAL = 900;

// ========================
// MAP LAYOUT (20 x 15)
// ========================
const MAP: number[][] = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
];

// ========================
// TYPES
// ========================
type Role = "escaper" | "hunter";
type GamePhase = "role_select" | "playing" | "game_over";

interface Vec2 {
  x: number;
  y: number;
}
interface Entity {
  pos: Vec2;
  dir: number;
}

interface Footprint {
  x: number;
  y: number;
  timestamp: number;
}
interface Coin {
  x: number;
  y: number;
  collected: boolean;
  isBonus: boolean;
  explosionAnim?: {
    startTime: number;
    x: number;
    y: number;
  };
}
interface Decoy {
  id: number;
  x: number;
  y: number;
  createdAt: number;
}

interface GameResult {
  winner: Role;
  score: number;
  coinsCollected: number;
  timeRemaining: number;
}

interface GameState {
  escaper: Entity;
  hunter: Entity;
  footprints: Footprint[];
  coins: Coin[];
  decoys: Decoy[];
  timeRemaining: number;
  coinsCollected: number;
  decoysRemaining: number;
  hunterTarget: Vec2;
  hunterTargetTimer: number;
  hunterDistractTimer: number;
  escaperAIDir: Vec2;
  escaperAITimer: number;
  frameCount: number;
  status: "playing" | "over";
  result: GameResult | null;
  decoyIdCounter: number;
  bonusCoinIndex: number;
  lastBonusCoinChange: number;
  totalScore: number; // Track score with bonus coin points
}

// ========================
// MAP UTILITIES
// ========================
function tileCenter(col: number, row: number): Vec2 {
  return {
    x: col * TILE_SIZE + TILE_SIZE / 2,
    y: row * TILE_SIZE + TILE_SIZE / 2,
  };
}

function isWall(col: number, row: number): boolean {
  if (col < 0 || col >= MAP_COLS || row < 0 || row >= MAP_ROWS) return true;
  return MAP[row][col] === 1;
}

function isWallAt(x: number, y: number): boolean {
  const r = PLAYER_RADIUS - 3;
  return [
    { x: x - r, y: y - r },
    { x: x + r, y: y - r },
    { x: x - r, y: y + r },
    { x: x + r, y: y + r },
  ].some((c) =>
    isWall(Math.floor(c.x / TILE_SIZE), Math.floor(c.y / TILE_SIZE)),
  );
}

function vecDist(a: Vec2, b: Vec2): number {
  return Math.sqrt((a.x - b.x) ** 2 + (a.y - b.y) ** 2);
}

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function createInitialGameState(): GameState {
  const floorTiles: Vec2[] = [];
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (MAP[r][c] === 0) floorTiles.push(tileCenter(c, r));
    }
  }
  const escaperSpawn = tileCenter(1, 1);
  const hunterSpawn = tileCenter(18, 13);
  const coinCandidates = floorTiles.filter(
    (t) =>
      vecDist(t, escaperSpawn) > TILE_SIZE * 2.5 &&
      vecDist(t, hunterSpawn) > TILE_SIZE * 2.5,
  );
  const coins: Coin[] = shuffleArray(coinCandidates)
    .slice(0, NUM_COINS)
    .map((t, index) => ({ 
      x: t.x, 
      y: t.y, 
      collected: false,
      isBonus: index === 0 // First coin starts as bonus
    }));
  return {
    escaper: { pos: { ...escaperSpawn }, dir: 0 },
    hunter: { pos: { ...hunterSpawn }, dir: Math.PI },
    footprints: [],
    coins,
    decoys: [],
    timeRemaining: GAME_DURATION,
    coinsCollected: 0,
    decoysRemaining: MAX_DECOYS,
    hunterTarget: { ...escaperSpawn },
    hunterTargetTimer: AI_LAG_INTERVAL,
    hunterDistractTimer: 0,
    escaperAIDir: { x: 1, y: 0 },
    escaperAITimer: 0,
    frameCount: 0,
    status: "playing",
    result: null,
    decoyIdCounter: 0,
    bonusCoinIndex: 0,
    lastBonusCoinChange: Date.now(),
    totalScore: 0,
  };
}

// ========================
// GAME LOGIC
// ========================
function moveEntity(entity: Entity, dx: number, dy: number): void {
  const nx = entity.pos.x + dx;
  const ny = entity.pos.y + dy;
  if (!isWallAt(nx, entity.pos.y)) entity.pos.x = nx;
  if (!isWallAt(entity.pos.x, ny)) entity.pos.y = ny;
}

function updatePlayerMovement(
  entity: Entity,
  dt: number,
  keys: Set<string>,
  speed: number,
): void {
  let dx = 0;
  let dy = 0;
  if (keys.has("arrowleft") || keys.has("a")) dx -= 1;
  if (keys.has("arrowright") || keys.has("d")) dx += 1;
  if (keys.has("arrowup") || keys.has("w")) dy -= 1;
  if (keys.has("arrowdown") || keys.has("s")) dy += 1;
  if (dx !== 0 || dy !== 0) {
    const len = Math.sqrt(dx * dx + dy * dy);
    const s = speed * dt;
    dx = (dx / len) * s;
    dy = (dy / len) * s;
    entity.dir = Math.atan2(dy, dx);
    moveEntity(entity, dx, dy);
  }
}

function updateAIHunter(gs: GameState, dt: number): void {
  gs.hunterDistractTimer = Math.max(0, gs.hunterDistractTimer - dt * 1000);
  gs.hunterTargetTimer -= dt * 1000;
  if (gs.hunterTargetTimer <= 0) {
    gs.hunterTargetTimer = AI_LAG_INTERVAL;
    
    // Random targeting logic
    if (gs.decoys.length > 0 && Math.random() < 0.7) { // 70% chance to target decoy if available
      // Find nearest decoy
      let nearest: Decoy | null = null;
      let nearestD = DECOY_DISTRACT_DIST;
      for (const d of gs.decoys) {
        const dd = vecDist(gs.hunter.pos, d);
        if (dd < nearestD) {
          nearestD = dd;
          nearest = d;
        }
      }
      if (nearest) {
        gs.hunterTarget = { x: nearest.x, y: nearest.y };
        gs.hunterDistractTimer = 4000;
      } else {
        gs.hunterTarget = { ...gs.escaper.pos };
      }
    } else {
      // Target escaper or random direction
      if (Math.random() < 0.8) { // 80% chance to target escaper
        gs.hunterTarget = { ...gs.escaper.pos };
      } else {
        // Random movement in general direction of escaper
        const angle = Math.atan2(
          gs.escaper.pos.y - gs.hunter.pos.y,
          gs.escaper.pos.x - gs.hunter.pos.x
        ) + (Math.random() - 0.5) * Math.PI / 2;
        gs.hunterTarget = {
          x: gs.hunter.pos.x + Math.cos(angle) * 100,
          y: gs.hunter.pos.y + Math.sin(angle) * 100
        };
      }
    }
  }
  
  // If distracted but target decoy no longer exists, chase escaper
  if (gs.hunterDistractTimer > 0) {
    const targetIsDecoy = gs.decoys.some(
      (d) => d.x === gs.hunterTarget.x && d.y === gs.hunterTarget.y,
    );
    if (!targetIsDecoy) {
      gs.hunterDistractTimer = 0;
      gs.hunterTarget = { ...gs.escaper.pos };
    }
  }
  
  const dx = gs.hunterTarget.x - gs.hunter.pos.x;
  const dy = gs.hunterTarget.y - gs.hunter.pos.y;
  const d = Math.sqrt(dx * dx + dy * dy);
  if (d > 2) {
    const s = AI_SPEED * dt;
    gs.hunter.dir = Math.atan2(dy, dx);
    moveEntity(gs.hunter, (dx / d) * s, (dy / d) * s);
  }
}

function updateAIEscaper(gs: GameState, dt: number): void {
  gs.escaperAITimer -= dt * 1000;
  if (gs.escaperAITimer <= 0) {
    gs.escaperAITimer = 500;
    const dx = gs.escaper.pos.x - gs.hunter.pos.x;
    const dy = gs.escaper.pos.y - gs.hunter.pos.y;
    const angle = Math.atan2(dy, dx) + (Math.random() - 0.5) * 1.2;
    gs.escaperAIDir = { x: Math.cos(angle), y: Math.sin(angle) };
  }
  const s = PLAYER_SPEED * 0.88 * dt;
  gs.escaper.dir = Math.atan2(gs.escaperAIDir.y, gs.escaperAIDir.x);
  moveEntity(gs.escaper, gs.escaperAIDir.x * s, gs.escaperAIDir.y * s);
}

function updateGame(
  gs: GameState,
  dt: number,
  playerRole: Role,
  keys: Set<string>,
): void {
  gs.frameCount++;
  gs.timeRemaining -= dt;
  if (gs.timeRemaining <= 0) {
    gs.timeRemaining = 0;
    gs.status = "over";
    gs.result = {
      winner: "escaper",
      score: gs.totalScore,
      coinsCollected: gs.coinsCollected,
      timeRemaining: 0,
    };
    return;
  }
  // Footprints
  if (gs.frameCount % FOOTPRINT_INTERVAL === 0) {
    gs.footprints.push({
      x: gs.escaper.pos.x,
      y: gs.escaper.pos.y,
      timestamp: Date.now(),
    });
  }
  const now = Date.now();
  gs.footprints = gs.footprints.filter(
    (fp) => now - fp.timestamp < FOOTPRINT_FADE_MS,
  );
  // Decoy cleanup — remove expired decoys
  gs.decoys = gs.decoys.filter((d) => now - d.createdAt < DECOY_LIFESPAN);
  
  // Rotate bonus coin
  if (now - gs.lastBonusCoinChange > BONUS_COIN_INTERVAL) {
    const availableCoins = gs.coins.filter(c => !c.collected);
    if (availableCoins.length > 0) {
      gs.bonusCoinIndex = Math.floor(Math.random() * availableCoins.length);
      gs.lastBonusCoinChange = now;
    }
  }
  // Move entities
  if (playerRole === "escaper") {
    updatePlayerMovement(gs.escaper, dt, keys, PLAYER_SPEED);
    updateAIHunter(gs, dt);
  } else {
    updatePlayerMovement(gs.hunter, dt, keys, PLAYER_SPEED);
    updateAIEscaper(gs, dt);
  }
  // Coin collection
  for (let i = 0; i < gs.coins.length; i++) {
    const coin = gs.coins[i];
    if (!coin.collected && vecDist(gs.escaper.pos, coin) < PLAYER_RADIUS + COIN_RADIUS) {
      coin.collected = true;
      gs.coinsCollected++;
      
      // Check if this was the bonus coin
      const availableCoins = gs.coins.filter(c => !c.collected);
      const currentBonusCoin = availableCoins[gs.bonusCoinIndex];
      
      if (currentBonusCoin && currentBonusCoin.x === coin.x && currentBonusCoin.y === coin.y) {
        gs.totalScore += BONUS_COIN_VALUE;
        // Add explosion animation
        coin.explosionAnim = {
          startTime: now,
          x: coin.x,
          y: coin.y
        };
      } else {
        gs.totalScore += COIN_VALUE;
      }
    }
  }
  // All coins collected — escaper wins!
  if (gs.coins.every((c) => c.collected)) {
    gs.status = "over";
    gs.result = {
      winner: "escaper",
      score: gs.totalScore + Math.round(gs.timeRemaining * 5),
      coinsCollected: gs.coinsCollected,
      timeRemaining: gs.timeRemaining,
    };
    return;
  }
  // Catch detection
  if (vecDist(gs.escaper.pos, gs.hunter.pos) < CATCH_DISTANCE) {
    gs.status = "over";
    gs.result = {
      winner: "hunter",
      score: Math.round(gs.timeRemaining * 10),
      coinsCollected: gs.coinsCollected,
      timeRemaining: gs.timeRemaining,
    };
  }
}

// ========================
// RENDERING
// ========================
function renderGame(ctx: CanvasRenderingContext2D, gs: GameState): void {
  const now = Date.now();
  // Background
  ctx.fillStyle = "#060d1f";
  ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  // Grid lines
  ctx.strokeStyle = "#0d1a33";
  ctx.lineWidth = 0.5;
  for (let c = 0; c <= MAP_COLS; c++) {
    ctx.beginPath();
    ctx.moveTo(c * TILE_SIZE, 0);
    ctx.lineTo(c * TILE_SIZE, CANVAS_H);
    ctx.stroke();
  }
  for (let r = 0; r <= MAP_ROWS; r++) {
    ctx.beginPath();
    ctx.moveTo(0, r * TILE_SIZE);
    ctx.lineTo(CANVAS_W, r * TILE_SIZE);
    ctx.stroke();
  }
  // Walls
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (MAP[r][c] === 1) {
        ctx.fillStyle = "#1a2744";
        ctx.fillRect(c * TILE_SIZE, r * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        ctx.strokeStyle = "#243558";
        ctx.lineWidth = 1;
        ctx.strokeRect(
          c * TILE_SIZE + 0.5,
          r * TILE_SIZE + 0.5,
          TILE_SIZE - 1,
          TILE_SIZE - 1,
        );
      }
    }
  }
  // Footprints
  for (const fp of gs.footprints) {
    const age = now - fp.timestamp;
    const alpha = Math.max(0, 0.55 * (1 - age / FOOTPRINT_FADE_MS));
    ctx.beginPath();
    ctx.arc(fp.x, fp.y, FOOTPRINT_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(96,165,250,${alpha.toFixed(2)})`;
    ctx.fill();
  }
  // Coins
  for (const coin of gs.coins) {
    if (!coin.collected) {
      const availableCoins = gs.coins.filter(c => !c.collected);
      const currentBonusCoin = availableCoins[gs.bonusCoinIndex];
      const isCurrentBonus = currentBonusCoin && currentBonusCoin.x === coin.x && currentBonusCoin.y === coin.y;
      
      ctx.save();
      if (isCurrentBonus) {
        // Bonus coin - pulsing golden effect
        const pulse = Math.sin(now * 0.006) * 0.3 + 0.7;
        ctx.shadowBlur = 20 + pulse * 10;
        ctx.shadowColor = "#fbbf24";
        ctx.beginPath();
        ctx.arc(coin.x, coin.y, COIN_RADIUS * (1 + pulse * 0.2), 0, Math.PI * 2);
        ctx.fillStyle = "#f59e0b";
        ctx.fill();
        ctx.strokeStyle = "#fde68a";
        ctx.lineWidth = 2;
        ctx.stroke();
        
        // Add star effect for bonus
        ctx.fillStyle = "#fff";
        ctx.font = "bold 10px Arial";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("★", coin.x, coin.y);
      } else {
        // Regular coin
        ctx.shadowBlur = 10;
        ctx.shadowColor = "#fbbf24";
        ctx.beginPath();
        ctx.arc(coin.x, coin.y, COIN_RADIUS, 0, Math.PI * 2);
        ctx.fillStyle = "#f59e0b";
        ctx.fill();
        ctx.strokeStyle = "#fde68a";
        ctx.lineWidth = 1.5;
        ctx.stroke();
      }
      ctx.restore();
    }
  }
  
  // Explosion animations
  for (const coin of gs.coins) {
    if (coin.explosionAnim) {
      const age = now - coin.explosionAnim.startTime;
      if (age < EXPLOSION_DURATION) {
        const progress = age / EXPLOSION_DURATION;
        const alpha = 1 - progress;
        const radius = COIN_RADIUS + progress * 20;
        
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.beginPath();
        ctx.arc(coin.explosionAnim.x, coin.explosionAnim.y, radius, 0, Math.PI * 2);
        ctx.strokeStyle = "#fbbf24";
        ctx.lineWidth = 3;
        ctx.stroke();
        
        // Inner explosion
        ctx.beginPath();
        ctx.arc(coin.explosionAnim.x, coin.explosionAnim.y, radius * 0.6, 0, Math.PI * 2);
        ctx.strokeStyle = "#fde68a";
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.restore();
      } else {
        delete coin.explosionAnim;
      }
    }
  }
  // Decoys — fade out and show shrinking timer ring
  for (const decoy of gs.decoys) {
    const age = now - decoy.createdAt;
    const lifeRatio = Math.max(0, 1 - age / DECOY_LIFESPAN);
    ctx.save();
    ctx.shadowBlur = 20 * lifeRatio;
    ctx.shadowColor = `rgba(6,182,212,${lifeRatio.toFixed(2)})`;
    ctx.beginPath();
    ctx.arc(decoy.x, decoy.y, DECOY_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(6,182,212,${(0.65 * lifeRatio).toFixed(2)})`;
    ctx.fill();
    ctx.strokeStyle = `rgba(34,211,238,${lifeRatio.toFixed(2)})`;
    ctx.lineWidth = 2;
    ctx.stroke();
    // Timer ring — shrinks as decoy expires
    const ringRadius = DECOY_RADIUS + 6;
    ctx.beginPath();
    ctx.arc(
      decoy.x,
      decoy.y,
      ringRadius,
      -Math.PI / 2,
      -Math.PI / 2 + Math.PI * 2 * lifeRatio,
    );
    ctx.strokeStyle = `rgba(103,232,249,${(0.8 * lifeRatio).toFixed(2)})`;
    ctx.lineWidth = 2.5;
    ctx.stroke();
    ctx.restore();
  }
  // Escaper
  {
    const e = gs.escaper;
    ctx.save();
    ctx.translate(e.pos.x, e.pos.y);
    ctx.shadowBlur = 18;
    ctx.shadowColor = "#3b82f6";
    ctx.beginPath();
    ctx.arc(0, 0, PLAYER_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = "#1d4ed8";
    ctx.fill();
    ctx.strokeStyle = "#93c5fd";
    ctx.lineWidth = 2.5;
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.strokeStyle = "#dbeafe";
    ctx.lineWidth = 2;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(Math.cos(e.dir) * 11, Math.sin(e.dir) * 11);
    ctx.stroke();
    ctx.restore();
  }
  // Hunter
  {
    const h = gs.hunter;
    ctx.save();
    ctx.translate(h.pos.x, h.pos.y);
    ctx.shadowBlur = 18;
    ctx.shadowColor = "#ef4444";
    ctx.beginPath();
    ctx.arc(0, 0, PLAYER_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = "#991b1b";
    ctx.fill();
    ctx.strokeStyle = "#fca5a5";
    ctx.lineWidth = 2.5;
    ctx.stroke();
    ctx.shadowBlur = 0;
    const ex = Math.cos(h.dir) * 6;
    const ey = Math.sin(h.dir) * 6;
    const px = -Math.sin(h.dir) * 3.5;
    const py = Math.cos(h.dir) * 3.5;
    ctx.fillStyle = "#fecaca";
    ctx.beginPath();
    ctx.arc(ex + px, ey + py, 2.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(ex - px, ey - py, 2.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
  // HUD
  ctx.fillStyle = "rgba(0,0,0,0.72)";
  ctx.fillRect(0, 0, CANVAS_W, 46);
  ctx.font = "bold 20px 'Courier New', monospace";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  const tc =
    gs.timeRemaining <= 10
      ? "#f87171"
      : gs.timeRemaining <= 30
        ? "#fbbf24"
        : "#4ade80";
  ctx.fillStyle = tc;
  const mm = Math.floor(gs.timeRemaining / 60);
  const ss = Math.floor(gs.timeRemaining % 60);
  ctx.fillText(`${mm}:${ss.toString().padStart(2, "0")}`, CANVAS_W / 2, 23);
  ctx.textAlign = "left";
  ctx.font = "bold 13px 'Courier New', monospace";
  ctx.fillStyle = "#fbbf24";
  ctx.fillText(`SCORE: ${gs.totalScore}`, 12, 15);
  ctx.fillStyle = "#22d3ee";
  ctx.fillText(`DECOYS[Q]: ${gs.decoysRemaining}`, 12, 35);
  ctx.textAlign = "right";
  ctx.fillStyle = "#60a5fa";
  ctx.fillText(
    `COINS: ${gs.coins.filter((c) => !c.collected).length} left`,
    CANVAS_W - 12,
    23,
  );
}

// ========================
// GAME CANVAS COMPONENT
// ========================
interface GameCanvasProps {
  playerRole: Role;
  onGameOver: (result: GameResult) => void;
}

function GameCanvas({ playerRole, onGameOver }: GameCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const gsRef = useRef<GameState>(createInitialGameState());
  const keysRef = useRef<Set<string>>(new Set());
  const rafRef = useRef<number>(0);
  const lastTimeRef = useRef<number>(0);
  const onGameOverRef = useRef(onGameOver);

  useEffect(() => {
    onGameOverRef.current = onGameOver;
  }, [onGameOver]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      keysRef.current.add(e.key.toLowerCase());
      if (e.key.toLowerCase() === "q" && playerRole === "escaper") {
        const gs = gsRef.current;
        if (gs.decoysRemaining > 0 && gs.status === "playing") {
          gs.decoys.push({
            id: gs.decoyIdCounter++,
            x: gs.escaper.pos.x,
            y: gs.escaper.pos.y,
            createdAt: Date.now(),
          });
          gs.decoysRemaining--;
        }
      }
      if (
        ["arrowup", "arrowdown", "arrowleft", "arrowright", " "].includes(
          e.key.toLowerCase(),
        )
      ) {
        e.preventDefault();
      }
    };
    const handleKeyUp = (e: KeyboardEvent) => {
      keysRef.current.delete(e.key.toLowerCase());
    };
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("keyup", handleKeyUp);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("keyup", handleKeyUp);
    };
  }, [playerRole]);

  useEffect(() => {
    gsRef.current = createInitialGameState();
    lastTimeRef.current = 0;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const loop = (timestamp: number) => {
      if (lastTimeRef.current === 0) lastTimeRef.current = timestamp;
      const dt = Math.min((timestamp - lastTimeRef.current) / 1000, 0.05);
      lastTimeRef.current = timestamp;
      const gs = gsRef.current;
      if (gs.status === "playing") {
        updateGame(gs, dt, playerRole, keysRef.current);
      }
      if ((gs.status as string) === "over" && gs.result) {
        renderGame(ctx, gs);
        onGameOverRef.current(gs.result);
        return;
      }
      renderGame(ctx, gs);
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => {
      cancelAnimationFrame(rafRef.current);
    };
  }, [playerRole]);

  return (
    <div className="flex flex-col items-center gap-3">
      <canvas
        ref={canvasRef}
        width={CANVAS_W}
        height={CANVAS_H}
        data-ocid="game.canvas_target"
        className="rounded-lg border border-cyan-500/20 shadow-2xl shadow-cyan-950/50"
        style={{ maxWidth: "100%", imageRendering: "pixelated" }}
      />
      <div className="flex gap-6 text-xs font-mono text-slate-400">
        <span className="text-blue-400">● You (Escaper)</span>
        <span className="text-red-400">● AI Hunter</span>
        <span className="text-yellow-400">● Coins (+10/★+25)</span>
        <span className="text-cyan-400">● Decoys [Q] (5s)</span>
        <span>WASD / Arrow Keys to move</span>
      </div>
    </div>
  );
}

// ========================
// ROLE SELECT SCREEN
// ========================
interface RoleSelectProps {
  onStart: (role: Role, name: string) => void;
}

  function RoleSelectScreen({ onStart }: RoleSelectProps) {
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);
  const [playerName, setPlayerName] = useState("");
  const [showTour, setShowTour] = useState(true);
  const [tourStep, setTourStep] = useState(0);

  const handleStart = () => {
    if (selectedRole && playerName.trim()) {
      onStart(selectedRole, playerName.trim());
    }
  };

  const tourSteps = [
    {
      title: "Welcome to Chase & Escape!",
      description: "Choose your hero and complete your mission!",
      icon: <Gamepad2 className="w-16 h-16 text-blue-400" />,
      content: (
        <div className="text-center space-y-4">
          <p className="text-white text-lg">Be fast, smart, and quick to win!</p>
          <div className="flex justify-center gap-6">
            <div className="text-center">
              <div className="text-2xl mb-1">🏃‍♂️</div>
              <p className="text-blue-300">Be Fast</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-1">🎯</div>
              <p className="text-red-300">Be Smart</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-1">⏱</div>
              <p className="text-yellow-300">Be Quick</p>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Game Rules",
      description: "Master the basics to win!",
      icon: <Sparkles className="w-16 h-16 text-yellow-400" />,
      content: (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4">
            <div className="flex items-center gap-3">
              <Timer className="w-8 h-8 text-green-400" />
              <div>
                <p className="text-white font-semibold">90 Seconds Timer</p>
                <p className="text-white/70 text-sm">Complete your mission before time runs out!</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Coins className="w-8 h-8 text-yellow-400" />
              <div>
                <p className="text-white font-semibold">15 Magic Coins</p>
                <p className="text-white/70 text-sm">Escapers must collect all coins to win!</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Target className="w-8 h-8 text-purple-400" />
              <div>
                <p className="text-white font-semibold">Smart AI Opponent</p>
                <p className="text-white/70 text-sm">Face an intelligent computer opponent!</p>
              </div>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Game Controls",
      description: "Learn the controls to play!",
      icon: <Heart className="w-16 h-16 text-pink-400" />,
      content: (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center mx-auto mb-2">
                <span className="text-white font-bold">↑↓←→</span>
              </div>
              <p className="text-white font-semibold">Arrow Keys</p>
              <p className="text-white/70 text-sm">Move your character</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center mx-auto mb-2">
                <span className="text-white font-bold text-sm">SPACE</span>
              </div>
              <p className="text-white font-semibold">Space Bar</p>
              <p className="text-white/70 text-sm">Drop decoys (Escaper only)</p>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Choose Your Hero",
      description: "Select your character and start playing!",
      icon: <Trophy className="w-16 h-16 text-amber-400" />,
      content: (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-6">
            <div className="text-center p-4 bg-blue-500/20 rounded-lg">
              <div className="text-2xl mb-2">🏃‍♂️</div>
              <p className="text-white font-bold">Escaper</p>
              <p className="text-blue-300 text-sm">Speed Hero</p>
              <ul className="text-white/80 text-sm mt-2 space-y-1">
                <li>• Collect 15 coins</li>
                <li>• Drop decoys</li>
                <li>• Survive 90 seconds</li>
              </ul>
            </div>
            <div className="text-center p-4 bg-red-500/20 rounded-lg">
              <div className="text-2xl mb-2">🎯</div>
              <p className="text-white font-bold">Hunter</p>
              <p className="text-red-300 text-sm">Chase Master</p>
              <ul className="text-white/80 text-sm mt-2 space-y-1">
                <li>• Follow footprints</li>
                <li>• Catch the Escaper</li>
                <li>• Score by time</li>
              </ul>
            </div>
          </div>
        </div>
      )
    }
  ];

  const nextTourStep = () => {
    if (tourStep < tourSteps.length - 1) {
      setTourStep(tourStep + 1);
    } else {
      setShowTour(false);
    }
  };

  const prevTourStep = () => {
    if (tourStep > 0) {
      setTourStep(tourStep - 1);
    }
  };

  const skipTour = () => {
    setShowTour(false);
  };

  if (showTour) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="absolute inset-0 bg-black/50" />
        
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.9 }}
          className="relative z-10 w-full max-w-2xl"
        >
          <Card className="bg-slate-800 border border-slate-600 shadow-2xl">
            {/* Header */}
            <div className="px-6 py-4 border-b border-slate-600">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-slate-700 rounded-full flex items-center justify-center">
                    {tourSteps[tourStep].icon}
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-white">
                      {tourSteps[tourStep].title}
                    </h2>
                    <p className="text-slate-400 text-sm">
                      {tourSteps[tourStep].description}
                    </p>
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="text-lg font-bold text-blue-400">
                    {tourStep + 1}/{tourSteps.length}
                  </div>
                </div>
              </div>
            </div>
            
            {/* Content */}
            <div className="px-6 py-8">
              {tourSteps[tourStep].content}
            </div>
            
            {/* Footer */}
            <div className="px-6 py-4 border-t border-slate-600">
              {/* Progress Indicators */}
              <div className="flex justify-center gap-2 mb-4">
                {tourSteps.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setTourStep(index)}
                    className={`h-2 rounded-full transition-all duration-300 ${
                      index === tourStep
                        ? "bg-blue-400 w-8"
                        : index < tourStep
                        ? "bg-green-400 w-2"
                        : "bg-slate-600 w-2 hover:bg-slate-500"
                    }`}
                    aria-label={`Go to step ${index + 1}`}
                  />
                ))}
              </div>
              
              {/* Navigation Buttons */}
              <div className="flex justify-between items-center">
                <Button
                  variant="outline"
                  onClick={skipTour}
                  className="border-slate-600 text-slate-300 hover:bg-slate-700 hover:text-white"
                >
                  <SkipForward className="w-4 h-4 mr-2" />
                  Skip Tour
                </Button>
                
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    onClick={prevTourStep}
                    disabled={tourStep === 0}
                    className="border-slate-600 text-slate-300 hover:bg-slate-700 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <ArrowLeft className="w-4 h-4" />
                  </Button>
                  
                  <Button
                    onClick={nextTourStep}
                    className="bg-blue-600 hover:bg-blue-500 text-white border-0"
                  >
                    {tourStep === tourSteps.length - 1 ? (
                      <>
                        <Play className="w-4 h-4 mr-2" />
                        Start Playing!
                      </>
                    ) : (
                      <>
                        Next
                        <ArrowRight className="w-4 h-4 ml-2" />
                      </>
                    )}
                  </Button>
                </div>
              </div>
            </div>
          </Card>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-800 via-slate-900 to-slate-800 flex flex-col items-center justify-center p-4">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-20 left-20 w-32 h-32 bg-blue-400/10 rounded-full blur-xl animate-pulse" />
        <div className="absolute top-40 right-32 w-24 h-24 bg-purple-400/10 rounded-full blur-xl animate-pulse delay-1000" />
        <div className="absolute bottom-32 left-40 w-28 h-28 bg-green-400/10 rounded-full blur-xl animate-pulse delay-2000" />
      </div>

      <div className="relative z-10 w-full max-w-6xl mx-auto">
        {/* Main Title */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          <div className="flex items-center justify-center gap-3 mb-4">
            <Gamepad2 className="w-12 h-12 text-blue-400 animate-bounce" />
            <div
              className="text-6xl font-black bg-gradient-to-r from-blue-400 via-purple-400 to-green-400 bg-clip-text text-transparent"
              style={{ textShadow: "0 0 40px rgba(59,130,246,0.3)" }}
            >
              CHASE & ESCAPE
            </div>
            <Gamepad2 className="w-12 h-12 text-blue-400 animate-bounce delay-300" />
          </div>
          <p className="text-slate-300 text-lg font-medium">
            🎮 An Exciting Adventure Game for Everyone! 🎮
          </p>
          
          {/* Tour Button */}
          <Button
            onClick={() => setShowTour(true)}
            variant="outline"
            className="mt-4 border-slate-600 text-slate-300 hover:bg-slate-700 hover:text-white"
          >
            <Play className="w-4 h-4 mr-2" />
            Show Tour
          </Button>
        </motion.div>

        {/* Character Selection */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2, duration: 0.5 }}
          className="w-full max-w-4xl mx-auto"
        >
          <Card className="bg-slate-800/80 backdrop-blur-md border-2 border-slate-600 shadow-2xl">
            <CardHeader className="text-center pb-4">
              <CardTitle className="text-2xl text-white">
                🎭 Choose Your Character 🎭
              </CardTitle>
              <CardDescription className="text-slate-300 text-base">
                Pick your hero and start your adventure!
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6 p-6">
              {/* Role Selection */}
              <div className="grid md:grid-cols-2 gap-6">
                <motion.button
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  data-ocid="role.escaper_button"
                  onClick={() => setSelectedRole("escaper")}
                  className={`p-6 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                    selectedRole === "escaper"
                      ? "border-blue-500 bg-blue-500/20 shadow-xl shadow-blue-500/30"
                      : "border-slate-600 bg-slate-700/50 hover:border-slate-500 hover:bg-slate-700/70"
                  }`}
                  aria-pressed={selectedRole === "escaper"}
                  aria-label="Select Escaper character"
                >
                  {selectedRole === "escaper" && (
                    <div className="absolute top-2 right-2">
                      <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center" aria-label="Selected">
                        <span className="text-white text-lg">✓</span>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg shadow-blue-500/40">
                      <Zap className="w-8 h-8 text-white" />
                    </div>
                    <div>
                      <div className="font-bold text-xl text-white">🏃‍♂️ Escaper</div>
                      <Badge
                        variant="outline"
                        className="text-sm border-blue-400/40 text-blue-300 bg-blue-400/10"
                      >
                        Speed Hero
                      </Badge>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-yellow-500/20 rounded flex items-center justify-center text-yellow-400 text-sm" aria-hidden="true">🪙</div>
                      <span className="text-sm font-medium">Collect all 15 coins to WIN!</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-purple-500/20 rounded flex items-center justify-center text-purple-400 text-sm" aria-hidden="true">🌀</div>
                      <span className="text-sm font-medium">Drop magic decoys (5 seconds)</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-green-500/20 rounded flex items-center justify-center text-green-400 text-sm" aria-hidden="true">⏱</div>
                      <span className="text-sm font-medium">Survive 90 seconds to win</span>
                    </div>
                  </div>
                </motion.button>

                <motion.button
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  data-ocid="role.hunter_button"
                  onClick={() => setSelectedRole("hunter")}
                  className={`p-6 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-red-400 ${
                    selectedRole === "hunter"
                      ? "border-red-500 bg-red-500/20 shadow-xl shadow-red-500/30"
                      : "border-slate-600 bg-slate-700/50 hover:border-slate-500 hover:bg-slate-700/70"
                  }`}
                  aria-pressed={selectedRole === "hunter"}
                  aria-label="Select Hunter character"
                >
                  {selectedRole === "hunter" && (
                    <div className="absolute top-2 right-2">
                      <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center" aria-label="Selected">
                        <span className="text-white text-lg">✓</span>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-red-500 to-red-600 flex items-center justify-center shadow-lg shadow-red-500/40">
                      <Shield className="w-8 h-8 text-white" />
                    </div>
                    <div>
                      <div className="font-bold text-xl text-white">🎯 Hunter</div>
                      <Badge
                        variant="outline"
                        className="text-sm border-red-400/40 text-red-300 bg-red-400/10"
                      >
                        Chase Master
                      </Badge>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-cyan-500/20 rounded flex items-center justify-center text-cyan-400 text-sm" aria-hidden="true">👣</div>
                      <span className="text-sm font-medium">Follow fading footprints</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-orange-500/20 rounded flex items-center justify-center text-orange-400 text-sm" aria-hidden="true">🎯</div>
                      <span className="text-sm font-medium">Catch the Escaper to win</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-6 h-6 bg-pink-500/20 rounded flex items-center justify-center text-pink-400 text-sm" aria-hidden="true">🏆</div>
                      <span className="text-sm font-medium">Score based on time remaining</span>
                    </div>
                  </div>
                </motion.button>
              </div>

              {/* Name Input */}
              <div className="space-y-3">
                <label
                  htmlFor="player-name-input"
                  className="text-lg text-white font-medium flex items-center gap-2"
                >
                  <Heart className="w-5 h-5 text-red-400" />
                  Your Hero Name
                </label>
                <Input
                  id="player-name-input"
                  data-ocid="role.name_input"
                  value={playerName}
                  onChange={(e) => setPlayerName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleStart();
                  }}
                  placeholder="Enter your hero name..."
                  maxLength={20}
                  className="bg-slate-700/50 border-2 border-slate-600 text-white placeholder-slate-400 focus:border-blue-400 focus:bg-slate-700/70 text-lg h-12 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-400/50"
                  aria-required="true"
                  aria-describedby="name-help"
                />
                <p id="name-help" className="text-sm text-slate-400">
                  Choose a name that represents your hero!
                </p>
              </div>

              {/* Start Button */}
              <Button
                data-ocid="role.start_button"
                onClick={handleStart}
                disabled={!selectedRole || !playerName.trim()}
                className="w-full h-14 text-lg font-bold bg-gradient-to-r from-green-600 to-green-700 hover:from-green-500 hover:to-green-600 text-white border-0 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-lg transition-all duration-300 flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-green-400/50"
                aria-describedby="start-help"
              >
                {selectedRole ? (
                  <>
                    <Play className="w-5 h-5" />
                    {`Start Adventure as ${selectedRole === "escaper" ? "🏃‍♂️ Escaper" : "🎯 Hunter"}!`}
                    <Play className="w-5 h-5" />
                  </>
                ) : (
                  <>
                    <Gamepad2 className="w-5 h-5" />
                    Choose your hero first!
                    <Gamepad2 className="w-5 h-5" />
                  </>
                )}
              </Button>
              
              <p id="start-help" className="text-sm text-slate-400 text-center">
                {!selectedRole || !playerName.trim() 
                  ? "Select a character and enter your name to begin" 
                  : "Ready to start your adventure!"}
              </p>

              {/* Quick Tips */}
              <div className="bg-slate-700/30 rounded-lg p-4 border border-slate-600/50">
                <p className="text-slate-300 text-sm text-center">
                  💡 <span className="font-medium">Pro Tip:</span> Escapers can press <kbd className="px-2 py-1 bg-slate-600 rounded text-xs">SPACE</kbd> to drop decoys!
                </p>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}

// ========================
// HOOKS FOR BACKEND
// ========================
function useTopScores() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["topScores"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.getTopScores();
    },
    enabled: !!actor && !isFetching,
  });
}

function useSubmitScore() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      playerName,
      role,
      score,
    }: { playerName: string; role: string; score: number }) => {
      if (!actor) throw new Error("No actor");
      await actor.submitScore(playerName, role, BigInt(score));
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["topScores"] });
      toast.success("Score submitted to leaderboard!");
    },
    onError: () => {
      toast.error("Failed to submit score");
    },
  });
}

// ========================
// GAME OVER SCREEN
// ========================
interface GameOverProps {
  result: GameResult;
  playerRole: Role;
  playerName: string;
  onPlayAgain: () => void;
}

function GameOverScreen({
  result,
  playerRole,
  playerName,
  onPlayAgain,
}: GameOverProps) {
  const [submitted, setSubmitted] = useState(false);
  const { data: scores, isLoading: scoresLoading } = useTopScores();
  const submitScore = useSubmitScore();

  const playerWon = result.winner === playerRole;

  const handleSubmit = useCallback(() => {
    submitScore.mutate(
      {
        playerName,
        role: playerRole,
        score: result.score,
      },
      {
        onSuccess: () => setSubmitted(true),
      },
    );
  }, [submitScore, playerName, playerRole, result.score]);

  const resultMessage =
    result.winner === "escaper" && result.coinsCollected === NUM_COINS
      ? "The Escaper collected ALL coins!"
      : result.winner === "escaper"
        ? "The Escaper survived the full 90 seconds!"
        : `The Hunter caught the Escaper with ${result.timeRemaining.toFixed(1)}s remaining!`;

  return (
    <div className="min-h-screen bg-game-bg flex flex-col items-center justify-center p-6">
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", duration: 0.7 }}
        className="w-full max-w-2xl"
      >
        {/* Result Banner */}
        <div
          className={`text-center mb-6 p-6 rounded-2xl border ${
            playerWon
              ? "bg-green-500/10 border-green-500/30"
              : "bg-red-500/10 border-red-500/30"
          }`}
        >
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", delay: 0.2 }}
            className="text-6xl mb-3"
          >
            {playerWon
              ? result.coinsCollected === NUM_COINS
                ? "🌟"
                : "🏆"
              : "💀"}
          </motion.div>
          <h1
            className={`text-3xl font-black tracking-tight mb-1 ${
              playerWon ? "text-green-400" : "text-red-400"
            }`}
          >
            {playerWon ? "YOU WIN!" : "CAUGHT!"}
          </h1>
          <p className="text-slate-400">{resultMessage}</p>
        </div>

        <Tabs defaultValue="result">
          <TabsList className="w-full bg-slate-800/80 border border-slate-700 mb-4">
            <TabsTrigger
              value="result"
              className="flex-1 data-[state=active]:bg-slate-700"
            >
              Results
            </TabsTrigger>
            <TabsTrigger
              value="leaderboard"
              className="flex-1 data-[state=active]:bg-slate-700"
              data-ocid="leaderboard.tab"
            >
              <Trophy className="w-3.5 h-3.5 mr-1" /> Leaderboard
            </TabsTrigger>
            <TabsTrigger
              value="howtoplay"
              className="flex-1 data-[state=active]:bg-slate-700"
            >
              How to Play
            </TabsTrigger>
          </TabsList>

          <TabsContent value="result">
            <Card className="bg-slate-900/80 border-slate-700/60">
              <CardContent className="p-6 space-y-4">
                <div className="grid grid-cols-3 gap-4 text-center">
                  <div className="bg-slate-800/60 rounded-xl p-4">
                    <div className="text-2xl font-black text-yellow-400">
                      {result.score}
                    </div>
                    <div className="text-xs text-slate-400 mt-1">
                      Final Score
                    </div>
                  </div>
                  <div className="bg-slate-800/60 rounded-xl p-4">
                    <div className="text-2xl font-black text-amber-400">
                      {result.coinsCollected}
                    </div>
                    <div className="text-xs text-slate-400 mt-1">
                      Coins Collected
                    </div>
                  </div>
                  <div className="bg-slate-800/60 rounded-xl p-4">
                    <div className="text-2xl font-black text-cyan-400">
                      {result.timeRemaining.toFixed(1)}s
                    </div>
                    <div className="text-xs text-slate-400 mt-1">
                      Time Remaining
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 bg-slate-800/40 rounded-lg p-3">
                  <Badge
                    className={
                      playerRole === "escaper" ? "bg-blue-600" : "bg-red-700"
                    }
                  >
                    {playerRole === "escaper" ? "Escaper" : "Hunter"}
                  </Badge>
                  <span className="text-white font-semibold">{playerName}</span>
                  <span className="text-slate-400 ml-auto text-sm">
                    Score: {result.score}
                  </span>
                </div>

                <div className="flex gap-3">
                  {!submitted && (
                    <Button
                      data-ocid="gameover.submit_button"
                      onClick={handleSubmit}
                      disabled={submitScore.isPending}
                      className="flex-1 bg-yellow-600 hover:bg-yellow-500 text-white border-0"
                    >
                      {submitScore.isPending ? (
                        <>
                          <Loader2 className="w-4 h-4 mr-2 animate-spin" />{" "}
                          Submitting...
                        </>
                      ) : (
                        <>
                          <Trophy className="w-4 h-4 mr-2" /> Submit Score
                        </>
                      )}
                    </Button>
                  )}
                  {submitted && (
                    <div className="flex-1 text-center text-green-400 text-sm py-2 font-medium">
                      ✓ Score submitted!
                    </div>
                  )}
                  <Button
                    data-ocid="gameover.play_again_button"
                    onClick={onPlayAgain}
                    className="flex-1 bg-cyan-700 hover:bg-cyan-600 text-white border-0"
                  >
                    Play Again
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="leaderboard">
            <Card className="bg-slate-900/80 border-slate-700/60">
              <CardHeader className="pb-2">
                <CardTitle className="text-white text-base flex items-center gap-2">
                  <Trophy className="w-4 h-4 text-yellow-400" /> Top Scores
                </CardTitle>
              </CardHeader>
              <CardContent className="p-4">
                {scoresLoading ? (
                  <div
                    className="flex items-center justify-center py-8"
                    data-ocid="leaderboard.loading_state"
                  >
                    <Loader2 className="w-6 h-6 animate-spin text-cyan-400" />
                  </div>
                ) : scores && scores.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow className="border-slate-700">
                        <TableHead className="text-slate-400 w-10">#</TableHead>
                        <TableHead className="text-slate-400">Player</TableHead>
                        <TableHead className="text-slate-400">Role</TableHead>
                        <TableHead className="text-slate-400 text-right">
                          Score
                        </TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {scores.slice(0, 10).map((entry, i) => (
                        <TableRow
                          key={`${entry.playerName}-${i}`}
                          className="border-slate-700/50"
                          data-ocid={`leaderboard.item.${i + 1}`}
                        >
                          <TableCell className="text-slate-500 font-mono text-sm">
                            {i + 1}
                          </TableCell>
                          <TableCell className="text-white font-medium">
                            {entry.playerName}
                          </TableCell>
                          <TableCell>
                            <Badge
                              variant="outline"
                              className={
                                entry.role === "escaper"
                                  ? "border-blue-500/50 text-blue-400"
                                  : "border-red-500/50 text-red-400"
                              }
                            >
                              {entry.role}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-right font-mono font-bold text-yellow-400">
                            {Number(entry.score).toLocaleString()}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <div
                    className="text-center py-8 text-slate-500"
                    data-ocid="leaderboard.empty_state"
                  >
                    No scores yet. Be the first!
                  </div>
                )}
                <Button
                  data-ocid="gameover.play_again_button"
                  onClick={onPlayAgain}
                  className="w-full mt-4 bg-cyan-700 hover:bg-cyan-600 text-white border-0"
                >
                  Play Again
                </Button>
              </CardContent>
            </Card>
          </TabsContent>
          
          <TabsContent value="howtoplay">
            <Card className="bg-slate-900/80 border-slate-700/60">
              <CardHeader className="pb-2">
                <CardTitle className="text-white text-base">How to Play</CardTitle>
              </CardHeader>
              <CardContent className="p-6 space-y-4">
                <div className="space-y-4">
                  <div>
                    <h3 className="text-cyan-400 font-semibold mb-2">🎮 Controls</h3>
                    <ul className="text-sm text-slate-300 space-y-1">
                      <li>• <kbd className="bg-slate-700 px-2 py-1 rounded">WASD</kbd> or <kbd className="bg-slate-700 px-2 py-1 rounded">Arrow Keys</kbd> - Move your character</li>
                      <li>• <kbd className="bg-slate-700 px-2 py-1 rounded">Q</kbd> - Drop decoy (Escaper only)</li>
                    </ul>
                  </div>
                  
                  <div>
                    <h3 className="text-blue-400 font-semibold mb-2">🏃 Escaper Role</h3>
                    <ul className="text-sm text-slate-300 space-y-1">
                      <li>• Collect all 15 coins to win instantly</li>
                      <li>• Look for golden pulsing coins for bonus points (+25)</li>
                      <li>• Drop decoys to mislead the hunter (5s duration)</li>
                      <li>• Survive 90 seconds as an alternative win condition</li>
                    </ul>
                  </div>
                  
                  <div>
                    <h3 className="text-red-400 font-semibold mb-2">🎯 Hunter Role</h3>
                    <ul className="text-sm text-slate-300 space-y-1">
                      <li>• Follow the blue footprints left by the escaper</li>
                      <li>• Catch the escaper to win</li>
                      <li>• Be aware of decoys - they can distract you</li>
                      <li>• Score based on time remaining when you catch them</li>
                    </ul>
                  </div>
                  
                  <div>
                    <h3 className="text-yellow-400 font-semibold mb-2">🪙 Scoring System</h3>
                    <ul className="text-sm text-slate-300 space-y-1">
                      <li>• Regular coin: 10 points</li>
                      <li>• Bonus coin (golden with ★): 25 points</li>
                      <li>• Hunter win: Time remaining × 10 points</li>
                      <li>• Escaper survival bonus: Time remaining × 5 points</li>
                    </ul>
                  </div>
                  
                  <div>
                    <h3 className="text-green-400 font-semibold mb-2">💡 Tips</h3>
                    <ul className="text-sm text-slate-300 space-y-1">
                      <li>• Use decoys strategically to create escape routes</li>
                      <li>• The hunter AI randomly targets decoys or moves unpredictably</li>
                      <li>• Bonus coins change position every 8 seconds</li>
                      <li>• Plan your path to collect coins efficiently</li>
                    </ul>
                  </div>
                </div>
                
                <Button
                  onClick={onPlayAgain}
                  className="w-full mt-4 bg-cyan-700 hover:bg-cyan-600 text-white border-0"
                >
                  Play Again
                </Button>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </motion.div>
    </div>
  );
}

// ========================
// APP
// ========================
export default function App() {
  const [phase, setPhase] = useState<GamePhase>("role_select");
  const [playerRole, setPlayerRole] = useState<Role>("escaper");
  const [playerName, setPlayerName] = useState("");
  const [gameResult, setGameResult] = useState<GameResult | null>(null);

  const handleStart = useCallback((role: Role, name: string) => {
    setPlayerRole(role);
    setPlayerName(name);
    setGameResult(null);
    setPhase("playing");
  }, []);

  const handleGameOver = useCallback((result: GameResult) => {
    setGameResult(result);
    setPhase("game_over");
  }, []);

  const handlePlayAgain = useCallback(() => {
    setPhase("role_select");
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <Toaster richColors position="top-right" />
      <AnimatePresence mode="wait">
        {phase === "role_select" && (
          <motion.div
            key="role_select"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <RoleSelectScreen onStart={handleStart} />
          </motion.div>
        )}
        {phase === "playing" && (
          <motion.div
            key="playing"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-4"
          >
            <div className="mb-4 text-center">
              <h2 className="text-lg font-bold text-white">
                <span
                  className={
                    playerRole === "escaper" ? "text-blue-400" : "text-red-400"
                  }
                >
                  {playerRole === "escaper" ? "🏃 Escaper" : "🎯 Hunter"}
                </span>
                <span className="text-slate-400 text-sm ml-2">
                  — {playerName}
                </span>
              </h2>
            </div>
            <GameCanvas playerRole={playerRole} onGameOver={handleGameOver} />
          </motion.div>
        )}
        {phase === "game_over" && gameResult && (
          <motion.div
            key="game_over"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <GameOverScreen
              result={gameResult}
              playerRole={playerRole}
              playerName={playerName}
              onPlayAgain={handlePlayAgain}
            />
          </motion.div>
        )}
      </AnimatePresence>

    </div>
  );
}
