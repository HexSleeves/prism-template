local LevelGenerator = require("modules.game.levelgenerator")
local GameDisplayHandler = require("modules.game.ui.display")
local GameInputHandler = require("modules.game.input.handler")

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
      prism.systems.EnhancedSight(),
      prism.systems.LevelTransition(),
      prism.systems.LightManagement(),
      prism.systems.MonsterFactory(),
      prism.systems.MonsterScaling(),
      prism.systems.CityServices(),
      prism.systems.GameState()
   )

   -- Initialize with the created level and display
   spectrum.LevelState.__new(self, builder:build(), display)

   -- Initialize senses system for vision
   local sensesSystem = self.level:getSystem(prism.systems.Senses)
   if sensesSystem then sensesSystem:postInitialize(self.level) end

   -- Initialize the transition system callback
   self:initializeTransitionSystem()

   -- Initialize game state for persistent data
   self:initializeGameState()
end

--- Initializes the level transition system callback
function IntoTheDepthsLevelState:initializeTransitionSystem()
   local transitionSystem = self.level:getSystem(prism.systems.LevelTransition)
   if transitionSystem then
      transitionSystem:setTransitionCallback(function(actor, targetDepth, currentLevel)
         self:performLevelTransition(actor, targetDepth, currentLevel)
      end)
   end
end

--- Initializes the game state system for persistent data
function IntoTheDepthsLevelState:initializeGameState()
   local gameStateSystem = self.level:getSystem(prism.systems.GameState)
   if gameStateSystem then
      -- Set initial progress if this is a new game
      local progress = gameStateSystem:getProgress()
      if progress.maxDepthReached == 0 and self.currentDepth == 0 then
         gameStateSystem:updateProgress("city", "surface_city")
         prism.logger.info("Initialized new game state")
      end
   end
end

--- Performs the actual level transition
--- @param actor Actor The actor transitioning
--- @param targetDepth integer The target depth
--- @param currentLevel Level The current level
function IntoTheDepthsLevelState:performLevelTransition(actor, targetDepth, currentLevel)
   -- Get the game state system for persistent state management
   local gameStateSystem = currentLevel:getSystem(prism.systems.GameState)
   if not gameStateSystem then
      prism.logger.warn("No GameState system found, using fallback state management")
      gameStateSystem = nil
   end

   -- Save current level as explored if it's not the surface
   if self.currentDepth > 0 and gameStateSystem then
      gameStateSystem:saveExploredLevel(self.currentDepth, {
         depth = self.currentDepth,
         timestamp = os.time(),
         playerLastPosition = actor:getPosition(),
      })
   end

   -- Save current player state using GameState system if available
   local playerState
   if gameStateSystem then
      playerState = gameStateSystem:savePlayerState(actor, currentLevel)
      -- Also save equipment separately for better persistence
      gameStateSystem:savePlayerEquipment(actor, currentLevel)
   else
      playerState = self:savePlayerState(actor)
   end

   -- Update progress tracking
   if gameStateSystem then gameStateSystem:updateProgress("depth", targetDepth) end

   -- Generate or load the target level
   local newLevel = self:generateOrLoadLevel(targetDepth)

   -- Place player in the new level using GameState system if available
   if gameStateSystem then
      local spawnPosition = self:findSpawnLocation(newLevel, targetDepth)
      local newGameStateSystem = newLevel:getSystem(prism.systems.GameState)
      if newGameStateSystem then
         -- Transfer game state to new level
         newGameStateSystem:importGameState(gameStateSystem:exportGameState())
         local restoredPlayer = newGameStateSystem:restorePlayerState(newLevel, spawnPosition)
         -- Restore equipment separately
         if restoredPlayer then newGameStateSystem:restorePlayerEquipment(newLevel, spawnPosition) end
      else
         self:placePlayerInLevel(newLevel, playerState, targetDepth)
      end
   else
      self:placePlayerInLevel(newLevel, playerState, targetDepth)
   end

   -- Update the level state
   self.level = newLevel
   self.currentDepth = targetDepth

   -- Initialize systems for the new level
   self:initializeNewLevel()

   -- Auto-save after successful transition
   self:autoSave()

   prism.logger.info("Level transition completed to depth " .. targetDepth)
end

--- Saves the current player state for transition
--- @param actor Actor The player actor
--- @return table Player state data
function IntoTheDepthsLevelState:savePlayerState(actor)
   local state = {
      position = actor:getPosition(),
      components = {},
      nearbyItems = {},
   }

   -- Save important components
   local componentsToSave = {
      prism.components.DepthTracker,
      prism.components.PlayerController,
      prism.components.Name,
      prism.components.Drawable,
      prism.components.Collider,
      prism.components.Position,
      prism.components.Senses,
      prism.components.Sight,
   }

   for _, componentType in ipairs(componentsToSave) do
      local component = actor:get(componentType)
      if component then state.components[componentType] = component end
   end

   -- Save nearby items (equipment, tools, etc.)
   local nearbyActors = self.level:query():at(actor:getPosition():decompose()):collect()
   for _, nearbyActor in ipairs(nearbyActors) do
      if nearbyActor ~= actor then
         table.insert(state.nearbyItems, {
            actor = nearbyActor,
            components = self:saveActorComponents(nearbyActor),
         })
      end
   end

   return state
end

--- Saves components from an actor
--- @param actor Actor The actor to save components from
--- @return table Component data
function IntoTheDepthsLevelState:saveActorComponents(actor)
   local components = {}

   -- Save all components from the actor
   local componentTypes = {
      prism.components.Name,
      prism.components.Drawable,
      prism.components.Collider,
      prism.components.Position,
      prism.components.LightSource,
      prism.components.MiningTool,
      prism.components.Item,
   }

   for _, componentType in ipairs(componentTypes) do
      local component = actor:get(componentType)
      if component then components[componentType] = component end
   end

   return components
end

--- Generates or loads a level for the target depth
--- @param targetDepth integer The target depth
--- @return Level The generated or loaded level
function IntoTheDepthsLevelState:generateOrLoadLevel(targetDepth)
   -- Check if we have a cached level
   local transitionSystem = self.level:getSystem(prism.systems.LevelTransition)
   local cachedLevel = transitionSystem and transitionSystem:getCachedLevel(targetDepth)

   if cachedLevel then
      prism.logger.info("Loading cached level for depth " .. targetDepth)
      return cachedLevel
   end

   -- Generate new level
   prism.logger.info("Generating new level for depth " .. targetDepth)
   local builder = prism.LevelBuilder(prism.cells.Wall)

   if targetDepth == 0 then
      -- Generate surface city
      LevelGenerator.generateSurfaceCity(builder)
   else
      -- Generate mine level
      LevelGenerator.generateMineLevel(builder, targetDepth)
   end

   -- Add core systems
   builder:addSystems(
      prism.systems.Senses(),
      prism.systems.EnhancedSight(),
      prism.systems.LevelTransition(),
      prism.systems.LightManagement(),
      prism.systems.MonsterFactory(),
      prism.systems.MonsterScaling(),
      prism.systems.CityServices(),
      prism.systems.GameState()
   )

   local newLevel = builder:build()

   -- Cache the level for future use
   if transitionSystem then transitionSystem:cacheLevel(targetDepth, newLevel) end

   -- Check if this level has been explored before and mark it if so
   local gameStateSystem = self.level:getSystem(prism.systems.GameState)
   local exploredLevel = gameStateSystem and gameStateSystem:getExploredLevel(targetDepth)
   if exploredLevel then
      local newGameStateSystem = newLevel:getSystem(prism.systems.GameState)
      if newGameStateSystem then newGameStateSystem:saveExploredLevel(targetDepth, exploredLevel) end
   end

   return newLevel
end

--- Places the player in the new level at an appropriate location
--- @param level Level The target level
--- @param playerState table The saved player state
--- @param targetDepth integer The target depth
function IntoTheDepthsLevelState:placePlayerInLevel(level, playerState, targetDepth)
   -- Find an appropriate spawn location
   local spawnPosition = self:findSpawnLocation(level, targetDepth)

   -- Create player actor with saved state
   local player = prism.actors.Player()

   -- Restore saved components
   for componentType, component in pairs(playerState.components) do
      if componentType ~= prism.components.Position then -- Position will be set separately
         player:add(component)
      end
   end

   -- Add player to level at spawn position
   level:addActor(player, spawnPosition.x, spawnPosition.y)

   -- Restore nearby items
   for _, itemData in ipairs(playerState.nearbyItems) do
      local itemActor = prism.Actor()

      -- Restore item components
      for componentType, component in pairs(itemData.components) do
         if componentType ~= prism.components.Position then itemActor:add(component) end
      end

      -- Place item near player
      level:addActor(itemActor, spawnPosition.x + 1, spawnPosition.y)
   end
end

--- Finds an appropriate spawn location in the level
--- @param level Level The level to search
--- @param targetDepth integer The target depth
--- @return Vector2 The spawn position
function IntoTheDepthsLevelState:findSpawnLocation(level, targetDepth)
   -- For surface level, spawn in city center
   if targetDepth == 0 then return prism.Vector2(20, 15) end

   -- For mine levels, find a mine shaft or safe floor tile
   local map = level:getMap()
   local width, height = map:getDimensions()

   -- First, try to find a mine shaft
   for x = 0, width - 1 do
      for y = 0, height - 1 do
         local cell = level:getCell(x, y)
         if cell and cell:get(prism.components.Name) and cell:get(prism.components.Name).name == "Mine Shaft" then
            return prism.Vector2(x, y)
         end
      end
   end

   -- If no mine shaft found, find a safe floor tile
   for x = 0, width - 1 do
      for y = 0, height - 1 do
         local cell = level:getCell(x, y)
         if cell and cell:get(prism.components.Name) and cell:get(prism.components.Name).name == "Floor" then
            -- Check if position is safe (no monsters nearby)
            local nearbyActors = level:query():at(x, y):collect()
            local isSafe = true
            for _, actor in ipairs(nearbyActors) do
               if actor:has(prism.components.CombatStats) then
                  isSafe = false
                  break
               end
            end
            if isSafe then return prism.Vector2(x, y) end
         end
      end
   end

   -- Fallback to center of level
   return prism.Vector2(math.floor(width / 2), math.floor(height / 2))
end

--- Initializes systems for the new level
function IntoTheDepthsLevelState:initializeNewLevel()
   -- Initialize senses system
   local sensesSystem = self.level:getSystem(prism.systems.Senses)
   if sensesSystem then sensesSystem:postInitialize(self.level) end

   -- Initialize transition system callback
   self:initializeTransitionSystem()

   -- Initialize monster scaling for current depth
   local monsterScaling = self.level:getSystem(prism.systems.MonsterScaling)
   if monsterScaling then monsterScaling:scaleForDepth(self.currentDepth) end
end

--- @param message {type: string, targetDepth: integer}
function IntoTheDepthsLevelState:handleMessage(message)
   spectrum.LevelState.handleMessage(self, message)

   -- Handle level transition messages
   if message.type == "level_transition" then
      local targetDepth = message.targetDepth
      if targetDepth ~= self.currentDepth then
         -- Get the player actor
         local player = self.level:query(prism.components.PlayerController):first()
         if player then
            -- Use the level transition system to handle the transition
            local transitionSystem = self.level:getSystem(prism.systems.LevelTransition)
            if transitionSystem then transitionSystem:requestTransition(player, targetDepth, self.level) end
         end
      end
   end
end

-- updateDecision is called whenever there's an ActionDecision to handle.
function IntoTheDepthsLevelState:updateDecision(dt, owner, decision)
   -- Process input and get the appropriate action
   local action = GameInputHandler.processInput(owner, self.level, self)

   if action then decision:setAction(action, self.level) end
end

function IntoTheDepthsLevelState:draw()
   local player = self.level:query(prism.components.PlayerController):first()

   -- Use the display handler to render everything
   GameDisplayHandler.render(self.display, self.level, player, false)
end

function IntoTheDepthsLevelState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.Senses):postInitialize(self.level)
end

--- Saves the complete game state to a file
--- @param filename string? The filename to save to (optional)
--- @return boolean True if save was successful
function IntoTheDepthsLevelState:saveGameState(filename)
   filename = filename or "savegame.json"

   local gameStateSystem = self.level:getSystem(prism.systems.GameState)
   if not gameStateSystem then
      prism.logger.warn("No GameState system found, cannot save")
      return false
   end

   -- Get the complete game state
   local gameData = gameStateSystem:exportGameState()

   -- Add current level information
   gameData.currentDepth = self.currentDepth
   gameData.currentLevelType = self.currentDepth == 0 and "surface" or "mine"

   -- Convert to JSON and save
   local success, jsonData = pcall(function()
      return love.data.encode("string", "json", gameData)
   end)

   if not success then
      prism.logger.warn("Failed to encode game state to JSON")
      return false
   end

   local saveSuccess, errorMsg = pcall(function()
      love.filesystem.write(filename, jsonData)
   end)

   if not saveSuccess then
      prism.logger.warn("Failed to write save file: " .. tostring(errorMsg))
      return false
   end

   prism.logger.info("Game state saved to " .. filename)
   return true
end

--- Loads the complete game state from a file
--- @param filename string? The filename to load from (optional)
--- @return boolean True if load was successful
function IntoTheDepthsLevelState:loadGameState(filename)
   filename = filename or "savegame.json"

   -- Check if save file exists
   if not love.filesystem.getInfo(filename) then
      prism.logger.info("No save file found: " .. filename)
      return false
   end

   -- Read and parse the save file
   local success, jsonData = pcall(function()
      return love.filesystem.read(filename)
   end)

   if not success then
      prism.logger.warn("Failed to read save file: " .. filename)
      return false
   end

   local gameData
   success, gameData = pcall(function()
      return love.data.decode("data", "json", jsonData)
   end)

   if not success then
      prism.logger.warn("Failed to parse save file JSON")
      return false
   end

   -- Import the game state
   local gameStateSystem = self.level:getSystem(prism.systems.GameState)
   if not gameStateSystem then
      prism.logger.warn("No GameState system found, cannot load")
      return false
   end

   local importSuccess = gameStateSystem:importGameState(gameData)
   if not importSuccess then
      prism.logger.warn("Failed to import game state")
      return false
   end

   -- Restore current level if specified
   if gameData.currentDepth then
      self.currentDepth = gameData.currentDepth
      prism.logger.info("Game state loaded from " .. filename .. " (depth: " .. self.currentDepth .. ")")
   end

   return true
end

--- Auto-saves the game state (called periodically or on important events)
function IntoTheDepthsLevelState:autoSave()
   local success = self:saveGameState("autosave.json")
   if success then
      prism.logger.info("Auto-save completed")
   else
      prism.logger.warn("Auto-save failed")
   end
end

return IntoTheDepthsLevelState
