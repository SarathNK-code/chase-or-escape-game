# Chase or Escape Game

Exported from Caffeine project: Chase or Escape Game

## Quick Start

```bash
# Navigate to frontend directory
cd src/frontend

# Install dependencies
pnpm install

# Start development server
pnpm vite
```

Open http://localhost:5173 to play the game!

## How to Play

- **Escaper**: Collect all coins or survive time limit to win
- **Hunter**: Catch escaper before time runs out
- **Controls**: 
  - Arrow Keys / WASD - Move your character
  - Space Bar (Escaper only) - Drop decoys to confuse the hunter

## Enhanced Features

### Skip Tour System
- **Constant Skip Button**: Always visible in top-right corner with skip icon
- **Instant Access**: Skip tutorial and jump directly into gameplay
- **Persistent Navigation**: Button remains available across all game screens

### Three Lives System
- **Heart Display**: Visual life indicators with (full) and (empty) hearts
- **5-Second Respawn**: Automatic respawn after being caught with countdown timer
- **Strategic Gameplay**: Multiple chances to complete each level
- **Lives Carry Over**: Remaining lives persist through level transitions

### Advanced AI Hunter Behavior
- **Block Detection**: Hunter detects when blocked by walls in any direction
- **Immediate Chase**: When blocked, hunter instantly targets escaper with aggressive pursuit
- **Faster Reaction**: Reduced decision time when blocked (200ms vs normal)
- **Smart Navigation**: Hunter analyzes terrain and adapts movement accordingly

### 5 Unique Strategic Maps
- ** Level 1**: Original balanced layout - perfect for learning basics
- ** Level 2**: Spiral maze with center arena - tests navigation skills
- ** Level 3**: Cross pattern with quadrants - strategic positioning required
- ** Level 4**: Diamond pattern with diagonal paths - dynamic movement challenges
- ** Level 5**: Islands pattern with bridges - tactical advantage points
- **Diverse Block Patterns**: Each level features unique wall configurations and strategic chokepoints

### Modern Visual Design
- **Glassmorphism HUD**: Semi-transparent overlays with modern blur effects
- **Gradient Backgrounds**: Dynamic color transitions for visual depth
- **Enhanced Character Design**: Radial gradients, glow effects, and improved visibility
- **Metallic Coin Rendering**: Realistic gold appearance with pulsing bonus indicators
- **Modern Color Palette**: Following contemporary frontend design standards
- **Lives Visualization**: Clear heart-based life display system

### Progressive Difficulty System
- **Dynamic Scaling**: Each level increases in complexity
  - More coins to collect (15 → 25)
  - Less time to complete (90s → 60s minimum)
  - Faster AI opponent (125 → 180 speed)
  - Fewer decoys available (3 → 1)
  - Smarter AI behavior and reactions
  - Adaptive hunter block detection

### Advanced Scoring System
- **Cumulative Scoring**: Score carries over across all levels
- **Bonus Coin System**: Golden coins worth 2.5x regular points
- **Time Bonuses**: Extra points for quick completion
- **Level Completion Rewards**: Bonus points for each finished level
- **Lives Preservation**: Score maintained through respawns

### Full Screen Experience
- **No Padding**: Complete screen utilization for immersive gameplay
- **Responsive Layout**: Adapts to different screen sizes
- **Persistent UI**: Skip button always accessible
- **Optimized Performance**: 60 FPS rendering with smooth animations

## Gameplay Mechanics

- **5-Second Level Transitions**: Beautiful animated countdown with progress rings
- **Respawn System**: 5-second countdown with visual feedback
- **Smart AI Interactions**: Hunter responds dynamically to terrain and player position
- **Lives Management**: Strategic use of three chances per level
- **Responsive Controls**: Instant input response with no lag

## Level Progression

Progress through 5 increasingly challenging levels, each with unique strategic layouts:

- ** Level 1**: Learn mechanics in a balanced environment
- ** Level 2**: Navigate complex spiral corridors
- ** Level 3**: Master cross-pattern positioning
- ** Level 4**: Conquer diagonal diamond challenges
- ** Level 5**: Dominate the islands battlefield

Complete all 5 levels with strategic lives management to achieve ultimate victory!
