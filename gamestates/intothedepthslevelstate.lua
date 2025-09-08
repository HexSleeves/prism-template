local controls = require "controls"
local PlayerUITools = require("modules.game.ui.player")
local LevelGenerator = require("modules.game.levelgenerator")

--- @class IntoTheDepthsLevelState : LevelState
--- A level state for the "Into the Depths" game that supports different level types
--- based on depth (surface city vs mine levels)
---
--- @field path Path
--- @field level Level
--- @field currentDepth integer
--- @overload fun(display: Display, depth: integer?): IntoTheDepthsLevelState
local IntoTheDepthsLevelState = spectrum.LevelState:extend "IntoTheDepthsLevelState"

--- @param display Display
--- @param depth integer? The depth level to generate (0 = surface, 1+ = mine levels)
function IntoTheDepthsLevelState:__new(display, depth)
   depth = depth or 0
   self.currentDepth = depth

   -- Create level based on depth
   --- @type LevelBuilder
   local builder = prism.LevelBuilder(prism.cells.Wall)

   if depth == 0 then
      -- Generate surface city
      LevelGenerator.generateSurfaceCity(builder)

      -- Place the player at a safe starting location in the city
      builder:addActor(prism.actors.Player(), 20, 15)

      -- Add a torch and pickaxe for the player to start with
      builder:addActor(prism.actors.Torch(), 21, 15)
      builder:addActor(prism.actors.Pickaxe(), 19, 15)
   else
      -- Generate mine level
      LevelGenerator.generateMineLevel(builder, depth)

      -- Place the player near the entrance shaft
      -- In a real implementation, this would be more sophisticated
      builder:addActor(prism.actors.Player(), 10, 10)

      -- Add some basic equipment
      builder:addActor(prism.actors.Torch(), 11, 10)
      builder:addActor(prism.actors.Pickaxe(), 9, 10)
   end

   -- Add core systems
   builder:addSystems(
      prism.systems.Senses(),
      prism.systems.LevelTransition(),
      prism.systems.LightManagement(),
      prism.systems.EnhancedSight(),
      prism.systems.MonsterFactory(),
      prism.systems.MonsterScaling()
   )

   -- Initialize with the created level and display
   spectrum.LevelState.__new(self, builder:build(), display)
end

--- @param message {type: string, targetDepth: integer}
function IntoTheDepthsLevelState:handleMessage(message)
   spectrum.LevelState.handleMessage(self, message)

   -- Handle level transition messages
   if message.type == "level_transition" then
      local targetDepth = message.targetDepth
      if targetDepth ~= self.currentDepth then
         -- Update current depth
         self.currentDepth = targetDepth
         -- TODO: In future implementation, this will trigger actual level transition
         -- For now, we just update the depth tracker on the player
         local player = self.level:query(prism.components.PlayerController):first()
         if player then
            local depthTracker = player:get(prism.components.DepthTracker)
            if depthTracker then depthTracker:setDepth(targetDepth) end
         end
      end
   end
end

-- updateDecision is called whenever there's an ActionDecision to handle.
function IntoTheDepthsLevelState:updateDecision(dt, owner, decision)
   -- Controls need to be updated each frame.
   controls:update()

   -- Movement controls
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

   -- Basic controls
   if controls.quit.pressed then love.event.quit() end
   if controls.wait.pressed then decision:setAction(prism.actions.Wait(self.decision.actor), self.level) end

   -- Light toggle
   if controls.toggle_light.pressed then
      local toggleLight = prism.actions.ToggleLight(owner)
      if self.level:canPerform(toggleLight) then
         decision:setAction(toggleLight, self.level)
         return
      end
   end

   -- Mining
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

   -- Level transition (interact with mine shafts)
   if controls.interact and controls.interact.pressed then
      local position = owner:getPosition()
      if not position then
         print("no position found for owner: ", owner)
         return
      end
      local cell = self.level:getCell(position:decompose())

      if cell and cell:get(prism.components.Name) and cell:get(prism.components.Name).name == "Mine Shaft" then
         -- Handle mine shaft interaction
         local depthTracker = owner:get(prism.components.DepthTracker)
         if depthTracker then
            local currentDepth = depthTracker:getCurrentDepth()
            local targetDepth

            if currentDepth == 0 then
               -- Going down from surface
               targetDepth = 1
            else
               -- Going up from mine level
               targetDepth = currentDepth - 1
            end

            -- Send transition message
            self:handleMessage({
               type = "level_transition",
               targetDepth = targetDepth,
            })
         end
      end
   end
end

function IntoTheDepthsLevelState:draw()
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
      -- Render the level using the player's senses
      self.display:putSenses(primary, secondary, self.level)
   end

   -- Display UI elements
   if player then
      PlayerUITools.DisplayLightSource(self.display, player)

      -- Display current depth
      local depthTracker = player:get(prism.components.DepthTracker)
      if depthTracker then
         local depth = depthTracker:getCurrentDepth()
         local depthText = depth == 0 and "Surface" or ("Depth: " .. depth)
         self.display:putString(2, 2, depthText, prism.Color4.WHITE)
      end
   end

   -- Render the display
   self.display:draw()
end

function IntoTheDepthsLevelState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.Senses):postInitialize(self.level)
end

return IntoTheDepthsLevelState
