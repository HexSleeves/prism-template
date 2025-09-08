local controls = require "controls"
local PlayerUITools = require("modules.game.ui.player")

--- @class GameLevelState : LevelState
--- A custom game level state responsible for initializing the level map,
--- handling input, and drawing the state to the screen.
---
--- @field path Path
--- @field level Level
--- @overload fun(display: Display): GameLevelState
local GameLevelState = spectrum.LevelState:extend "GameLevelState"

--- @param display Display
function GameLevelState:__new(display)
   -- Construct a simple test map using MapBuilder.
   -- In a complete game, you'd likely extract this logic to a separate module
   -- and pass in an existing player object between levels.
   local builder = prism.LevelBuilder(prism.cells.Wall)

   builder:rectangle("line", 0, 0, 32, 32, prism.cells.Wall)
   -- Fill the interior with floor tiles
   builder:rectangle("fill", 1, 1, 31, 31, prism.cells.Floor)
   -- Add a small block of walls within the map
   builder:rectangle("fill", 5, 5, 7, 7, prism.cells.Wall)
   -- Add a pit area to the southeast
   builder:rectangle("fill", 20, 20, 25, 25, prism.cells.Pit)

   -- Add some mineable coal deposits around the map
   local coalPositions = {
      { 10, 8 },
      { 14, 10 },
      { 8, 15 },
      { 16, 18 },
      { 22, 12 },
   }

   for _, pos in ipairs(coalPositions) do
      local x, y = pos[1], pos[2]
      builder:setCell(x, y, prism.cells.CoalDeposit())
   end

   -- Place the player character at a starting location
   builder:addActor(prism.actors.Player(), 12, 12)
   -- Add a kobold to chase the player
   -- builder:addActor(prism.actors.Kobold(), 18, 12)
   -- Add a torch for testing light sources
   builder:addActor(prism.actors.Torch(), 15, 15)
   -- Add a pickaxe next to the player for mining
   builder:addActor(prism.actors.Pickaxe(), 13, 12)

   -- Add systems
   builder:addSystems(
      prism.systems.Senses(),
      -- prism.systems.Sight(),
      prism.systems.LevelTransition(),
      prism.systems.LightManagement(),
      prism.systems.EnhancedSight()
   )

   -- Initialize with the created level and display, the heavy lifting is done by
   -- the parent class.
   spectrum.LevelState.__new(self, builder:build(), display)
end

function GameLevelState:handleMessage(message)
   spectrum.LevelState.handleMessage(self, message)

   -- Handle any messages sent to the level state from the level. LevelState
   -- handles a few built-in messages for you, like the decision you fill out
   -- here.

   -- This is where you'd process custom messages like advancing to the next
   -- level or triggering a game over.
end

-- updateDecision is called whenever there's an ActionDecision to handle.
function GameLevelState:updateDecision(dt, owner, decision)
   -- Controls need to be updated each frame.
   controls:update()

   -- Controls are accessed directly via table index.
   if controls.move.pressed then
      local destination = owner:getPosition() + controls.move.vector
      local move = prism.actions.Move(owner, destination)
      if self:setAction(move) then return end

      -- If we couldn't move, try kicking an actor in front of us.
      local target = self.level:query():at(destination:decompose()):first()
      local kick = prism.actions.Kick(owner, target)
      if self.level:canPerform(kick) then
         decision:setAction(kick, self.level)
         return
      end
   end

   if controls.quit.pressed then love.event.quit() end
   if controls.wait.pressed then decision:setAction(prism.actions.Wait(self.decision.actor), self.level) end
   if controls.toggle_light.pressed then
      local toggleLight = prism.actions.ToggleLight(owner)
      if self.level:canPerform(toggleLight) then
         decision:setAction(toggleLight, self.level)
         return
      end
   end

   if controls.mine.pressed then
      -- Try mining in each direction around the player
      local position = owner:getPosition()
      local directions = {
         prism.Vector2(-1, -1),
         prism.Vector2(0, -1),
         prism.Vector2(1, -1),
         prism.Vector2(-1, 0),
         prism.Vector2(1, 0),
         prism.Vector2(-1, 1),
         prism.Vector2(0, 1),
         prism.Vector2(1, 1),
      }

      for _, dir in ipairs(directions) do
         local target = position + dir
         local mine = prism.actions.Mine(owner, target)
         if self.level:canPerform(mine) then
            decision:setAction(mine, self.level)
            return
         end
      end
   end
end

function GameLevelState:draw()
   self.display:clear()

   local player = self.level:query(prism.components.PlayerController):first()

   if not player then
      -- You would normally transition to a game over state
      self.display:putLevel(self.level)
   else
      local position = player:expectPosition()

      local x, y = self.display:getCenterOffset(position:decompose())
      self.display:setCamera(x, y)

      local primary, secondary = self:getSenses()
      -- Render the level using the player’s senses
      self.display:putSenses(primary, secondary, self.level)
   end

   -- custom terminal drawing goes here!

   -- Display light source status
   if player then PlayerUITools.DisplayLightSource(self.display, player) end

   -- Actually render the terminal out and present it to the screen.
   -- You could use love2d to translate and say center a smaller terminal or
   -- offset it for custom non-terminal UI elements. If you do scale the UI
   -- just remember that display:getCellUnderMouse expects the mouse in the
   -- display's local pixel coordinates
   self.display:draw()

   -- custom love2d drawing goes here!
end

function GameLevelState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.Senses):postInitialize(self.level)
end

return GameLevelState
