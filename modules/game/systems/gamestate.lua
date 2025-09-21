--- @class GameStateSystem : System
--- System for managing persistent game state across level transitions
local GameStateSystem = prism.System:extend("GameStateSystem")

--- Initializes the game state system
function GameStateSystem:__new()
   prism.System.__new(self)
   -- Persistent game state data
   self.gameState = {
      playerData = {},
      exploredLevels = {},
      globalInventory = {},
      gameProgress = {
         maxDepthReached = 0,
         citiesVisited = {},
         questsCompleted = {},
      },
   }
end

--- Saves the current player state
--- @param player Actor The player actor
--- @param level Level The current level
--- @return table The saved player state
function GameStateSystem:savePlayerState(player, level)
   local state = {
      position = player:getPosition(),
      components = {},
      nearbyItems = {},
      levelDepth = nil,
   }

   -- Save depth information
   local depthTracker = player:get(prism.components.DepthTracker)
   if depthTracker then
      state.levelDepth = depthTracker:getCurrentDepth()
      state.maxDepthReached = depthTracker:getMaxDepthReached()
   end

   -- Save important player components
   local componentsToSave = {
      prism.components.DepthTracker,
      prism.components.PlayerController,
      prism.components.Name,
      prism.components.Drawable,
      prism.components.Collider,
      prism.components.Senses,
      prism.components.Sight,
   }

   for _, componentType in ipairs(componentsToSave) do
      local component = player:get(componentType)
      if component then
         -- Create a deep copy of the component data
         state.components[componentType] = self:deepCopyComponent(component)
      end
   end

   -- Save nearby items (equipment, tools, etc.)
   if player:getPosition() then
      local nearbyActors = level:query():at(player:getPosition():decompose()):collect()
      for _, nearbyActor in ipairs(nearbyActors) do
         if nearbyActor ~= player then
            local itemData = self:saveActorData(nearbyActor)
            if itemData then table.insert(state.nearbyItems, itemData) end
         end
      end
   end

   -- Store in persistent game state
   self.gameState.playerData = state

   return state
end

--- Restores player state in a new level
--- @param level Level The target level
--- @param spawnPosition Vector2 The position to spawn the player
--- @return Actor The restored player actor
function GameStateSystem:restorePlayerState(level, spawnPosition)
   local playerState = self.gameState.playerData
   if not playerState then
      prism.logger.warn("No saved player state found")
      return nil
   end

   -- Create new player actor
   local player = prism.Actor()

   -- Restore saved components
   for componentType, componentData in pairs(playerState.components) do
      if componentType ~= prism.components.Position then -- Position handled separately
         local restoredComponent = self:restoreComponent(componentType, componentData)
         if restoredComponent then player:add(restoredComponent) end
      end
   end

   -- Add player to level at spawn position
   level:addActor(player, spawnPosition.x, spawnPosition.y)

   -- Restore nearby items
   for i, itemData in ipairs(playerState.nearbyItems) do
      local itemActor = self:restoreActor(itemData)
      if itemActor then
         -- Place items in a pattern around the player
         local offsetX = (i - 1) % 3 - 1 -- -1, 0, 1, -1, 0, 1, ...
         local offsetY = math.floor((i - 1) / 3) - 1
         level:addActor(itemActor, spawnPosition.x + offsetX, spawnPosition.y + offsetY)
      end
   end

   return player
end

--- Saves data for an actor (items, equipment, etc.)
--- @param actor Actor The actor to save
--- @return table? The saved actor data, or nil if not saveable
function GameStateSystem:saveActorData(actor)
   local data = {
      components = {},
   }

   -- Save relevant components
   local componentsToSave = {
      prism.components.Name,
      prism.components.Drawable,
      prism.components.Collider,
      prism.components.LightSource,
      prism.components.MiningTool,
      prism.components.Item,
   }

   local hasRelevantComponents = false
   for _, componentType in ipairs(componentsToSave) do
      local component = actor:get(componentType)
      if component then
         data.components[componentType] = self:deepCopyComponent(component)
         hasRelevantComponents = true
      end
   end

   return hasRelevantComponents and data or nil
end

--- Restores an actor from saved data
--- @param actorData table The saved actor data
--- @return Actor? The restored actor, or nil if restoration failed
function GameStateSystem:restoreActor(actorData)
   if not actorData or not actorData.components then return nil end

   local actor = prism.Actor()

   -- Restore components
   for componentType, componentData in pairs(actorData.components) do
      local restoredComponent = self:restoreComponent(componentType, componentData)
      if restoredComponent then actor:add(restoredComponent) end
   end

   return actor
end

--- Creates a deep copy of a component
--- @param component any The component to copy
--- @return any The copied component
function GameStateSystem:deepCopyComponent(component)
   -- For now, return the component as-is
   -- In a full implementation, this would create proper deep copies
   -- to avoid reference issues during state transitions
   return component
end

--- Restores a component from saved data
--- @param componentType any The component type
--- @param componentData any The saved component data
--- @return any? The restored component, or nil if restoration failed
function GameStateSystem:restoreComponent(componentType, componentData)
   -- For now, return the data as-is
   -- In a full implementation, this would properly reconstruct components
   return componentData
end

--- Saves the state of an explored level
--- @param depth integer The depth level
--- @param levelData table The level data to save
function GameStateSystem:saveExploredLevel(depth, levelData)
   self.gameState.exploredLevels[depth] = {
      timestamp = os.time(),
      levelData = levelData,
      explored = true,
   }

   prism.logger.info("Saved explored level data for depth " .. depth)
end

--- Gets saved data for an explored level
--- @param depth integer The depth level
--- @return table? The saved level data, or nil if not explored
function GameStateSystem:getExploredLevel(depth)
   local exploredData = self.gameState.exploredLevels[depth]
   return exploredData and exploredData.levelData or nil
end

--- Checks if a level has been explored
--- @param depth integer The depth level
--- @return boolean True if the level has been explored
function GameStateSystem:isLevelExplored(depth)
   return self.gameState.exploredLevels[depth] ~= nil
end

--- Updates game progress tracking
--- @param progressType string The type of progress ("depth", "city", "quest")
--- @param value any The progress value
function GameStateSystem:updateProgress(progressType, value)
   if progressType == "depth" then
      if value > self.gameState.gameProgress.maxDepthReached then
         self.gameState.gameProgress.maxDepthReached = value
         prism.logger.info("New maximum depth reached: " .. value)
      end
   elseif progressType == "city" then
      if not self.gameState.gameProgress.citiesVisited[value] then
         self.gameState.gameProgress.citiesVisited[value] = true
         prism.logger.info("New city visited: " .. value)
      end
   elseif progressType == "quest" then
      table.insert(self.gameState.gameProgress.questsCompleted, value)
      prism.logger.info("Quest completed: " .. value)
   end
end

--- Gets current game progress
--- @return table The current game progress data
function GameStateSystem:getProgress()
   return self.gameState.gameProgress
end

--- Saves inventory state globally
--- @param inventoryData table The inventory data to save
function GameStateSystem:saveGlobalInventory(inventoryData)
   self.gameState.globalInventory = inventoryData
   prism.logger.info("Global inventory saved")
end

--- Gets the global inventory state
--- @return table The global inventory data
function GameStateSystem:getGlobalInventory()
   return self.gameState.globalInventory
end

--- Saves equipment state (tools, light sources, etc.)
--- @param player Actor The player actor
--- @param level Level The current level
function GameStateSystem:savePlayerEquipment(player, level)
   local equipment = {}

   -- Find equipment near the player
   if player:getPosition() then
      local nearbyActors = level:query():at(player:getPosition():decompose()):collect()
      for _, actor in ipairs(nearbyActors) do
         if actor ~= player then
            -- Check if this is equipment
            if actor:has(prism.components.MiningTool) or actor:has(prism.components.LightSource) then
               local equipmentData = self:saveActorData(actor)
               if equipmentData then table.insert(equipment, equipmentData) end
            end
         end
      end
   end

   self.gameState.playerEquipment = equipment
   prism.logger.info("Player equipment saved: " .. #equipment .. " items")
end

--- Restores player equipment in a new level
--- @param level Level The target level
--- @param playerPosition Vector2 The player's position
function GameStateSystem:restorePlayerEquipment(level, playerPosition)
   local equipment = self.gameState.playerEquipment or {}

   for i, equipmentData in ipairs(equipment) do
      local equipmentActor = self:restoreActor(equipmentData)
      if equipmentActor then
         -- Place equipment near player
         local offsetX = (i - 1) % 2 -- 0, 1, 0, 1, ...
         local offsetY = math.floor((i - 1) / 2)
         level:addActor(equipmentActor, playerPosition.x + offsetX, playerPosition.y + offsetY)
      end
   end

   prism.logger.info("Player equipment restored: " .. #equipment .. " items")
end

--- Exports the complete game state for persistence
--- @return table The complete game state
function GameStateSystem:exportGameState()
   return {
      version = "1.0",
      timestamp = os.time(),
      gameState = self.gameState,
   }
end

--- Imports a complete game state from persistence
--- @param stateData table The game state data to import
--- @return boolean True if import was successful
function GameStateSystem:importGameState(stateData)
   if not stateData or not stateData.gameState then
      prism.logger.warn("Invalid game state data for import")
      return false
   end

   -- Validate version compatibility
   if stateData.version ~= "1.0" then
      prism.logger.warn("Game state version mismatch: " .. tostring(stateData.version))
      -- Could implement version migration here
   end

   self.gameState = stateData.gameState
   prism.logger.info("Game state imported successfully")
   return true
end

--- Clears all saved game state (for new game)
function GameStateSystem:clearGameState()
   self.gameState = {
      playerData = {},
      exploredLevels = {},
      globalInventory = {},
      gameProgress = {
         maxDepthReached = 0,
         citiesVisited = {},
         questsCompleted = {},
      },
   }
   prism.logger.info("Game state cleared")
end

return GameStateSystem
