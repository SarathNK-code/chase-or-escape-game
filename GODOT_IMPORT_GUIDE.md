# Chase or Escape Game - Godot Import Guide

This guide will help you import the complete Chase or Escape Game into your Godot engine project.

## 🎮 Game Overview

The Chase or Escape Game is a 2D multiplayer game featuring:
- **Two Roles**: Escaper (collects coins, drops decoys) and Hunter (catches escaper)
- **5 Unique Levels**: Progressive difficulty with different map layouts
- **Lives System**: Escaper has 3 lives with 5-second respawn
- **Smart AI**: Advanced pathfinding and behavior for both characters
- **Modern Visuals**: Gradients, glow effects, and smooth animations

## 📁 Project Structure

```
godot_project/
├── scenes/
│   ├── Character.tscn          # Base character scene
│   ├── Escaper.tscn           # Player-controlled escaper
│   ├── Hunter.tscn            # AI-controlled hunter
│   ├── Coin.tscn              # Collectible coins (regular/bonus)
│   ├── Decoy.tscn             # Decoy objects for distraction
│   ├── Level.tscn             # Level environment
│   ├── GameManager.tscn       # Main game controller
│   └── HUD.tscn               # User interface
├── scripts/
│   ├── Character.gd           # Base character logic
│   ├── Escaper.gd             # Escaper-specific behavior
│   ├── Hunter.gd              # Hunter AI and logic
│   ├── Coin.gd                # Coin collection and effects
│   ├── Decoy.gd               # Decoy timer and distraction
│   ├── Level.gd               # Level setup and management
│   ├── LevelManager.gd        # Level data and progression
│   ├── GameManager.gd         # Main game coordination
│   └── HUD.gd                 # UI updates and display
├── project.godot              # Godot project configuration
└── input_map.cfg              # Input controls configuration
```

## 🚀 Step-by-Step Import Instructions

### Step 1: Create New Godot Project

1. Open Godot Engine
2. Click "New Project"
3. Choose a location and name your project (e.g., "ChaseOrEscape")
4. Select "Create Folder & Project"
5. Choose "2D" template
6. Click "Create & Edit"

### Step 2: Copy Project Files

1. Navigate to your project folder
2. Copy the entire `godot_project` folder contents to your project root
3. Ensure the folder structure matches the structure shown above

### Step 3: Configure Project Settings

1. In Godot, go to **Project → Project Settings**
2. Set the **Main Scene** to `res://scenes/GameManager.tscn`
3. Go to **Input Map** tab
4. Import the input configuration from `input_map.cfg` or manually add:
   - `move_left`: Left Arrow, A key
   - `move_right`: Right Arrow, D key  
   - `move_up`: Up Arrow, W key
   - `move_down`: Down Arrow, S key
   - `drop_decoy`: Spacebar

### Step 4: Set Up Scene References

1. Open `GameManager.tscn`
2. Select the GameManager node
3. In the Inspector, assign the scene references:
   - **Escaper Scene**: `res://scenes/Escaper.tscn`
   - **Hunter Scene**: `res://scenes/Hunter.tscn`
   - **Level Scene**: `res://scenes/Level.tscn`

### Step 5: Configure Level Scene

1. Open `Level.tscn`
2. Select the Level node
3. In the Inspector, assign:
   - **Coin Scene**: `res://scenes/Coin.tscn`
   - **Decoy Scene**: `res://scenes/Decoy.tscn`

### Step 6: Test the Game

1. Press **F5** or click the **Play** button
2. The game should start with Level 1
3. Test controls:
   - **Arrow Keys/WASD**: Move character
   - **Spacebar**: Drop decoy (Escaper only)

## 🎮 Game Controls

### Escaper Controls
- **Arrow Keys / WASD**: Move your character
- **Spacebar**: Drop decoy to distract hunter
- **Objective**: Collect all coins or survive time limit

### Hunter Controls  
- **Arrow Keys / WASD**: Move your character (if player-controlled)
- **Objective**: Catch the escaper before time runs out

## 🏗️ Architecture Overview

### Core Components

1. **GameManager**: Central coordination of all game systems
2. **LevelManager**: Handles level data and progression
3. **Level Scene**: Manages individual level setup and objects
4. **Character Classes**: Base character with specialized escaper/hunter variants
5. **HUD**: Real-time UI updates and game state display

### Key Features

- **Modular Design**: Each component is reusable and independent
- **Signal-Based Communication**: Clean decoupling between systems
- **AI Pathfinding**: Smart navigation using BFS algorithm
- **Progressive Difficulty**: 5 levels with increasing challenge
- **Visual Effects**: Modern gradients, glow, and particle effects

## 🔧 Customization Guide

### Adding New Levels

1. Open `scripts/LevelManager.gd`
2. Add new map arrays to the `LEVEL_MAPS` collection
3. Update `total_levels` variable
4. Each map should be a 20x15 grid (1 = wall, 0 = empty)

### Adjusting Difficulty

In `LevelManager.gd`, modify the `get_level_difficulty_settings()` method:
- `num_coins`: Number of coins to collect
- `game_duration`: Time limit in seconds
- `ai_speed`: Hunter movement speed
- `max_decoys`: Available decoys for escaper

### Visual Customization

- **Character Colors**: Modify gradient colors in character scripts
- **Wall Appearance**: Update `create_wall_tileset()` in Level.gd
- **UI Styling**: Adjust colors and fonts in HUD.tscn

## 🐛 Troubleshooting

### Common Issues

1. **Scene Not Found Errors**
   - Ensure all scene paths are correct in Inspector
   - Check that all .tscn files exist in the scenes folder

2. **Input Not Working**
   - Verify input map configuration
   - Check that input actions match script references

3. **AI Not Moving**
   - Ensure LevelManager is properly initialized
   - Check that map data is being passed to Hunter

4. **Visual Issues**
   - Verify all textures are loading correctly
   - Check that color values are valid

### Debug Tips

- Use Godot's **Debug** menu to monitor performance
- Check the **Output** panel for error messages
- Use `print()` statements in scripts for debugging

## 🎯 Performance Notes

- **Target FPS**: 60 FPS
- **Resolution**: 800x600 (configurable in GameManager)
- **Optimizations**: Efficient collision detection and pathfinding
- **Memory**: Lightweight textures and minimal object pooling

## 🚀 Next Steps

Once imported, you can:

1. **Test All Levels**: Play through all 5 levels
2. **Adjust Difficulty**: Modify level settings as needed
3. **Add New Features**: Implement power-ups or new game modes
4. **Polish**: Add sound effects and music
5. **Export**: Build for your target platform

## 📞 Support

If you encounter issues during import:

1. Check Godot version compatibility (tested with Godot 4.x)
2. Verify all file paths and references
3. Review the console for specific error messages
4. Ensure all required scenes and scripts are present

---

**Enjoy your Chase or Escape Game in Godot!** 🎮✨
