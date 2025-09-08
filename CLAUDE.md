# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **prism-template** - a starting template for building roguelike games using the [Prism game engine](https://github.com/PrismRL/prism). Prism is a Lua-based game framework built on top of LÖVE2D that provides entity-component-system (ECS) architecture, grid-based movement, and roguelike-specific utilities.

## Development Commands

### Running the Game

```bash
# Run the game with LÖVE2D
love .

# Format code with StyLua
stylua .

# Build releases with makelove (requires makelove installed)
makelove build
```

### Testing

```bash
# No formal test framework is currently configured
# Run the game directly to test functionality
love .
```

## Architecture Overview

### Core Framework Stack

- **LÖVE2D** - Base game engine and graphics
- **Prism** - ECS framework with roguelike utilities
- **Spectrum** - Display and state management (Prism module)
- **Geometer** - Map generation and level design (Prism module)

### Module System

The game uses a modular architecture with the following structure:

```
modules/
├── game/              # Main game module
│   ├── module.lua     # Module initialization
│   ├── actors/        # Entity definitions
│   ├── actions/       # Action system (move, wait, etc.)
│   ├── cells/         # Tile/terrain types
│   ├── components/    # ECS components
│   └── systems/      # System implementations
gamestates/            # Game state managers
display/               # Sprite assets and graphics
```

### Entity-Component-System (ECS) Architecture

**Actors**: Game entities defined in `modules/game/actors/`

- Example: `player.lua` - Player actor with components (Position, Drawable, Controller, etc.)

**Components**: Data containers attached to actors

- Built-in: `Position`, `Drawable`, `Collider`, `Controller`, `Mover`, `Senses`, `Sight`
- Custom: Game-specific components can be added

**Actions**: Entity behaviors defined in `modules/game/actions/`

- Target-based system with validation and execution phases
- Example: `move.lua` - Movement action with collision detection

**Systems**: Game logic processors in `modules/game/systems/`

- Event-driven systems that respond to game state changes
- Example: `fallsystem.lua` - Handles falling when actors move

### Input System

Controls are defined in `controls.lua` using Spectrum's input system:

- Supports keyboard, gamepad, mouse, and joystick inputs
- Directional movement with 8-way support
- Configurable control mappings and pairs

### Display System

- Terminal-based display using sprite fonts
- Configurable dimensions (81x41 default)
- Sprite atlas system for tile-based graphics
- Automatic window sizing to match terminal dimensions

## Code Conventions

### Lua Style

- **Indentation**: 3 spaces (configured in `stylua.toml`)
- **Naming**: PascalCase for classes, camelCase for variables and functions
- **Module pattern**: Use `return` at end of files for module exports
- **Type hints**: Use LDoc-style comments (`---@class`, `---@param`, `---@return`)

### Prism-Specific Patterns

- **Actor registration**: Use `prism.registerActor(name, factoryFunction)`
- **Component composition**: Build actors with `prism.Actor.fromComponents{}`
- **Action targets**: Define with `prism.Target():isPrototype(type):range(distance)`
- **System extension**: Extend base systems with `prism.System:extend "SystemName"`

### Module Loading

Load modules in `main.lua` using:

```lua
prism.loadModule("module/path")
```

### Project Structure Guidelines

- Keep game logic in `modules/game/` subdirectories
- Separate actors, actions, cells, components, and systems
- Use `gamestates/` for different game states (menu, playing, etc.)
- Store assets in appropriate subdirectories (`display/`, etc.)

## Build System

### makelove Configuration

- Targets: Windows (32/64-bit), Linux (AppImage)
- LÖVE version: 11.4
- Includes: Git-tracked files, prism engine modules
- Excludes: Hidden files and directories

### Dependencies

- **LÖVE2D 11.4+** - Primary runtime dependency
- **Prism engine** - Game framework (included as submodule)
- **StyLua** - Code formatter (development)
- **makelove** - Build tool (optional, for releases)

## Important Notes

- The default cell type is set to `prism.cells.Pit` for new maps
- All game objects use the ECS architecture - avoid inheritance-based designs
- Input handling is event-driven through Spectrum's system
- Display is terminal-based with sprite atlas support
- Movement is grid-based with collision detection
- The template is designed for turn-based roguelike development
