--- @class GameInputHandler
--- Handles all input processing and control logic for the Into the Depths game
local GameInputHandler = {}

local controls = require("controls")

--- Processes movement input and returns appropriate action
--- @param owner Actor The actor performing the movement
--- @param level Level The current level
--- @return Action? Movement or kick action, or nil if no valid action
function GameInputHandler.processMovement(owner, level)
   if not controls.move.pressed then return nil end

   local destination = owner:getPosition() + controls.move.vector
   local move = prism.actions.Move(owner, destination)

   -- Try to move first
   if level:canPerform(move) then return move end

   -- If we couldn't move, try kicking an actor in front of us
   local target = level:query():at(destination:decompose()):first()
   local kick = prism.actions.Kick(owner, target)

   if level:canPerform(kick) then return kick end

   return nil
end

--- Processes basic game controls (quit, wait)
--- @param owner Actor The actor performing the action
--- @return Action? Wait action or nil
function GameInputHandler.processBasicControls(owner)
   if controls.quit.pressed then
      love.event.quit()
      return nil
   end

   if controls.wait.pressed then return prism.actions.Wait(owner) end

   return nil
end

--- Processes light toggle input
--- @param owner Actor The actor with the light source
--- @param level Level The current level
--- @return Action? ToggleLight action or nil
function GameInputHandler.processLightToggle(owner, level)
   if not controls.toggle_light.pressed then return nil end

   local toggleLight = prism.actions.ToggleLight(owner)
   if level:canPerform(toggleLight) then return toggleLight end

   return nil
end

--- Processes mining input
--- @param owner Actor The actor performing the mining
--- @param level Level The current level
--- @return Action? Mine action or nil
function GameInputHandler.processMining(owner, level)
   if not controls.mine.pressed then return nil end

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

   -- Try mining in each direction around the player
   for _, dir in ipairs(directions) do
      local target = position + dir
      local mine = prism.actions.Mine(owner, target)
      if level:canPerform(mine) then return mine end
   end

   return nil
end

--- Processes return to surface input
--- @param owner Actor The actor requesting return
--- @param level Level The current level
--- @param state table The level state for handling messages
--- @return Action? Return action or nil
function GameInputHandler.processReturnToSurface(owner, level, state)
   if not (controls.return_surface and controls.return_surface.pressed) then return nil end

   local depthTracker = owner:get(prism.components.DepthTracker)
   if not depthTracker then return nil end

   local currentDepth = depthTracker:getCurrentDepth()
   if currentDepth == 0 then
      prism.logger.info("Already at surface level")
      return nil
   end

   -- Send transition message to return to surface
   if state and state.handleMessage then
      state:handleMessage({
         type = "level_transition",
         targetDepth = 0,
      })
   end

   return nil
end

--- Processes interaction input (mine shafts, NPCs, etc.)
--- @param owner Actor The actor performing the interaction
--- @param level Level The current level
--- @param state table The level state for handling messages
--- @return Action? Interaction action or nil
function GameInputHandler.processInteraction(owner, level, state)
   if not (controls.interact and controls.interact.pressed) then return nil end

   local position = owner:getPosition()
   if not position then
      prism.logger.warn("No position found for owner during interaction")
      return nil
   end

   local cell = level:getCell(position:decompose())

   -- Handle mine shaft interaction
   if cell and cell:get(prism.components.Name) and cell:get(prism.components.Name).name == "Mine Shaft" then
      local depthTracker = owner:get(prism.components.DepthTracker)
      if depthTracker then
         local currentDepth = depthTracker:getCurrentDepth()
         local targetDepth = currentDepth == 0 and 1 or (currentDepth - 1)

         -- Send transition message to the state
         if state and state.handleMessage then
            state:handleMessage({
               type = "level_transition",
               targetDepth = targetDepth,
            })
         end
      end
      return nil
   end

   -- Handle NPC/service interaction
   local nearbyActors = level:query():at(position:decompose()):gather()
   for _, actor in ipairs(nearbyActors) do
      if actor ~= owner and actor:has(prism.components.CityService) then
         local interact = prism.actions.Interact(owner, actor)
         if level:canPerform(interact) then return interact end
      end
   end

   -- Check adjacent tiles for interactive objects
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
      local targetPos = position + dir
      local adjacentActors = level:query():at(targetPos:decompose()):gather()

      for _, actor in ipairs(adjacentActors) do
         if actor:has(prism.components.CityService) then
            local interact = prism.actions.Interact(owner, actor)
            if level:canPerform(interact) then return interact end
         end
      end
   end

   return nil
end

--- Processes city service commands (buy, sell, deposit, withdraw)
--- @param owner Actor The actor performing the action
--- @param level Level The current level
--- @return Action? Service action or nil
function GameInputHandler.processCityServices(owner, level)
   -- This would be expanded to handle keyboard input for city services
   -- For now, these are handled through the interaction system
   -- Future: Could add hotkeys like 'b' for buy menu, 's' for sell menu, etc.
   return nil
end

--- Main input processing function that coordinates all input handlers
--- @param owner Actor The actor (usually the player)
--- @param level Level The current level
--- @param state table The level state for handling messages
--- @return Action? The action to perform, or nil if no action
function GameInputHandler.processInput(owner, level, state)
   -- Update controls first
   controls:update()

   -- Process input in priority order

   -- 1. Movement (highest priority for responsiveness)
   local action = GameInputHandler.processMovement(owner, level)
   if action then return action end

   -- 2. Basic controls (quit, wait)
   action = GameInputHandler.processBasicControls(owner)
   if action then return action end

   -- 3. Light toggle
   action = GameInputHandler.processLightToggle(owner, level)
   if action then return action end

   -- 4. Mining
   action = GameInputHandler.processMining(owner, level)
   if action then return action end

   -- 5. Return to surface
   action = GameInputHandler.processReturnToSurface(owner, level, state)
   if action then return action end

   -- 6. Interaction (mine shafts, NPCs)
   action = GameInputHandler.processInteraction(owner, level, state)
   if action then return action end

   -- 7. City services (future expansion)
   action = GameInputHandler.processCityServices(owner, level)
   if action then return action end

   return nil
end

--- Checks if any input is currently pressed (useful for UI updates)
--- @return boolean True if any input is currently active
function GameInputHandler.hasActiveInput()
   return controls.move.pressed
      or controls.quit.pressed
      or controls.wait.pressed
      or controls.toggle_light.pressed
      or controls.mine.pressed
      or (controls.interact and controls.interact.pressed)
      or (controls.return_surface and controls.return_surface.pressed)
end

--- Gets a string description of currently pressed inputs (useful for debugging)
--- @return string Description of active inputs
function GameInputHandler.getActiveInputDescription()
   local active = {}

   if controls.move.pressed then
      table.insert(active, "move(" .. controls.move.vector.x .. "," .. controls.move.vector.y .. ")")
   end
   if controls.quit.pressed then table.insert(active, "quit") end
   if controls.wait.pressed then table.insert(active, "wait") end
   if controls.toggle_light.pressed then table.insert(active, "toggle_light") end
   if controls.mine.pressed then table.insert(active, "mine") end
   if controls.interact and controls.interact.pressed then table.insert(active, "interact") end
   if controls.return_surface and controls.return_surface.pressed then table.insert(active, "return_surface") end

   return table.concat(active, ", ")
end

return GameInputHandler
