require "debugger"
require "prism"

prism.loadModule("prism/spectrum")
prism.loadModule("prism/extra/sight")
prism.loadModule("prism/extra/inventory")
prism.loadModule("modules/game")

-- Used by Geometer for new maps
prism.defaultCell = prism.cells.Pit

-- Grab our level state and sprite atlas.
local GameLevelState = require "gamestates.gamelevelstate"
local IntoTheDepthsLevelState = require "gamestates.intothedepthslevelstate"

-- Load a sprite atlas and configure the terminal-style display,
love.graphics.setDefaultFilter("nearest", "nearest")
local spriteAtlas = spectrum.SpriteAtlas.fromASCIIGrid("display/wanderlust_16x16.png", 16, 16)
local display = spectrum.Display(81, 41, spriteAtlas, prism.Vector2(16, 16))

-- Automatically size the window to match the terminal dimensions
display:fitWindowToTerminal()

-- spin up our state machine
--- @type GameStateManager
local manager = spectrum.StateManager()

-- we put out levelstate on top here, but you could create a main menu
--- @diagnostic disable-next-line
function love.load()
   -- Use the new Into the Depths level state starting at surface (depth 0)
   manager:push(IntoTheDepthsLevelState(display, 0))
   manager:hook()
   spectrum.Input:hook()
end
