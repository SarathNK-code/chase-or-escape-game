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
import { Coins, Loader2, Shield, Timer, Trophy, Zap, Play, Gamepad2, Target, Sparkles, Heart, ArrowRight, ArrowLeft, X, SkipForward, BookOpen } from "lucide-react";
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
// MAP LAYOUTS (20 x 15)
// ========================
const MAPS: number[][][] = [
  // Level 1 - Original balanced map
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Level 2 - Spiral maze with center arena
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Level 3 - Cross pattern with quadrants
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Level 4 - Diamond pattern with diagonal paths
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Level 5 - Islands pattern with bridges
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1],
    [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
];

// Get current map based on level
function getCurrentMap(level: number): number[][] {
  return MAPS[(level - 1) % MAPS.length];
}

// ========================
// TYPES
// ========================
type Role = "escaper" | "hunter";
type GamePhase = "role_select" | "playing" | "level_transition" | "game_over";

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
  status: "playing" | "over" | "level_complete" | "respawning";
  result: GameResult | null;
  decoyIdCounter: number;
  bonusCoinIndex: number;
  lastBonusCoinChange: number;
  totalScore: number; // Track score with bonus coin points
  currentLevel: number;
  totalLevels: number;
  levelTransitionTimer: number;
  cumulativeScore: number;
  livesRemaining: number; // Escaper lives system
  respawnTimer: number; // 5-second respawn timer
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

function isWall(col: number, row: number, level: number = 1): boolean {
  if (col < 0 || col >= MAP_COLS || row < 0 || row >= MAP_ROWS) return true;
  const currentMap = getCurrentMap(level);
  return currentMap[row][col] === 1;
}

function isWallAt(x: number, y: number, level: number = 1): boolean {
  const r = PLAYER_RADIUS - 3;
  return [
    { x: x - r, y: y - r },
    { x: x + r, y: y - r },
    { x: x - r, y: y + r },
    { x: x + r, y: y + r },
  ].some((c) =>
    isWall(Math.floor(c.x / TILE_SIZE), Math.floor(c.y / TILE_SIZE), level),
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

function createInitialGameState(level: number = 1, totalLevels: number = 3): GameState {
  const currentMap = getCurrentMap(level);
  const floorTiles: Vec2[] = [];
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (currentMap[r][c] === 0) floorTiles.push(tileCenter(c, r));
    }
  }
  const escaperSpawn = tileCenter(1, 1);
  const hunterSpawn = tileCenter(18, 13);
  const coinCandidates = floorTiles.filter(
    (t) =>
      vecDist(t, escaperSpawn) > TILE_SIZE * 2.5 &&
      vecDist(t, hunterSpawn) > TILE_SIZE * 2.5,
  );
  
  // Level-specific difficulty adjustments
  const levelMultiplier = 1 + (level - 1) * 0.2; // 20% harder each level
  const adjustedNumCoins = Math.min(NUM_COINS + Math.floor((level - 1) * 2), 25); // More coins each level
  const adjustedGameDuration = Math.max(GAME_DURATION - (level - 1) * 10, 60); // Less time each level
  const adjustedAI_SPEED = Math.min(AI_SPEED + (level - 1) * 10, 180); // Faster AI each level
  const adjustedMAX_DECOYS = Math.max(MAX_DECOYS - Math.floor((level - 1) * 0.5), 1); // Fewer decoys each level
  
  const coins: Coin[] = shuffleArray(coinCandidates)
    .slice(0, adjustedNumCoins)
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
    timeRemaining: adjustedGameDuration,
    coinsCollected: 0,
    decoysRemaining: adjustedMAX_DECOYS,
    hunterTarget: { ...escaperSpawn },
    hunterTargetTimer: Math.max(AI_LAG_INTERVAL - (level - 1) * 100, 300), // Faster AI reaction
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
    currentLevel: level,
    totalLevels: totalLevels,
    levelTransitionTimer: 5,
    cumulativeScore: 0,
    livesRemaining: 3, // Start with 3 lives
    respawnTimer: 0, // Initialize respawn timer
  };
}

// ========================
// GAME LOGIC
// ========================
function moveEntity(entity: Entity, dx: number, dy: number, level: number = 1): void {
  const nx = entity.pos.x + dx;
  const ny = entity.pos.y + dy;
  if (!isWallAt(nx, entity.pos.y, level)) entity.pos.x = nx;
  if (!isWallAt(entity.pos.x, ny, level)) entity.pos.y = ny;
}

function updatePlayerMovement(
  entity: Entity,
  dt: number,
  keys: Set<string>,
  speed: number,
  level: number = 1,
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
    moveEntity(entity, dx, dy, level);
  }
}

function updateAIHunter(gs: GameState, dt: number): void {
  gs.hunterDistractTimer = Math.max(0, gs.hunterDistractTimer - dt * 1000);
  gs.hunterTargetTimer -= dt * 1000;
  
  // Level-specific AI speed
  const currentAISpeed = Math.min(AI_SPEED + (gs.currentLevel - 1) * 10, 180);
  
  if (gs.hunterTargetTimer <= 0) {
    gs.hunterTargetTimer = Math.max(AI_LAG_INTERVAL - (gs.currentLevel - 1) * 100, 300);
    
    // Check for blocks in all directions
    const hunterTile = {
      col: Math.floor(gs.hunter.pos.x / TILE_SIZE),
      row: Math.floor(gs.hunter.pos.y / TILE_SIZE)
    };
    const currentMap = getCurrentMap(gs.currentLevel);
    
    // Check if hunter is blocked in any direction
    const blockedDirections = {
      up: isWall(hunterTile.col, hunterTile.row - 1, gs.currentLevel),
      down: isWall(hunterTile.col, hunterTile.row + 1, gs.currentLevel),
      left: isWall(hunterTile.col - 1, hunterTile.row, gs.currentLevel),
      right: isWall(hunterTile.col + 1, hunterTile.row, gs.currentLevel)
    };
    
    // If hunter is blocked, immediately target escaper with aggressive pursuit
    if (blockedDirections.up || blockedDirections.down || blockedDirections.left || blockedDirections.right) {
      gs.hunterTarget = { ...gs.escaper.pos };
      gs.hunterTargetTimer = 200; // Faster reaction when blocked
      return;
    }
    
    // Intelligent hunting strategies
    const distance = vecDist(gs.hunter.pos, gs.escaper.pos);
    
    // Analyze escaper movement patterns
    const recentFootprints = gs.footprints.slice(-3); // Last 3 footprints
    let predictedPos = { ...gs.escaper.pos };
    
    if (recentFootprints.length >= 2) {
      // Predict escaper's next position based on movement
      const fp1 = recentFootprints[0];
      const fp2 = recentFootprints[recentFootprints.length - 1];
      const dx = fp2.x - fp1.x;
      const dy = fp2.y - fp1.y;
      const timeDiff = fp2.timestamp - fp1.timestamp;
      
      if (timeDiff > 0) {
        const velX = (dx / timeDiff) * 1000; // pixels per second
        const velY = (dy / timeDiff) * 1000;
        const predictionTime = 500; // Predict 500ms ahead
        predictedPos = {
          x: gs.escaper.pos.x + velX * predictionTime / 1000,
          y: gs.escaper.pos.y + velY * predictionTime / 1000
        };
      }
    }
    
    // Consider decoys vs escaper priority
    const decoyChance = Math.max(0.7 - (gs.currentLevel - 1) * 0.1, 0.3);
    
    if (gs.decoys.length > 0 && Math.random() < decoyChance && distance > 100) {
      // Check if decoys are strategically placed
      let bestDecoy: Decoy | null = null;
      let bestDecoyScore = -Infinity;
      
      for (const decoy of gs.decoys) {
        const decoyDist = vecDist(gs.hunter.pos, decoy);
        const escaperToDecoyDist = vecDist(gs.escaper.pos, decoy);
        
        // Score decoys based on proximity to escaper path and distance from us
        const score = (200 - decoyDist) + (escaperToDecoyDist * 0.3);
        if (score > bestDecoyScore) {
          bestDecoyScore = score;
          bestDecoy = decoy;
        }
      }
      
      if (bestDecoy) {
        gs.hunterTarget = { x: bestDecoy.x, y: bestDecoy.y };
        gs.hunterDistractTimer = 3000; // Shorter distraction on higher levels
      } else {
        gs.hunterTarget = { ...predictedPos };
      }
    } else {
      // Hunt escaper intelligently
      
      // Check for choke points and ambush opportunities
      const escaperTile = {
        col: Math.floor(gs.escaper.pos.x / TILE_SIZE),
        row: Math.floor(gs.escaper.pos.y / TILE_SIZE)
      };
      
      // Try to find interception point
      let interceptPoint = { ...predictedPos };
      
      if (distance < 200) {
        // Close range - direct pursuit with prediction
        interceptPoint = predictedPos;
      } else {
        // Long range - anticipate escaper's likely path
        const availableCoins = gs.coins.filter(c => !c.collected);
        
        if (availableCoins.length > 0) {
          // Predict which coin escaper will go for
          let targetCoin: Coin | null = null;
          let minHeuristic = Infinity;
          
          for (const coin of availableCoins) {
            const distToEscaper = vecDist(gs.escaper.pos, coin);
            const distToHunter = vecDist(gs.hunter.pos, coin);
            const timeForEscaper = distToEscaper / (PLAYER_SPEED * 0.88);
            const timeForHunter = distToHunter / currentAISpeed;
            
            // Can we intercept?
            if (timeForHunter < timeForEscaper * 1.2) {
              const heuristic = distToEscaper + (distToHunter * 0.5);
              if (heuristic < minHeuristic) {
                minHeuristic = heuristic;
                targetCoin = coin;
              }
            }
          }
          
          if (targetCoin) {
            interceptPoint = { x: targetCoin.x, y: targetCoin.y };
          } else {
            interceptPoint = predictedPos;
          }
        } else {
          interceptPoint = predictedPos;
        }
      }
      
      gs.hunterTarget = interceptPoint;
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
    const s = currentAISpeed * dt;
    gs.hunter.dir = Math.atan2(dy, dx);
    moveEntity(gs.hunter, (dx / d) * s, (dy / d) * s, gs.currentLevel);
  }
}

function updateAIEscaper(gs: GameState, dt: number): void {
  gs.escaperAITimer -= dt * 1000;
  if (gs.escaperAITimer <= 0) {
    gs.escaperAITimer = 400; // React faster on higher levels
    
    const dx = gs.escaper.pos.x - gs.hunter.pos.x;
    const dy = gs.escaper.pos.y - gs.hunter.pos.y;
    const distance = Math.sqrt(dx * dx + dy * dy);
    
    // Intelligent evasion strategies based on distance and situation
    let targetAngle: number;
    
    if (distance < 150) {
      // Hunter is close - aggressive evasion
      const hunterAngle = Math.atan2(dy, dx);
      
      // Check available escape routes
      const escapeRoutes: { angle: number; score: number }[] = [];
      for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 4) {
        const testX = gs.escaper.pos.x + Math.cos(angle) * 50;
        const testY = gs.escaper.pos.y + Math.sin(angle) * 50;
        if (!isWallAt(testX, testY, gs.currentLevel)) {
          const routeAngle = Math.atan2(testY - gs.hunter.pos.y, testX - gs.hunter.pos.x);
          const angleDiff = Math.abs(routeAngle - hunterAngle);
          escapeRoutes.push({ angle, score: angleDiff });
        }
      }
      
      if (escapeRoutes.length > 0) {
        // Choose route that maximizes distance from hunter
        escapeRoutes.sort((a, b) => b.score - a.score);
        targetAngle = escapeRoutes[0].angle;
      } else {
        // Cornered - move directly away
        targetAngle = hunterAngle;
      }
    } else if (distance < 250) {
      // Hunter is medium distance - tactical movement
      
      // Consider coin positions and hunter position
      const availableCoins = gs.coins.filter(c => !c.collected);
      let bestCoin: Coin | null = null;
      let bestScore = -Infinity;
      
      for (const coin of availableCoins) {
        const coinDist = vecDist(gs.escaper.pos, coin);
        const hunterToCoinDist = vecDist(gs.hunter.pos, coin);
        
        // Score coins based on distance from us and distance from hunter
        const score = (200 - coinDist) - (hunterToCoinDist * 0.5);
        if (score > bestScore) {
          bestScore = score;
          bestCoin = coin;
        }
      }
      
      if (bestCoin) {
        // Move toward best coin while avoiding hunter
        const coinAngle = Math.atan2(bestCoin.y - gs.escaper.pos.y, bestCoin.x - gs.escaper.pos.x);
        const hunterAngle = Math.atan2(dy, dx);
        
        // Blend coin direction with evasion
        targetAngle = coinAngle * 0.7 + hunterAngle * 0.3;
      } else {
        // No coins left, focus on evasion
        targetAngle = Math.atan2(dy, dx) + (Math.random() - 0.5) * Math.PI / 2;
      }
    } else {
      // Hunter is far - focus on coins with awareness
      const availableCoins = gs.coins.filter(c => !c.collected);
      if (availableCoins.length > 0) {
        // Find nearest safe coin
        let nearestCoin = availableCoins[0];
        let minDist = Infinity;
        
        for (const coin of availableCoins) {
          const dist = vecDist(gs.escaper.pos, coin);
          if (dist < minDist) {
            minDist = dist;
            nearestCoin = coin;
          }
        }
        
        targetAngle = Math.atan2(nearestCoin.y - gs.escaper.pos.y, nearestCoin.x - gs.escaper.pos.x);
      } else {
        // All coins collected, just evade
        targetAngle = Math.atan2(dy, dx) + (Math.random() - 0.5) * Math.PI / 3;
      }
    }
    
    // Add some unpredictability
    targetAngle += (Math.random() - 0.5) * 0.3;
    
    gs.escaperAIDir = { 
      x: Math.cos(targetAngle), 
      y: Math.sin(targetAngle) 
    };
  }
  
  // Apply movement with level-specific speed
  const speedMultiplier = 1 + (gs.currentLevel - 1) * 0.05; // Slightly faster on higher levels
  const s = PLAYER_SPEED * 0.88 * speedMultiplier * dt;
  gs.escaper.dir = Math.atan2(gs.escaperAIDir.y, gs.escaperAIDir.x);
  moveEntity(gs.escaper, gs.escaperAIDir.x * s, gs.escaperAIDir.y * s, gs.currentLevel);
}

function updateGame(
  gs: GameState,
  dt: number,
  playerRole: Role,
  keys: Set<string>,
): void {
  gs.frameCount++;
  
  // Handle respawn timer
  if (gs.status === "respawning") {
    gs.respawnTimer -= dt * 1000;
    if (gs.respawnTimer <= 0) {
      // Respawn escaper
      const currentMap = getCurrentMap(gs.currentLevel);
      const escaperSpawn = tileCenter(1, 1);
      gs.escaper.pos = { ...escaperSpawn };
      gs.escaper.dir = 0;
      gs.status = "playing";
      gs.respawnTimer = 0;
    }
    return;
  }
  
  gs.timeRemaining -= dt;
  if (gs.timeRemaining <= 0) {
    gs.timeRemaining = 0;
    gs.status = "over";
    gs.result = {
      winner: "escaper",
      score: gs.cumulativeScore + gs.totalScore,
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
    updatePlayerMovement(gs.escaper, dt, keys, PLAYER_SPEED, gs.currentLevel);
    updateAIHunter(gs, dt);
  } else {
    updatePlayerMovement(gs.hunter, dt, keys, PLAYER_SPEED, gs.currentLevel);
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
  // All coins collected — level complete!
  if (gs.coins.every((c) => c.collected)) {
    gs.cumulativeScore += gs.totalScore + Math.round(gs.timeRemaining * 5);
    if (gs.currentLevel >= gs.totalLevels) {
      // Game completed - all levels finished
      gs.status = "over";
      gs.result = {
        winner: "escaper",
        score: gs.cumulativeScore,
        coinsCollected: gs.coinsCollected,
        timeRemaining: gs.timeRemaining,
      };
    } else {
      // Level complete - transition to next level
      gs.status = "level_complete";
    }
    return;
  }
  // Catch detection
  if (vecDist(gs.escaper.pos, gs.hunter.pos) < CATCH_DISTANCE) {
    if (playerRole === "escaper") {
      // Escaper caught - lose a life
      gs.livesRemaining--;
      if (gs.livesRemaining <= 0) {
        // Game over - no lives left
        gs.status = "over";
        gs.result = {
          winner: "hunter",
          score: gs.cumulativeScore + Math.round(gs.timeRemaining * 10),
          coinsCollected: gs.coinsCollected,
          timeRemaining: gs.timeRemaining,
        };
      } else {
        // Start respawn timer
        gs.status = "respawning";
        gs.respawnTimer = 5; // 5 seconds to respawn
      }
    } else {
      // Hunter wins - game over immediately
      gs.status = "over";
      gs.result = {
        winner: "hunter",
        score: gs.cumulativeScore + Math.round(gs.timeRemaining * 10),
        coinsCollected: gs.coinsCollected,
        timeRemaining: gs.timeRemaining,
      };
    }
  }
}

// ========================
// RENDERING
// ========================
function renderGame(ctx: CanvasRenderingContext2D, gs: GameState): void {
  const now = Date.now();
  const currentMap = getCurrentMap(gs.currentLevel);
  // Background - Modern gradient
  const gradient = ctx.createLinearGradient(0, 0, 0, CANVAS_H);
  gradient.addColorStop(0, '#0f172a');
  gradient.addColorStop(1, '#1e293b');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  
  // Grid lines - Subtle modern look
  ctx.strokeStyle = '#334155';
  ctx.lineWidth = 0.5;
  ctx.globalAlpha = 0.3;
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
  ctx.globalAlpha = 1;
  
  // Walls - Modern elevated look
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (currentMap[r][c] === 1) {
        // Wall gradient
        const wallGradient = ctx.createLinearGradient(
          c * TILE_SIZE, r * TILE_SIZE,
          c * TILE_SIZE, (r + 1) * TILE_SIZE
        );
        wallGradient.addColorStop(0, '#475569');
        wallGradient.addColorStop(1, '#1e293b');
        ctx.fillStyle = wallGradient;
        ctx.fillRect(c * TILE_SIZE, r * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        
        // Modern border
        ctx.strokeStyle = '#64748b';
        ctx.lineWidth = 2;
        ctx.strokeRect(
          c * TILE_SIZE + 1,
          r * TILE_SIZE + 1,
          TILE_SIZE - 2,
          TILE_SIZE - 2,
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
  // Coins - Modern golden look
  for (const coin of gs.coins) {
    if (!coin.collected) {
      const availableCoins = gs.coins.filter(c => !c.collected);
      const currentBonusCoin = availableCoins[gs.bonusCoinIndex];
      const isCurrentBonus = currentBonusCoin && currentBonusCoin.x === coin.x && currentBonusCoin.y === coin.y;
      
      ctx.save();
      
      if (isCurrentBonus) {
        // Bonus coin - Enhanced golden effect
        const pulse = Math.sin(now * 0.006) * 0.3 + 0.7;
        ctx.shadowBlur = 30 + pulse * 15;
        ctx.shadowColor = '#fbbf24';
        
        const bonusGradient = ctx.createRadialGradient(coin.x, coin.y, 0, 0, 0, COIN_RADIUS * (1 + pulse * 0.3));
        bonusGradient.addColorStop(0, '#fde047');
        bonusGradient.addColorStop(0.5, '#f59e0b');
        bonusGradient.addColorStop(1, '#d97706');
        
        ctx.beginPath();
        ctx.arc(coin.x, coin.y, COIN_RADIUS * (1 + pulse * 0.3), 0, Math.PI * 2);
        ctx.fillStyle = bonusGradient;
        ctx.fill();
        
        // Inner glow ring
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(coin.x, coin.y, COIN_RADIUS * (1 + pulse * 0.3) + 3, 0, Math.PI * 2);
        ctx.stroke();
        
        // Star symbol
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 10px Arial';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('★', coin.x, coin.y);
      } else {
        // Regular coin - Modern metallic look
        ctx.shadowBlur = 15;
        ctx.shadowColor = '#fbbf24';
        
        const coinGradient = ctx.createRadialGradient(coin.x, coin.y, 0, 0, 0, COIN_RADIUS);
        coinGradient.addColorStop(0, '#fde047');
        coinGradient.addColorStop(0.7, '#f59e0b');
        coinGradient.addColorStop(1, '#d97706');
        
        ctx.beginPath();
        ctx.arc(coin.x, coin.y, COIN_RADIUS, 0, Math.PI * 2);
        ctx.fillStyle = coinGradient;
        ctx.fill();
        
        // Modern border
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 2;
        ctx.shadowBlur = 0;
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
  // Escaper - Modern blue with glow
  {
    const e = gs.escaper;
    ctx.save();
    ctx.translate(e.pos.x, e.pos.y);
    
    // Glow effect
    ctx.shadowBlur = 20;
    ctx.shadowColor = '#3b82f6';
    
    // Gradient fill
    const escaperGradient = ctx.createRadialGradient(0, 0, 0, 0, 0, PLAYER_RADIUS);
    escaperGradient.addColorStop(0, '#60a5fa');
    escaperGradient.addColorStop(1, '#2563eb');
    
    ctx.beginPath();
    ctx.arc(0, 0, PLAYER_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = escaperGradient;
    ctx.fill();
    
    // Modern border
    ctx.strokeStyle = '#93c5fd';
    ctx.lineWidth = 3;
    ctx.shadowBlur = 0;
    ctx.stroke();
    
    // Direction indicator
    ctx.strokeStyle = '#dbeafe';
    ctx.lineWidth = 2;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(Math.cos(e.dir) * 12, Math.sin(e.dir) * 12);
    ctx.stroke();
    
    ctx.restore();
  }
  // Hunter - Modern red with aggressive look
  {
    const h = gs.hunter;
    ctx.save();
    ctx.translate(h.pos.x, h.pos.y);
    
    // Aggressive glow
    ctx.shadowBlur = 25;
    ctx.shadowColor = '#ef4444';
    
    // Gradient fill
    const hunterGradient = ctx.createRadialGradient(0, 0, 0, 0, 0, PLAYER_RADIUS);
    hunterGradient.addColorStop(0, '#dc2626');
    hunterGradient.addColorStop(1, '#991b1b');
    
    ctx.beginPath();
    ctx.arc(0, 0, PLAYER_RADIUS, 0, Math.PI * 2);
    ctx.fillStyle = hunterGradient;
    ctx.fill();
    
    // Modern border
    ctx.strokeStyle = '#fca5a5';
    ctx.lineWidth = 3;
    ctx.shadowBlur = 0;
    ctx.stroke();
    
    // Eyes - more menacing
    const ex = Math.cos(h.dir) * 6;
    const ey = Math.sin(h.dir) * 6;
    const px = -Math.sin(h.dir) * 3.5;
    const py = Math.cos(h.dir) * 3.5;
    
    ctx.fillStyle = '#fecaca';
    ctx.beginPath();
    ctx.arc(ex + px, ey + py, 2.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(ex - px, ey - py, 2.5, 0, Math.PI * 2);
    ctx.fill();
    
    ctx.restore();
  }
  // HUD - Modern glassmorphism with lives display
  ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
  ctx.fillRect(0, 0, CANVAS_W, 56);
  
  // HUD border
  ctx.strokeStyle = 'rgba(59, 130, 246, 0.5)';
  ctx.lineWidth = 1;
  ctx.strokeRect(0, 0, CANVAS_W, 56);
  
  ctx.font = 'bold 20px "JetBrains Mono", monospace';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const tc =
    gs.timeRemaining <= 10
      ? '#ef4444'
      : gs.timeRemaining <= 30
        ? '#f59e0b'
        : '#10b981';
  ctx.fillStyle = tc;
  const mm = Math.floor(gs.timeRemaining / 60);
  const ss = Math.floor(gs.timeRemaining % 60);
  ctx.fillText(`${mm}:${ss.toString().padStart(2, "0")}`, CANVAS_W / 2, 18);
  
  // Level information - Modern styling
  ctx.font = 'bold 14px "JetBrains Mono", monospace';
  ctx.fillStyle = '#8b5cf6';
  ctx.fillText(`Level ${gs.currentLevel}/${gs.totalLevels}`, CANVAS_W / 2, 38);
  
  // Lives display - Heart icons
  ctx.font = 'bold 16px Arial';
  ctx.fillStyle = '#ef4444';
  ctx.textAlign = 'left';
  ctx.fillText('Lives:', 12, 18);
  
  // Draw heart icons for lives
  for (let i = 0; i < 3; i++) {
    const x = 70 + i * 25;
    const y = 18;
    
    if (i < gs.livesRemaining) {
      // Full heart
      ctx.fillStyle = '#ef4444';
      ctx.fillText('❤️', x, y);
    } else {
      // Empty heart
      ctx.fillStyle = '#64748b';
      ctx.fillText('🤍', x, y);
    }
  }
  
  // Respawn timer display
  if (gs.status === 'respawning') {
    ctx.font = 'bold 18px "JetBrains Mono", monospace';
    ctx.fillStyle = '#f59e0b';
    ctx.textAlign = 'center';
    ctx.fillText(`Respawning in ${Math.ceil(gs.respawnTimer)}...`, CANVAS_W / 2, CANVAS_H / 2);
  }
  
  ctx.textAlign = 'left';
  ctx.font = 'bold 13px "JetBrains Mono", monospace';
  ctx.fillStyle = '#f59e0b';
  ctx.fillText(`SCORE: ${gs.cumulativeScore + gs.totalScore}`, 12, 38);
  ctx.fillStyle = '#06b6d4';
  ctx.fillText(`DECOYS[SPACE]: ${gs.decoysRemaining}`, 12, 58);
  ctx.textAlign = 'right';
  ctx.fillStyle = '#3b82f6';
  ctx.fillText(
    `COINS: ${gs.coins.filter((c) => !c.collected).length} left`,
    CANVAS_W - 12,
    18,
  );
}

// ========================
// LEVEL TRANSITION COMPONENT
// ========================
interface LevelTransitionProps {
  level: number;
  totalLevels: number;
  score: number;
  onComplete: () => void;
}

function LevelTransition({ level, totalLevels, score, onComplete }: LevelTransitionProps) {
  const [countdown, setCountdown] = useState(5);
  const [isComplete, setIsComplete] = useState(false);

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => {
        setCountdown(countdown - 1);
      }, 1000);
      return () => clearTimeout(timer);
    } else if (!isComplete) {
      setIsComplete(true);
      setTimeout(() => {
        onComplete();
      }, 500);
    }
  }, [countdown, isComplete, onComplete]);

  return (
    <div className="absolute inset-0 bg-slate-900/95 flex items-center justify-center z-50">
      <motion.div
        initial={{ scale: 0.5, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", duration: 0.6 }}
        className="text-center"
      >
        <div className="mb-8">
          <motion.div
            initial={{ rotateY: 0 }}
            animate={{ rotateY: 360 }}
            transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
            className="text-6xl mb-4"
          >
            🌟
          </motion.div>
          <h2 className="text-4xl font-black text-white mb-2">
            Level {level} Complete!
          </h2>
          <p className="text-xl text-slate-300 mb-4">
            Score: {score} points
          </p>
          {level < totalLevels && (
            <p className="text-lg text-purple-400">
              Get ready for Level {level + 1}...
            </p>
          )}
        </div>

        <div className="relative w-32 h-32 mx-auto mb-6">
          <svg className="transform -rotate-90 w-32 h-32">
            <circle
              cx="64"
              cy="64"
              r="56"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-slate-700"
            />
            <motion.circle
              cx="64"
              cy="64"
              r="56"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-purple-400"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: (5 - countdown) / 5 }}
              transition={{ duration: 1, ease: "easeInOut" }}
              style={{
                pathLength: (5 - countdown) / 5,
              }}
              strokeLinecap="round"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <motion.div
              key={countdown}
              initial={{ scale: 0.5, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 1.5, opacity: 0 }}
              className="text-4xl font-black text-white"
            >
              {countdown}
            </motion.div>
          </div>
        </div>

        {isComplete && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-lg text-green-400 font-semibold"
          >
            Starting Level {level + 1}...
          </motion.div>
        )}
      </motion.div>
    </div>
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
  const gsRef = useRef<GameState>(createInitialGameState(1, 5));
  const keysRef = useRef<Set<string>>(new Set());
  const rafRef = useRef<number>(0);
  const lastTimeRef = useRef<number>(0);
  const onGameOverRef = useRef(onGameOver);
  const [showLevelTransition, setShowLevelTransition] = useState(false);
  const [levelTransitionData, setLevelTransitionData] = useState<{
    level: number;
    totalLevels: number;
    score: number;
  } | null>(null);

  useEffect(() => {
    onGameOverRef.current = onGameOver;
  }, [onGameOver]);

  const startNextLevel = useCallback(() => {
    const gs = gsRef.current;
    const nextLevel = gs.currentLevel + 1;
    const newGs = createInitialGameState(nextLevel, gs.totalLevels);
    newGs.cumulativeScore = gs.cumulativeScore;
    newGs.livesRemaining = gs.livesRemaining; // Preserve lives between levels
    gsRef.current = newGs;
    setShowLevelTransition(false);
    setLevelTransitionData(null);
    lastTimeRef.current = 0;
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      keysRef.current.add(e.key.toLowerCase());
      if (e.key === " " && playerRole === "escaper") {
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
    const gs = gsRef.current;
    // Reset game state properly for new game
    if (gs.status === "over" && gs.result) {
      onGameOverRef.current(gs.result);
      return;
    }
    
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
      
      if (gs.status === "playing" || gs.status === "respawning") {
        updateGame(gs, dt, playerRole, keysRef.current);
      }
      
      if (gs.status === "level_complete" && !showLevelTransition) {
        setLevelTransitionData({
          level: gs.currentLevel,
          totalLevels: gs.totalLevels,
          score: gs.totalScore + Math.round(gs.timeRemaining * 5),
        });
        setShowLevelTransition(true);
      }
      
      if (gs.status === "over" && gs.result) {
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
  }, [playerRole, showLevelTransition]);

  return (
    <div className="relative flex flex-col items-center justify-center min-h-screen w-full">
      {showLevelTransition && levelTransitionData && (
        <LevelTransition
          level={levelTransitionData.level}
          totalLevels={levelTransitionData.totalLevels}
          score={levelTransitionData.score}
          onComplete={startNextLevel}
        />
      )}
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
          <span className="text-cyan-400">● Decoys [SPACE] (5s)</span>
          <span>WASD / Arrow Keys to move</span>
        </div>
      </div>
    </div>
  );
}

// ========================
// ROLE SELECT SCREEN
// ========================
interface RoleSelectProps {
  onStart: (role: Role, name: string) => void;
  showTour: boolean;
  onTourComplete?: () => void;
}

  function RoleSelectScreen({ onStart, showTour, onTourComplete }: RoleSelectProps) {
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);
  const [playerName, setPlayerName] = useState("");
  const [tourStep, setTourStep] = useState(0);

  const handleStart = () => {
    if (selectedRole && playerName.trim()) {
      onStart(selectedRole, playerName.trim());
    }
  };

  const tourSteps = [
    {
      title: "Welcome to Chase or Escape!",
      description: "Choose your hero and complete your mission!",
      icon: <Gamepad2 className="w-16 h-16 text-blue-400" />,
      content: (
        <div className="text-center space-y-2">
          <p className="text-white text-sm">Be fast, smart, and quick to win!</p>
          <div className="flex justify-center gap-3">
            <div className="text-center">
              <div className="text-lg mb-1">🏃‍♂️</div>
              <p className="text-blue-300 text-xs">Be Fast</p>
            </div>
            <div className="text-center">
              <div className="text-lg mb-1">🎯</div>
              <p className="text-red-300 text-xs">Be Smart</p>
            </div>
            <div className="text-center">
              <div className="text-lg mb-1">⏱</div>
              <p className="text-yellow-300 text-xs">Be Quick</p>
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
        <div className="space-y-2">
          <div className="grid grid-cols-1 gap-2">
            <div className="flex items-center gap-2">
              <Timer className="w-5 h-5 text-green-400" />
              <div>
                <p className="text-white font-semibold text-xs">90 Seconds Timer</p>
                <p className="text-white/70 text-xs">Complete before time runs out!</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Coins className="w-5 h-5 text-yellow-400" />
              <div>
                <p className="text-white font-semibold text-xs">15 Magic Coins</p>
                <p className="text-white/70 text-xs">Escapers collect all coins to win!</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Target className="w-5 h-5 text-purple-400" />
              <div>
                <p className="text-white font-semibold text-xs">Smart AI Opponent</p>
                <p className="text-white/70 text-xs">Face intelligent computer opponent!</p>
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
        <div className="space-y-2">
          <div className="grid grid-cols-2 gap-3">
            <div className="text-center">
              <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center mx-auto mb-1">
                <span className="text-white font-bold text-xs">↑↓←→</span>
              </div>
              <p className="text-white font-semibold text-xs">Arrow Keys</p>
              <p className="text-white/70 text-xs">Move character</p>
            </div>
            <div className="text-center">
              <div className="w-8 h-8 bg-purple-500 rounded-lg flex items-center justify-center mx-auto mb-1">
                <span className="text-white font-bold text-xs">SPACE</span>
              </div>
              <p className="text-white font-semibold text-xs">Space Bar</p>
              <p className="text-white/70 text-xs">Drop decoys</p>
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
        <div className="space-y-2">
          <div className="grid grid-cols-2 gap-3">
            <div className="text-center p-2 bg-blue-500/20 rounded-lg">
              <div className="text-lg mb-1">🏃‍♂️</div>
              <p className="text-white font-bold text-xs">Escaper</p>
              <p className="text-blue-300 text-xs">Speed Hero</p>
              <ul className="text-white/80 text-xs mt-1 space-y-0">
                <li>• Collect 15 coins</li>
                <li>• Drop decoys</li>
                <li>• Survive 90s</li>
              </ul>
            </div>
            <div className="text-center p-2 bg-red-500/20 rounded-lg">
              <div className="text-lg mb-1">🎯</div>
              <p className="text-white font-bold text-xs">Hunter</p>
              <p className="text-red-300 text-xs">Chase Master</p>
              <ul className="text-white/80 text-xs mt-1 space-y-0">
                <li>• Follow footprints</li>
                <li>• Catch Escaper</li>
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
      // Tour completed - notify parent to show main page
      if (onTourComplete) {
        onTourComplete();
      }
    }
  };

  const prevTourStep = () => {
    if (tourStep > 0) {
      setTourStep(tourStep - 1);
    }
  };

  const skipTour = () => {
    // Tour is now controlled by parent component
    if (onTourComplete) {
      onTourComplete();
    }
  };

  if (showTour) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="absolute inset-0 bg-black/50" />
        
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.9 }}
          className="relative z-10 w-full max-w-2xl h-[400px] flex flex-col"
        >
          <Card className="bg-slate-800 border border-slate-600 shadow-2xl flex flex-col h-full">
            {/* Fixed Header */}
            <div className="px-6 py-4 border-b border-slate-600 flex-shrink-0">
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
            
            {/* Content Area - No Scrolling */}
            <div className="flex-1 px-6 py-4 overflow-hidden">
              {tourSteps[tourStep].content}
            </div>
            
            {/* Fixed Footer */}
            <div className="px-6 py-4 border-t border-slate-600 flex-shrink-0">
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
              
              {/* Navigation Buttons - Fixed Position */}
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

      <div className="relative z-10 w-full max-w-2xl mx-auto">
        {/* Main Title */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-6"
        >
          <div className="flex items-center justify-center gap-3 mb-3">
            <Gamepad2 className="w-10 h-10 text-blue-400 animate-bounce" />
            <div
              className="text-4xl font-black bg-gradient-to-r from-blue-400 via-purple-400 to-green-400 bg-clip-text text-transparent"
              style={{ textShadow: "0 0 40px rgba(59,130,246,0.3)" }}
            >
              CHASE OR ESCAPE
            </div>
            <Gamepad2 className="w-10 h-10 text-blue-400 animate-bounce delay-300" />
          </div>
          <p className="text-slate-300 text-base font-medium">
            🎮 An Exciting Adventure Game for Everyone! 🎮
          </p>
          
          {/* Tour Button */}
          <Button
            variant="outline"
            className="mt-3 border-slate-600 text-slate-300 hover:bg-slate-700 hover:text-white"
          >
            <BookOpen className="w-4 h-4 mr-2" />
            Tour Completed
          </Button>
        </motion.div>

        {/* Character Selection */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2, duration: 0.5 }}
          className="w-full max-w-2xl mx-auto"
        >
          <Card className="bg-slate-800/80 backdrop-blur-md border-2 border-slate-600 shadow-2xl">
            <CardHeader className="text-center pb-3">
              <CardTitle className="text-xl text-white">
                🎭 Choose Your Character 🎭
              </CardTitle>
              <CardDescription className="text-slate-300 text-sm">
                Pick your hero and start your adventure!
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 p-4">
              {/* Role Selection */}
              <div className="grid md:grid-cols-2 gap-4">
                <motion.button
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  data-ocid="role.escaper_button"
                  onClick={() => setSelectedRole("escaper")}
                  className={`p-4 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                    selectedRole === "escaper"
                      ? "border-blue-500 bg-blue-500/20 shadow-xl shadow-blue-500/30"
                      : "border-slate-600 bg-slate-700/50 hover:border-slate-500 hover:bg-slate-700/70"
                  }`}
                  aria-pressed={selectedRole === "escaper"}
                  aria-label="Select Escaper character"
                >
                  {selectedRole === "escaper" && (
                    <div className="absolute top-2 right-2">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center" aria-label="Selected">
                        <span className="text-white text-sm">✓</span>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg shadow-blue-500/40">
                      <Zap className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <div className="font-bold text-lg text-white">🏃‍♂️ Escaper</div>
                      <Badge
                        variant="outline"
                        className="text-xs border-blue-400/40 text-blue-300 bg-blue-400/10"
                      >
                        Speed Hero
                      </Badge>
                    </div>
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-yellow-500/20 rounded flex items-center justify-center text-yellow-400 text-xs" aria-hidden="true">🪙</div>
                      <span className="text-xs font-medium">Collect all 15 coins to WIN!</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-purple-500/20 rounded flex items-center justify-center text-purple-400 text-xs" aria-hidden="true">🌀</div>
                      <span className="text-xs font-medium">Drop magic decoys (5 seconds)</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-green-500/20 rounded flex items-center justify-center text-green-400 text-xs" aria-hidden="true">⏱</div>
                      <span className="text-xs font-medium">Survive 90 seconds to win</span>
                    </div>
                  </div>
                </motion.button>

                <motion.button
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  data-ocid="role.hunter_button"
                  onClick={() => setSelectedRole("hunter")}
                  className={`p-4 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-red-400 ${
                    selectedRole === "hunter"
                      ? "border-red-500 bg-red-500/20 shadow-xl shadow-red-500/30"
                      : "border-slate-600 bg-slate-700/50 hover:border-slate-500 hover:bg-slate-700/70"
                  }`}
                  aria-pressed={selectedRole === "hunter"}
                  aria-label="Select Hunter character"
                >
                  {selectedRole === "hunter" && (
                    <div className="absolute top-2 right-2">
                      <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center" aria-label="Selected">
                        <span className="text-white text-sm">✓</span>
                      </div>
                    </div>
                  )}
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-red-500 to-red-600 flex items-center justify-center shadow-lg shadow-red-500/40">
                      <Shield className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <div className="font-bold text-lg text-white">🎯 Hunter</div>
                      <Badge
                        variant="outline"
                        className="text-xs border-red-400/40 text-red-300 bg-red-400/10"
                      >
                        Chase Master
                      </Badge>
                    </div>
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-cyan-500/20 rounded flex items-center justify-center text-cyan-400 text-xs" aria-hidden="true">👣</div>
                      <span className="text-xs font-medium">Follow fading footprints</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-orange-500/20 rounded flex items-center justify-center text-orange-400 text-xs" aria-hidden="true">🎯</div>
                      <span className="text-xs font-medium">Catch the Escaper to win</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <div className="w-4 h-4 bg-pink-500/20 rounded flex items-center justify-center text-pink-400 text-xs" aria-hidden="true">🏆</div>
                      <span className="text-xs font-medium">Score based on time remaining</span>
                    </div>
                  </div>
                </motion.button>
              </div>

              {/* Name Input */}
              <div className="space-y-2">
                <label
                  htmlFor="player-name-input"
                  className="text-sm text-white font-medium flex items-center gap-2"
                >
                  <Heart className="w-4 h-4 text-red-400" />
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
                  className="bg-slate-700/50 border-2 border-slate-600 text-white placeholder-slate-400 focus:border-blue-400 focus:bg-slate-700/70 text-sm h-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-400/50"
                  aria-required="true"
                  aria-describedby="name-help"
                />
                <p id="name-help" className="text-xs text-slate-400">
                  Choose a name that represents your hero!
                </p>
              </div>

              {/* Start Button */}
              <Button
                data-ocid="role.start_button"
                onClick={handleStart}
                disabled={!selectedRole || !playerName.trim()}
                className="w-full h-12 text-base font-bold bg-gradient-to-r from-green-600 to-green-700 hover:from-green-500 hover:to-green-600 text-white border-0 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-lg transition-all duration-300 flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-green-400/50"
                aria-describedby="start-help"
              >
                {selectedRole ? (
                  <>
                    <Play className="w-4 h-4" />
                    {`Start Adventure as ${selectedRole === "escaper" ? "🏃‍♂️ Escaper" : "🎯 Hunter"}!`}
                    <Play className="w-4 h-4" />
                  </>
                ) : (
                  <>
                    <Gamepad2 className="w-4 h-4" />
                    Choose your hero first!
                    <Gamepad2 className="w-4 h-4" />
                  </>
                )}
              </Button>
              
              <p id="start-help" className="text-xs text-slate-400 text-center">
                {!selectedRole || !playerName.trim() 
                  ? "Select a character and enter your name to begin" 
                  : "Ready to start your adventure!"}
              </p>

              {/* Quick Tips */}
              <div className="bg-slate-700/30 rounded-lg p-3 border border-slate-600/50">
                <p className="text-slate-300 text-xs text-center">
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
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", duration: 0.7 }}
        className="relative z-10 w-full max-w-2xl h-[400px] flex flex-col"
      >
        <Card className="bg-slate-800 border border-slate-600 shadow-2xl flex flex-col h-full">
          {/* Fixed Header */}
          <div className="px-6 py-4 border-b border-slate-600 flex-shrink-0">
            <div className="text-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", delay: 0.2 }}
                className="text-4xl mb-2"
              >
                {playerWon
                  ? result.coinsCollected === NUM_COINS
                    ? "🌟"
                    : "🏆"
                  : "💀"}
              </motion.div>
              <h1
                className={`text-2xl font-black tracking-tight mb-1 ${
                  playerWon ? "text-green-400" : "text-red-400"
                }`}
              >
                {playerWon ? "YOU WIN!" : "CAUGHT!"}
              </h1>
              <p className="text-slate-400 text-sm">{resultMessage}</p>
            </div>
          </div>
          
          {/* Content Area - No Scrolling */}
          <div className="flex-1 px-6 py-4 overflow-hidden">
            <Tabs defaultValue="result">
              <TabsList className="w-full bg-slate-700/80 border border-slate-600 mb-3">
                <TabsTrigger
                  value="result"
                  className="flex-1 data-[state=active]:bg-slate-600 text-xs"
                >
                  Results
                </TabsTrigger>
                <TabsTrigger
                  value="leaderboard"
                  className="flex-1 data-[state=active]:bg-slate-600 text-xs"
                  data-ocid="leaderboard.tab"
                >
                  <Trophy className="w-3 h-3 mr-1" /> Leaderboard
                </TabsTrigger>
                <TabsTrigger
                  value="howtoplay"
                  className="flex-1 data-[state=active]:bg-slate-600 text-xs"
                >
                  How to Play
                </TabsTrigger>
              </TabsList>

              <TabsContent value="result" className="mt-0">
                <div className="space-y-3">
                  <div className="grid grid-cols-3 gap-2 text-center">
                    <div className="bg-slate-700/60 rounded-lg p-2">
                      <div className="text-lg font-black text-yellow-400">
                        {result.score}
                      </div>
                      <div className="text-xs text-slate-400">
                        Score
                      </div>
                    </div>
                    <div className="bg-slate-700/60 rounded-lg p-2">
                      <div className="text-lg font-black text-amber-400">
                        {result.coinsCollected}
                      </div>
                      <div className="text-xs text-slate-400">
                        Coins
                      </div>
                    </div>
                    <div className="bg-slate-700/60 rounded-lg p-2">
                      <div className="text-lg font-black text-cyan-400">
                        {result.timeRemaining.toFixed(1)}s
                      </div>
                      <div className="text-xs text-slate-400">
                        Time
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 bg-slate-700/40 rounded-lg p-2">
                    <Badge
                      className={`text-xs ${
                        playerRole === "escaper" ? "bg-blue-600" : "bg-red-700"
                      }`}
                    >
                      {playerRole === "escaper" ? "Escaper" : "Hunter"}
                    </Badge>
                    <span className="text-white text-sm font-medium">{playerName}</span>
                  </div>

                  <div className="flex gap-2">
                    {!submitted && (
                      <Button
                        data-ocid="gameover.submit_button"
                        onClick={handleSubmit}
                        disabled={submitScore.isPending}
                        className="flex-1 bg-yellow-600 hover:bg-yellow-500 text-white border-0 text-xs h-8"
                      >
                        {submitScore.isPending ? (
                          <>
                            <Loader2 className="w-3 h-3 mr-1 animate-spin" /> Submitting...
                          </>
                        ) : (
                          <>
                            <Trophy className="w-3 h-3 mr-1" /> Submit Score
                          </>
                        )}
                      </Button>
                    )}
                    {submitted && (
                      <div className="flex-1 text-center text-green-400 text-xs py-1 font-medium">
                        ✓ Score submitted!
                      </div>
                    )}
                    <Button
                      data-ocid="gameover.play_again_button"
                      onClick={onPlayAgain}
                      className="flex-1 bg-cyan-700 hover:bg-cyan-600 text-white border-0 text-xs h-8"
                    >
                      Play Again
                    </Button>
                  </div>
                </div>
              </TabsContent>

              <TabsContent value="leaderboard" className="mt-0">
                <div className="space-y-2">
                  <div className="text-center">
                    <h3 className="text-white text-sm font-medium mb-2">Top Scores</h3>
                  </div>
                  {scoresLoading ? (
                    <div className="flex items-center justify-center py-4">
                      <Loader2 className="w-4 h-4 animate-spin text-cyan-400" />
                    </div>
                  ) : scores && scores.length > 0 ? (
                    <div className="space-y-1">
                      {scores.slice(0, 5).map((entry, i) => (
                        <div key={`${entry.playerName}-${i}`} className="flex items-center justify-between p-1 bg-slate-700/30 rounded">
                          <span className="text-slate-400 text-xs w-4">{i + 1}</span>
                          <span className="text-white text-xs truncate flex-1">{entry.playerName}</span>
                          <span className="text-yellow-400 text-xs font-mono">{Number(entry.score).toLocaleString()}</span>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-4 text-slate-500 text-xs">
                      No scores yet. Be the first!
                    </div>
                  )}
                  <Button
                    onClick={onPlayAgain}
                    className="w-full bg-cyan-700 hover:bg-cyan-600 text-white border-0 text-xs h-8"
                  >
                    Play Again
                  </Button>
                </div>
              </TabsContent>
              
              <TabsContent value="howtoplay" className="mt-0">
                <div className="space-y-2">
                  <div className="text-center">
                    <h3 className="text-white text-sm font-medium mb-2">How to Play</h3>
                  </div>
                  <div className="space-y-2">
                    <div>
                      <h4 className="text-cyan-400 font-semibold text-xs mb-1">🎮 Controls</h4>
                      <ul className="text-xs text-slate-300 space-y-0">
                        <li>• WASD/Arrows - Move</li>
                        <li>• Q - Drop decoy</li>
                      </ul>
                    </div>
                    <div>
                      <h4 className="text-blue-400 font-semibold text-xs mb-1">🏃 Escaper</h4>
                      <ul className="text-xs text-slate-300 space-y-0">
                        <li>• Collect 15 coins</li>
                        <li>• Drop decoys</li>
                        <li>• Survive 90s</li>
                      </ul>
                    </div>
                    <div>
                      <h4 className="text-red-400 font-semibold text-xs mb-1">🎯 Hunter</h4>
                      <ul className="text-xs text-slate-300 space-y-0">
                        <li>• Follow footprints</li>
                        <li>• Catch escaper</li>
                        <li>• Score by time</li>
                      </ul>
                    </div>
                  </div>
                  <Button
                    onClick={onPlayAgain}
                    className="w-full bg-cyan-700 hover:bg-cyan-600 text-white border-0 text-xs h-8"
                  >
                    Play Again
                  </Button>
                </div>
              </TabsContent>
            </Tabs>
          </div>
          
          {/* Fixed Footer */}
          <div className="px-6 py-3 border-t border-slate-600 flex-shrink-0">
            <div className="flex justify-center gap-2">
              <Button
                onClick={onPlayAgain}
                className="bg-blue-600 hover:bg-blue-500 text-white border-0 text-xs h-8"
              >
                <Play className="w-3 h-3 mr-1" />
                Play Again
              </Button>
            </div>
          </div>
        </Card>
      </motion.div>
    </div>
  );
}
// APP
// ========================
export default function App() {
  const [phase, setPhase] = useState<GamePhase>("role_select");
  const [playerRole, setPlayerRole] = useState<Role>("escaper");
  const [playerName, setPlayerName] = useState("");
  const [gameResult, setGameResult] = useState<GameResult | null>(null);
  const [showSkipButton, setShowSkipButton] = useState(true);

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

  const handleTourComplete = useCallback(() => {
    setShowSkipButton(false);
  }, []);

  const handlePlayAgain = useCallback(() => {
    setPhase("role_select");
  }, []);

  return (
    <div className="min-h-screen w-full bg-slate-950 text-white overflow-hidden">
      <Toaster richColors position="top-right" />
      
      {/* Toggle Tour Button */}
      {phase === "role_select" && (
        <Button
          onClick={() => setShowSkipButton(!showSkipButton)}
          className="fixed top-4 right-4 z-50 bg-cyan-600 hover:bg-cyan-500 text-white border-0 shadow-lg"
          size="sm"
        >
          <SkipForward className="w-4 h-4 mr-2" />
          {showSkipButton ? "Skip Tour" : "Show Tour"}
        </Button>
      )}
      
      <AnimatePresence mode="wait">
        {phase === "role_select" && (
          <motion.div
            key="role_select"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen w-full bg-slate-950 flex flex-col items-center justify-center"
          >
            <RoleSelectScreen onStart={handleStart} showTour={showSkipButton} onTourComplete={handleTourComplete} />
          </motion.div>
        )}
        {phase === "playing" && (
          <motion.div
            key="playing"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen w-full bg-slate-950 flex flex-col items-center justify-center p-0"
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
