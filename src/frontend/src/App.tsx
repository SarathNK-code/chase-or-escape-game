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
  // Level 3 - Cross pattern with quadrants (fixed for connectivity)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
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

// Generate additional levels automatically for higher levels
function generatePlayableLevel(levelNumber: number): number[][] {
  const map: number[][] = Array(MAP_ROWS).fill(null).map(() => Array(MAP_COLS).fill(1));

  // Create a guaranteed path from top-left to bottom-right
  const createPath = (startX: number, startY: number, endX: number, endY: number) => {
    let currentX = startX;
    let currentY = startY;

    while (currentX !== endX || currentY !== endY) {
      map[currentY][currentX] = 0; // Clear path

      // Smart pathfinding towards target with better corridor creation
      const dx = endX - currentX;
      const dy = endY - currentY;
      
      // Create wider corridors for better movement
      const corridorWidth = Math.min(2, 1 + Math.floor(levelNumber / 3));
      
      if (Math.random() < 0.8) { // 80% chance to move towards target
        if (Math.abs(dx) > Math.abs(dy)) {
          // Move horizontally with corridor
          for (let w = 0; w < corridorWidth; w++) {
            const y = Math.max(1, Math.min(MAP_ROWS - 2, currentY + w - Math.floor(corridorWidth / 2)));
            if (y >= 1 && y < MAP_ROWS - 1) {
              map[y][currentX] = 0;
            }
          }
          currentX += dx > 0 ? 1 : -1;
        } else {
          // Move vertically with corridor
          for (let w = 0; w < corridorWidth; w++) {
            const x = Math.max(1, Math.min(MAP_COLS - 2, currentX + w - Math.floor(corridorWidth / 2)));
            if (x >= 1 && x < MAP_COLS - 1) {
              map[currentY][x] = 0;
            }
          }
          currentY += dy > 0 ? 1 : -1;
        }
      } else { // 20% chance for strategic exploration
        const dir = Math.floor(Math.random() * 4);
        switch (dir) {
          case 0: 
            if (currentY > 1) {
              for (let w = 0; w < corridorWidth; w++) {
                const x = Math.max(1, Math.min(MAP_COLS - 2, currentX + w - Math.floor(corridorWidth / 2)));
                if (x >= 1 && x < MAP_COLS - 1) {
                  map[currentY - 1][x] = 0;
                }
              }
              currentY--;
            }
            break;
          case 1: 
            if (currentX < MAP_COLS - 2) {
              for (let w = 0; w < corridorWidth; w++) {
                const y = Math.max(1, Math.min(MAP_ROWS - 2, currentY + w - Math.floor(corridorWidth / 2)));
                if (y >= 1 && y < MAP_ROWS - 1) {
                  map[y][currentX + 1] = 0;
                }
              }
              currentX++;
            }
            break;
          case 2: 
            if (currentY < MAP_ROWS - 2) {
              for (let w = 0; w < corridorWidth; w++) {
                const x = Math.max(1, Math.min(MAP_COLS - 2, currentX + w - Math.floor(corridorWidth / 2)));
                if (x >= 1 && x < MAP_COLS - 1) {
                  map[currentY + 1][x] = 0;
                }
              }
              currentY++;
            }
            break;
          case 3: 
            if (currentX > 1) {
              for (let w = 0; w < corridorWidth; w++) {
                const y = Math.max(1, Math.min(MAP_ROWS - 2, currentY + w - Math.floor(corridorWidth / 2)));
                if (y >= 1 && y < MAP_ROWS - 1) {
                  map[y][currentX - 1] = 0;
                }
              }
              currentX--;
            }
            break;
        }
      }
      
      // Keep within bounds
      currentX = Math.max(1, Math.min(MAP_COLS - 2, currentX));
      currentY = Math.max(1, Math.min(MAP_ROWS - 2, currentY));
    }
    map[endY][endX] = 0; // Ensure end is clear
  };

  // Create main paths with better connectivity and wider corridors
  createPath(1, 1, MAP_COLS - 2, MAP_ROWS - 2);
  createPath(1, MAP_ROWS - 2, MAP_COLS - 2, 1);
  createPath(1, 1, MAP_COLS - 2, 1);
  createPath(1, 1, 1, MAP_ROWS - 2);
  createPath(MAP_COLS - 2, 1, MAP_COLS - 2, MAP_ROWS - 2);
  
  // Create additional connecting paths for better flow
  for (let i = 0; i < 8 + levelNumber; i++) {
    const x1 = Math.floor(Math.random() * (MAP_COLS - 6)) + 3;
    const y1 = Math.floor(Math.random() * (MAP_ROWS - 6)) + 3;
    const x2 = Math.floor(Math.random() * (MAP_COLS - 6)) + 3;
    const y2 = Math.floor(Math.random() * (MAP_ROWS - 6)) + 3;
    createPath(x1, y1, x2, y2);
  }

  // Create larger open areas for better movement
  const createRoom = (centerX: number, centerY: number, width: number, height: number) => {
    for (let y = Math.max(1, centerY - height); y <= Math.min(MAP_ROWS - 2, centerY + height); y++) {
      for (let x = Math.max(1, centerX - width); x <= Math.min(MAP_COLS - 2, centerX + width); x++) {
        map[y][x] = 0;
      }
    }
  };

  // Add strategic rooms with better sizing
  const roomSize = Math.min(4, 2 + Math.floor(levelNumber / 2));
  createRoom(5, 5, roomSize, roomSize);
  createRoom(MAP_COLS - 5, 5, roomSize, roomSize);
  createRoom(5, MAP_ROWS - 5, roomSize, roomSize);
  createRoom(MAP_COLS - 5, MAP_ROWS - 5, roomSize, roomSize);
  createRoom(Math.floor(MAP_COLS / 2), Math.floor(MAP_ROWS / 2), roomSize + 1, roomSize);
  
  // Add some random open areas for variety
  for (let i = 0; i < 3 + Math.floor(levelNumber / 2); i++) {
    const roomX = Math.floor(Math.random() * (MAP_COLS - 8)) + 4;
    const roomY = Math.floor(Math.random() * (MAP_ROWS - 8)) + 4;
    const roomW = Math.floor(Math.random() * 3) + 2;
    const roomH = Math.floor(Math.random() * 3) + 2;
    createRoom(roomX, roomY, roomW, roomH);
  }

  // Ensure borders are walls
  for (let i = 0; i < MAP_COLS; i++) {
    map[0][i] = 1;
    map[MAP_ROWS - 1][i] = 1;
  }
  for (let i = 0; i < MAP_ROWS; i++) {
    map[i][0] = 1;
    map[i][MAP_COLS - 1] = 1;
  }

  // Verify map accessibility and fix if needed
  if (!verifyMapAccessibility(map)) {
    // Add emergency grid paths if map is not fully accessible
    for (let y = 2; y < MAP_ROWS - 2; y += 2) {
      for (let x = 2; x < MAP_COLS - 2; x += 2) {
        map[y][x] = 0;
      }
    }
  }

  return map;
}

// Verify that all accessible areas are connected
function verifyMapAccessibility(map: number[][]): boolean {
  const accessibleTiles: {col: number, row: number}[] = [];
  
  // Find all accessible tiles
  for (let r = 1; r < MAP_ROWS - 1; r++) {
    for (let c = 1; c < MAP_COLS - 1; c++) {
      if (map[r][c] === 0) {
        accessibleTiles.push({ col: c, row: r });
      }
    }
  }
  
  if (accessibleTiles.length === 0) return false;
  
  // BFS from first accessible tile
  const queue = [accessibleTiles[0]];
  const visited = new Set<string>();
  visited.add(`${accessibleTiles[0].col},${accessibleTiles[0].row}`);
  
  while (queue.length > 0) {
    const current = queue.shift()!;
    
    for (const tile of accessibleTiles) {
      const key = `${tile.col},${tile.row}`;
      if (!visited.has(key) && 
          Math.abs(current.col - tile.col) <= 1 && 
          Math.abs(current.row - tile.row) <= 1) {
        visited.add(key);
        queue.push(tile);
      }
    }
  }
  
  // Check if all accessible tiles are reachable
  return visited.size === accessibleTiles.length;
}

MAPS.push(...Array(10).fill(null).map((_, i) => generatePlayableLevel(i + 3)));

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
  respawnGraceTimer: number; // Grace period after respawn to prevent immediate re-catch
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
  const r = PLAYER_RADIUS - 1; // Even smaller radius for smooth movement
  const checkPoints = [
    { x: x - r, y: y - r },
    { x: x + r, y: y - r },
    { x: x - r, y: y + r },
    { x: x + r, y: y + r },
    // Add diagonal checks for better corner detection
    { x: x - r * 0.7, y: y - r * 0.7 },
    { x: x + r * 0.7, y: y - r * 0.7 },
    { x: x - r * 0.7, y: y + r * 0.7 },
    { x: x + r * 0.7, y: y + r * 0.7 },
    // Center point
    { x: x, y: y }
  ];
  
  return checkPoints.some((c) => {
    const col = Math.floor(c.x / TILE_SIZE);
    const row = Math.floor(c.y / TILE_SIZE);
    return isWall(col, row, level);
  });
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

// Find valid spawn points for entities
function findValidSpawnPoint(level: number, excludePoints: Vec2[] = []): Vec2 {
  const currentMap = getCurrentMap(level);
  const floorTiles: Vec2[] = [];
  
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (currentMap[r][c] === 0) {
        const tilePos = tileCenter(c, r);
        // Check if this position is valid (not in walls and not too close to excluded points)
        if (!isWallAt(tilePos.x, tilePos.y, level)) {
          const tooClose = excludePoints.some(point => vecDist(tilePos, point) < TILE_SIZE * 2);
          if (!tooClose) {
            // Check if this tile has good connectivity to other areas
            const hasGoodConnectivity = checkTileConnectivity(c, r, currentMap);
            if (hasGoodConnectivity) {
              floorTiles.push(tilePos);
            }
          }
        }
      }
    }
  }
  
  // Return a random valid position, or fallback to (1,1) if none found
  if (floorTiles.length > 0) {
    return floorTiles[Math.floor(Math.random() * floorTiles.length)];
  }
  return tileCenter(1, 1);
}

// Check if a tile has good connectivity to other areas
function checkTileConnectivity(col: number, row: number, map: number[][]): boolean {
  const directions = [
    { dx: 0, dy: -1 }, { dx: 1, dy: 0 }, 
    { dx: 0, dy: 1 }, { dx: -1, dy: 0 }
  ];
  
  let openNeighbors = 0;
  for (const dir of directions) {
    const newCol = col + dir.dx;
    const newRow = row + dir.dy;
    if (newCol >= 0 && newCol < MAP_COLS && newRow >= 0 && newRow < MAP_ROWS) {
      if (map[newRow][newCol] === 0) {
        openNeighbors++;
      }
    }
  }
  
  // Prefer tiles with at least 2 open neighbors for better movement
  return openNeighbors >= 2;
}

// Check if there's a path between two points using BFS
function isPathAccessible(start: Vec2, end: Vec2, map: number[][]): boolean {
  const startTile = {
    col: Math.floor(start.x / TILE_SIZE),
    row: Math.floor(start.y / TILE_SIZE)
  };
  const endTile = {
    col: Math.floor(end.x / TILE_SIZE),
    row: Math.floor(end.y / TILE_SIZE)
  };
  
  // If start or end is in a wall, return false
  if (map[startTile.row][startTile.col] === 1 || map[endTile.row][endTile.col] === 1) {
    return false;
  }
  
  // BFS to find path
  const queue: {col: number, row: number}[] = [startTile];
  const visited = new Set<string>();
  visited.add(`${startTile.col},${startTile.row}`);
  
  while (queue.length > 0) {
    const current = queue.shift()!;
    
    if (current.col === endTile.col && current.row === endTile.row) {
      return true; // Path found
    }
    
    const directions = [
      { dx: 0, dy: -1 }, { dx: 1, dy: 0 }, 
      { dx: 0, dy: 1 }, { dx: -1, dy: 0 }
    ];
    
    for (const dir of directions) {
      const newCol = current.col + dir.dx;
      const newRow = current.row + dir.dy;
      const key = `${newCol},${newRow}`;
      
      if (newCol >= 0 && newCol < MAP_COLS && newRow >= 0 && newRow < MAP_ROWS &&
          !visited.has(key) && map[newRow][newCol] === 0) {
        visited.add(key);
        queue.push({ col: newCol, row: newRow });
      }
    }
  }
  
  return false; // No path found
}

function createInitialGameState(level: number = 1, totalLevels: number = 3): GameState {
  const currentMap = getCurrentMap(level);
  const floorTiles: Vec2[] = [];
  for (let r = 0; r < MAP_ROWS; r++) {
    for (let c = 0; c < MAP_COLS; c++) {
      if (currentMap[r][c] === 0) floorTiles.push(tileCenter(c, r));
    }
  }
  
  // Find valid spawn points for both players
  const escaperSpawn = findValidSpawnPoint(level, []);
  const hunterSpawn = findValidSpawnPoint(level, [escaperSpawn]);
  
  // Level-specific difficulty adjustments
  const levelMultiplier = 1 + (level - 1) * 0.2; // 20% harder each level
  const adjustedNumCoins = Math.min(NUM_COINS + Math.floor((level - 1) * 2), 25); // More coins each level
  const adjustedGameDuration = Math.max(GAME_DURATION - (level - 1) * 10, 60); // Less time each level
  const adjustedAI_SPEED = Math.min(AI_SPEED + (level - 1) * 10, 180); // Faster AI each level
  const adjustedMAX_DECOYS = Math.max(MAX_DECOYS - Math.floor((level - 1) * 0.5), 1); // Fewer decoys each level
  
  // Filter coin candidates to ensure accessibility from both spawn points
  const coinCandidates = floorTiles.filter((t) => {
    // Check distance from spawn points
    const farEnoughFromSpawns = 
      vecDist(t, escaperSpawn) > TILE_SIZE * 2.5 &&
      vecDist(t, hunterSpawn) > TILE_SIZE * 2.5;
    
    if (!farEnoughFromSpawns) return false;
    
    // Check if coin is accessible from both escaper and hunter positions
    const accessibleFromEscaper = isPathAccessible(escaperSpawn, t, currentMap);
    const accessibleFromHunter = isPathAccessible(hunterSpawn, t, currentMap);
    
    return accessibleFromEscaper && accessibleFromHunter;
  });
  
  // Ensure we have enough accessible coin positions
  const minRequiredCoins = Math.min(adjustedNumCoins, coinCandidates.length);
  if (coinCandidates.length < adjustedNumCoins) {
    // If not enough accessible coins, add more by clearing additional paths
    console.warn(`Level ${level}: Only ${coinCandidates.length} accessible coins found, need ${adjustedNumCoins}. Adding emergency paths.`);
    
    // Add emergency paths to ensure coin accessibility
    for (let attempts = 0; attempts < 10 && coinCandidates.length < adjustedNumCoins; attempts++) {
      const randomCol = Math.floor(Math.random() * (MAP_COLS - 4)) + 2;
      const randomRow = Math.floor(Math.random() * (MAP_ROWS - 4)) + 2;
      const potentialPos = tileCenter(randomCol, randomRow);
      
      if (!isWallAt(potentialPos.x, potentialPos.y, level)) {
        const accessibleFromEscaper = isPathAccessible(escaperSpawn, potentialPos, currentMap);
        const accessibleFromHunter = isPathAccessible(hunterSpawn, potentialPos, currentMap);
        
        if (accessibleFromEscaper && accessibleFromHunter) {
          coinCandidates.push(potentialPos);
        }
      }
    }
  }
  
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
    respawnGraceTimer: 0, // Initialize respawn grace timer
  };
}

// ========================
// GAME LOGIC
// ========================
function moveEntity(entity: Entity, dx: number, dy: number, level: number = 1): void {
  const originalX = entity.pos.x;
  const originalY = entity.pos.y;
  const nx = entity.pos.x + dx;
  const ny = entity.pos.y + dy;
  
  // Try full movement first
  if (!isWallAt(nx, ny, level)) {
    entity.pos.x = nx;
    entity.pos.y = ny;
    return;
  }
  
  // Try horizontal only
  if (!isWallAt(nx, originalY, level)) {
    entity.pos.x = nx;
    return;
  }
  
  // Try vertical only
  if (!isWallAt(originalX, ny, level)) {
    entity.pos.y = ny;
    return;
  }
  
  // Try smaller steps (for getting out of tight spaces)
  const stepSize = 0.5;
  const steps = Math.max(Math.abs(dx), Math.abs(dy)) / stepSize;
  
  for (let i = 1; i <= steps; i++) {
    const stepX = originalX + (dx * i / steps);
    const stepY = originalY + (dy * i / steps);
    
    if (!isWallAt(stepX, stepY, level)) {
      entity.pos.x = stepX;
      entity.pos.y = stepY;
      break;
    }
    
    // Try just horizontal movement at this step
    if (!isWallAt(stepX, originalY, level)) {
      entity.pos.x = stepX;
      break;
    }
    
    // Try just vertical movement at this step
    if (!isWallAt(originalX, stepY, level)) {
      entity.pos.y = stepY;
      break;
    }
  }
  
  // Ensure entity stays within bounds
  entity.pos.x = Math.max(PLAYER_RADIUS, Math.min(CANVAS_W - PLAYER_RADIUS, entity.pos.x));
  entity.pos.y = Math.max(PLAYER_RADIUS, Math.min(CANVAS_H - PLAYER_RADIUS, entity.pos.y));
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
    
    // Find best target using intelligent pathfinding
    let bestTarget = { ...gs.escaper.pos };
    let bestTargetScore = -Infinity;
    
    // Consider decoys as potential targets
    const allTargets = [
      { pos: gs.escaper.pos, type: 'escaper', priority: 100 },
      ...gs.decoys.map(decoy => ({ pos: { x: decoy.x, y: decoy.y }, type: 'decoy', priority: 60 }))
    ];
    
    for (const target of allTargets) {
      // Calculate path-based score
      const pathDistance = calculatePathDistance(gs.hunter.pos, target.pos, gs.currentLevel);
      const directDistance = vecDist(gs.hunter.pos, target.pos);
      
      // Score based on path efficiency and priority
      const pathEfficiency = directDistance / Math.max(pathDistance, 1);
      const score = (target.priority * pathEfficiency) - (pathDistance * 0.5);
      
      if (score > bestTargetScore) {
        bestTargetScore = score;
        bestTarget = target.pos;
      }
    }
    
    gs.hunterTarget = bestTarget;
    
    // Set distraction timer if targeting decoy
    const isDecoyTarget = gs.decoys.some(decoy => 
      Math.abs(decoy.x - gs.hunterTarget.x) < 5 && 
      Math.abs(decoy.y - gs.hunterTarget.y) < 5
    );
    
    if (isDecoyTarget) {
      gs.hunterDistractTimer = Math.max(2000, 4000 - (gs.currentLevel - 1) * 200);
    }
  }
  
  // Move hunter towards target with smart pathfinding
  const dx = gs.hunterTarget.x - gs.hunter.pos.x;
  const dy = gs.hunterTarget.y - gs.hunter.pos.y;
  const distance = Math.sqrt(dx * dx + dy * dy);
  
  if (distance > 1) {
    // Use pathfinding for movement
    const nextStep = getNextStepTowards(gs.hunter.pos, gs.hunterTarget, gs.currentLevel);
    if (nextStep) {
      const moveX = nextStep.x - gs.hunter.pos.x;
      const moveY = nextStep.y - gs.hunter.pos.y;
      const moveDistance = Math.sqrt(moveX * moveX + moveY * moveY);
      
      // Normalize and apply speed
      const normalizedX = (moveX / moveDistance) * currentAISpeed * dt;
      const normalizedY = (moveY / moveDistance) * currentAISpeed * dt;
      
      gs.hunter.dir = Math.atan2(normalizedY, normalizedX);
      moveEntity(gs.hunter, normalizedX, normalizedY, gs.currentLevel);
    }
  }
}

// Calculate actual path distance using BFS
function calculatePathDistance(start: Vec2, end: Vec2, level: number): number {
  const startTile = {
    col: Math.floor(start.x / TILE_SIZE),
    row: Math.floor(start.y / TILE_SIZE)
  };
  const endTile = {
    col: Math.floor(end.x / TILE_SIZE),
    row: Math.floor(end.y / TILE_SIZE)
  };
  
  const currentMap = getCurrentMap(level);
  type QueueItem = {col: number, row: number, dist: number};
  const queue: QueueItem[] = [{...startTile, dist: 0}];
  const visited = new Set<string>();
  visited.add(`${startTile.col},${startTile.row}`);
  
  while (queue.length > 0) {
    const current = queue.shift()!;
    
    if (current.col === endTile.col && current.row === endTile.row) {
      return current.dist;
    }
    
    const directions = [
      { dx: 0, dy: -1 }, { dx: 1, dy: 0 }, 
      { dx: 0, dy: 1 }, { dx: -1, dy: 0 }
    ];
    
    for (const dir of directions) {
      const newCol = current.col + dir.dx;
      const newRow = current.row + dir.dy;
      const key = `${newCol},${newRow}`;
      
      if (newCol >= 0 && newCol < MAP_COLS && newRow >= 0 && newRow < MAP_ROWS &&
          !visited.has(key) && currentMap[newRow][newCol] === 0) {
        visited.add(key);
        queue.push({ col: newCol, row: newRow, dist: current.dist + 1 });
      }
    }
  }
  
  return vecDist(start, end); // Fallback to direct distance
}

// Get next step towards target using pathfinding
function getNextStepTowards(start: Vec2, target: Vec2, level: number): Vec2 | null {
  const startTile = {
    col: Math.floor(start.x / TILE_SIZE),
    row: Math.floor(start.y / TILE_SIZE)
  };
  const targetTile = {
    col: Math.floor(target.x / TILE_SIZE),
    row: Math.floor(target.y / TILE_SIZE)
  };
  
  const currentMap = getCurrentMap(level);
  type PathItem = {col: number, row: number, path: {col: number, row: number}[]};
  const queue: PathItem[] = [{...startTile, path: [{...startTile}]}];
  const visited = new Set<string>();
  visited.add(`${startTile.col},${startTile.row}`);
  
  while (queue.length > 0) {
    const current = queue.shift()!;
    
    if (current.col === targetTile.col && current.row === targetTile.row) {
      // Found path, return next step after start
      if (current.path.length > 1) {
        return tileCenter(current.path[1].col, current.path[1].row);
      }
      break;
    }
    
    const directions = [
      { dx: 0, dy: -1 }, { dx: 1, dy: 0 }, 
      { dx: 0, dy: 1 }, { dx: -1, dy: 0 }
    ];
    
    for (const dir of directions) {
      const newCol = current.col + dir.dx;
      const newRow = current.row + dir.dy;
      const key = `${newCol},${newRow}`;
      
      if (newCol >= 0 && newCol < MAP_COLS && newRow >= 0 && newRow < MAP_ROWS &&
          !visited.has(key) && currentMap[newRow][newCol] === 0) {
        visited.add(key);
        queue.push({ 
          col: newCol, 
          row: newRow, 
          path: [...current.path, {col: newCol, row: newRow}] 
        });
      }
    }
  }
  
  return null; // No path found
}

function updateAIEscaper(gs: GameState, dt: number): void {
  gs.escaperAITimer -= dt * 1000;
  // ... (rest of the code remains the same)
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
      // Find valid respawn point for escaper that ensures access to remaining coins
      const remainingCoins = gs.coins.filter(c => !c.collected);
      let bestRespawnPoint: Vec2 | null = null;
      let bestScore = -Infinity;
      
      // Find respawn point with best access to remaining coins
      const currentMap = getCurrentMap(gs.currentLevel);
      for (let r = 1; r < MAP_ROWS - 1; r++) {
        for (let c = 1; c < MAP_COLS - 1; c++) {
          if (currentMap[r][c] === 0) {
            const potentialPos = tileCenter(c, r);
            
            // Check if this position is valid
            if (!isWallAt(potentialPos.x, potentialPos.y, gs.currentLevel)) {
              // Calculate total path distance to all remaining coins
              let totalPathDistance = 0;
              let accessibleCoins = 0;
              
              for (const coin of remainingCoins) {
                const pathDist = calculatePathDistance(potentialPos, coin, gs.currentLevel);
                if (pathDist < Infinity) { // Path exists
                  totalPathDistance += pathDist;
                  accessibleCoins++;
                }
              }
              
              // Score based on accessibility and distance from hunter
              const hunterDist = vecDist(potentialPos, gs.hunter.pos);
              const distanceFromHunter = Math.max(0, hunterDist - TILE_SIZE * 3); // Prefer distance from hunter
              const score = (accessibleCoins * 100) - totalPathDistance + distanceFromHunter;
              
              if (score > bestScore) {
                bestScore = score;
                bestRespawnPoint = potentialPos;
              }
            }
          }
        }
      }
      
      // Fallback to original method if no optimal point found
      if (!bestRespawnPoint) {
        bestRespawnPoint = findValidSpawnPoint(gs.currentLevel, [gs.hunter.pos]);
      }
      
      gs.escaper.pos = { ...bestRespawnPoint };
      gs.escaper.dir = 0;
      gs.status = "playing";
      gs.respawnTimer = 0;
      gs.respawnGraceTimer = 2; // 2 second grace period after respawn
    }
    return; // Don't update game while respawning
  }
  
  // Update respawn grace timer
  if (gs.respawnGraceTimer > 0) {
    gs.respawnGraceTimer -= dt;
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
  // Catch detection (only if not in grace period)
  if (gs.respawnGraceTimer <= 0 && vecDist(gs.escaper.pos, gs.hunter.pos) < CATCH_DISTANCE) {
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
        gs.respawnGraceTimer = 0; // Reset grace timer
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
  } else if (gs.respawnGraceTimer > 0) {
    // Show grace period indicator
    ctx.font = 'bold 16px "JetBrains Mono", monospace';
    ctx.fillStyle = '#10b981';
    ctx.textAlign = 'center';
    ctx.fillText(`Grace Period: ${Math.ceil(gs.respawnGraceTimer)}s`, CANVAS_W / 2, 50);
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
      title: "Welcome to Your Adventure!",
      description: "Let's start your exciting journey!",
      icon: <Gamepad2 className="w-16 h-16 text-blue-400" />,
      content: (
        <div className="text-center space-y-3">
          <p className="text-white text-sm font-medium">Ready for an amazing adventure?</p>
          <div className="flex justify-center gap-4">
            <div className="text-center">
              <div className="text-2xl mb-2">🏃‍♂️</div>
              <p className="text-blue-300 text-sm font-medium">Run Fast</p>
              <p className="text-white/70 text-xs">Be quick on your feet!</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-2">🎯</div>
              <p className="text-red-300 text-sm font-medium">Think Smart</p>
              <p className="text-white/70 text-xs">Plan your moves wisely!</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-2">⏱</div>
              <p className="text-yellow-300 text-sm font-medium">Beat Time</p>
              <p className="text-white/70 text-xs">Race against the clock!</p>
            </div>
          </div>
        </div>
      )
    },
    
    {
      title: "Easy Game Controls",
      description: "Anyone can play - it's that simple!",
      icon: <Heart className="w-16 h-16 text-pink-400" />,
      content: (
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-blue-500/10 rounded-lg p-3 border border-blue-500/30 text-center">
              <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center mx-auto mb-2">
                <span className="text-white font-bold text-sm">↑↓←→</span>
              </div>
              <p className="text-white font-semibold text-sm">Arrow Keys</p>
              <p className="text-white/80 text-xs">Move your character around</p>
              <p className="text-blue-300 text-xs mt-1">💡 Also works with WASD!</p>
            </div>
            <div className="bg-purple-500/10 rounded-lg p-3 border border-purple-500/30 text-center">
              <div className="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center mx-auto mb-2">
                <span className="text-white font-bold text-sm">SPACE</span>
              </div>
              <p className="text-white font-semibold text-sm">Space Bar</p>
              <p className="text-white/80 text-xs">Drop magic decoys</p>
              <p className="text-purple-300 text-xs mt-1">🎯 Escaper special power!</p>
            </div>
          </div>
          <div className="text-center bg-green-500/10 rounded-lg p-2 border border-green-500/30">
            <p className="text-green-300 text-sm font-medium">🎮 Super Easy Controls!</p>
          </div>
        </div>
      )
    },
    {
      title: "Pick Your Hero!",
      description: "Choose your character and start playing!",
      icon: <Trophy className="w-16 h-16 text-amber-400" />,
      content: (
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-blue-500/20 rounded-lg p-3 border border-blue-500/40">
              <div className="text-center">
                <div className="text-3xl mb-2">🏃‍♂️</div>
                <p className="text-white font-bold text-base">Escaper</p>
                <p className="text-blue-300 text-sm font-medium">The Speed Hero</p>
              </div>
              <div className="mt-2 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-yellow-400 text-xs">🪙</span>
                  <p className="text-white/80 text-xs">Collect 15 shiny coins</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-purple-400 text-xs">🌀</span>
                  <p className="text-white/80 text-xs">Drop magic decoys</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-green-400 text-xs">⏱</span>
                  <p className="text-white/80 text-xs">Survive for 90 seconds</p>
                </div>
              </div>
            </div>
            <div className="bg-red-500/20 rounded-lg p-3 border border-red-500/40">
              <div className="text-center">
                <div className="text-3xl mb-2">🎯</div>
                <p className="text-white font-bold text-base">Hunter</p>
                <p className="text-red-300 text-sm font-medium">The Chase Master</p>
              </div>
              <div className="mt-2 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-cyan-400 text-xs">👣</span>
                  <p className="text-white/80 text-xs">Follow glowing footprints</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-orange-400 text-xs">🎯</span>
                  <p className="text-white/80 text-xs">Catch the Escaper</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-pink-400 text-xs">🏆</span>
                  <p className="text-white/80 text-xs">Score big with time bonus</p>
                </div>
              </div>
            </div>
          </div>
          <div className="text-center bg-amber-500/10 rounded-lg p-2 border border-amber-500/30">
            <p className="text-amber-300 text-sm font-medium">🎮 Choose the hero that matches your style!</p>
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
          className="relative z-10 w-full max-w-2xl h-[400px] flex flex-col mx-auto"
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
            
            {/* Content Area with Navigation - No Scrolling */}
            <div className="flex-1 px-6 py-4 overflow-hidden flex flex-col">
              <div className="flex-1">
                {tourSteps[tourStep].content}
              </div>
              
              {/* Navigation Buttons inside content */}
              <div className="flex justify-between items-center mt-4">
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
              
              {/* Skip Tour Button Only */}
              <div className="flex justify-center">
                <Button
                  variant="outline"
                  onClick={skipTour}
                  className="border-slate-600 text-slate-300 hover:bg-slate-700 hover:text-white"
                >
                  <SkipForward className="w-4 h-4 mr-2" />
                  Skip Tour
                </Button>
              </div>
            </div>
          </Card>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-800 via-slate-900 to-slate-800 flex flex-col items-center justify-center p-4 w-full">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-20 left-20 w-32 h-32 bg-blue-400/10 rounded-full blur-xl animate-pulse" />
        <div className="absolute top-40 right-32 w-24 h-24 bg-purple-400/10 rounded-full blur-xl animate-pulse delay-1000" />
        <div className="absolute bottom-32 left-40 w-28 h-28 bg-green-400/10 rounded-full blur-xl animate-pulse delay-2000" />
      </div>

      <div className="relative z-10 w-full h-full flex flex-col items-center justify-center">
        {/* Main Title */}
        <Card className="bg-slate-800 border border-slate-600 shadow-2xl flex flex-col w-full max-w-4xl">
          {/* Fixed Header */}
          <div className="px-6 py-4 border-b border-slate-600 flex-shrink-0">
            <motion.div
              initial={{ opacity: 0, y: -30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="text-center"
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
          </div>
          
          {/* Content Area - No Scrolling */}
          <div className="flex-1 px-6 py-4 overflow-hidden min-h-[400px]">
            {/* Character Selection */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2, duration: 0.5 }}
              className="h-full"
            >
              <div className="space-y-4">
                {/* Role Selection */}
                <div className="grid md:grid-cols-2 gap-4">
                  <motion.button
                    whileHover={{ scale: 1.03 }}
                    whileTap={{ scale: 0.97 }}
                    data-ocid="role.escaper_button"
                    onClick={() => setSelectedRole("escaper")}
                    className={`p-3 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-blue-400 ${
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
                    <div className="flex items-center gap-3 mb-2">
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
                    className={`p-3 rounded-xl border-2 text-left transition-all duration-300 cursor-pointer relative overflow-hidden focus:outline-none focus:ring-2 focus:ring-red-400 ${
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
                    <div className="flex items-center gap-3 mb-2">
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
              </div>
            </motion.div>
          </div>
          
          {/* Fixed Footer */}
          <div className="px-6 py-3 border-t border-slate-600 flex-shrink-0">
            <div className="flex justify-center gap-2">
              <Button
                onClick={onTourComplete}
                className="bg-blue-600 hover:bg-blue-500 text-white border-0 text-xs h-8"
              >
                <BookOpen className="w-3 h-3 mr-1" />
                Start Tour
              </Button>
            </div>
          </div>
        </Card>
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
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4 w-full">
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", duration: 0.7 }}
        className="relative z-10 w-full max-w-4xl flex flex-col mx-auto"
      >
        <Card className="bg-slate-800 border border-slate-600 shadow-2xl flex flex-col w-full">
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
          <div className="flex-1 px-6 py-4 overflow-hidden min-h-[400px]">
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
