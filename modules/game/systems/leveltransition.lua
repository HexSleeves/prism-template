--- @class LevelTransitionSystem : System
--- System for managing transitions between different depth levels
local LevelTransitionSystem = prism.System:extend("LevelTransitionSystem")

--- Initializes the level transition system
function LevelTransitionSystem:__new()
   prism.System.__new(self)
   -- Cache for generated levels to avoid regenerating them
   self.levelCache = {}
   -- Callback function for level transitions (set by game state)
   self.transitionCallback = nil
end

--- Sets the callback function for level transitions
--- @param callback function Function to call when a transition occurs
function LevelTransitionSystem:setTransitionCallback(callback)
   self.transitionCallback = callback
end

--- Handles level transition requests
--- @param actor Actor The actor requesting the transition
--- @param targetDepth integer The target depth level
--- @param level Level The current level
--- @return boolean True if transition was successful
function LevelTransitionSystem:requestTransition(actor, targetDepth, level)
   local depthTracker = actor:get(prism.components.DepthTracker)

   if not depthTracker then
      prism.logger.warn("Actor attempting level transition without DepthTracker component")
      return false
   end

   -- Validate depth access
   if not self:canTransitionTo(actor, targetDepth) then
      prism.logger.info(
         "Cannot access depth " .. targetDepth .. " from current max depth " .. depthTracker:getMaxDepthReached()
      )
      return false
   end

   -- Validate transition requirements
   if not self:validateTransitionRequirements(actor, targetDepth, level) then
      prism.logger.info("Transition requirements not met for depth " .. targetDepth)
      return false
   end

   -- Update depth tracker
   depthTracker:setDepth(targetDepth)

   -- Log the transition
   prism.logger.info("Transitioning to depth " .. targetDepth)

   -- Trigger the actual level transition through callback
   if self.transitionCallback then self.transitionCallback(actor, targetDepth, level) end

   return true
end

--- Validates transition requirements (equipment, keys, etc.)
--- @param actor Actor The actor requesting transition
--- @param targetDepth integer The target depth
--- @param level Level The current level
--- @return boolean True if requirements are met
function LevelTransitionSystem:validateTransitionRequirements(actor, targetDepth, level)
   -- Basic validation: ensure actor has required equipment for deeper levels
   if targetDepth > 0 then
      -- Check for mining tool (required for mine levels)
      local hasMiningTool = false
      local nearbyActors = level:query():at(actor:getPosition():decompose()):collect()

      for _, nearbyActor in ipairs(nearbyActors) do
         if nearbyActor:has(prism.components.MiningTool) then
            hasMiningTool = true
            break
         end
      end

      if not hasMiningTool then
         prism.logger.info("Mining tool required for mine levels")
         return false
      end

      -- Check for light source (recommended for deeper levels)
      local hasLightSource = false
      for _, nearbyActor in ipairs(nearbyActors) do
         if nearbyActor:has(prism.components.LightSource) then
            hasLightSource = true
            break
         end
      end

      if not hasLightSource and targetDepth > 2 then
         prism.logger.warn("Light source recommended for deeper levels")
         -- Don't block transition, just warn
      end
   end

   return true
end

--- Creates a return-to-surface transition for emergency exits
--- @param actor Actor The actor requesting return
--- @param level Level The current level
--- @return boolean True if return was successful
function LevelTransitionSystem:returnToSurface(actor, level)
   prism.logger.info("Emergency return to surface initiated")
   return self:requestTransition(actor, 0, level)
end

--- Gets the current depth of an actor
--- @param actor Actor The actor to check
--- @return integer? The current depth, or nil if no DepthTracker component
function LevelTransitionSystem:getCurrentDepth(actor)
   local depthTracker = actor:get(prism.components.DepthTracker)
   return depthTracker and depthTracker:getCurrentDepth() or nil
end

--- Checks if an actor can transition to a specific depth
--- @param actor Actor The actor to check
--- @param targetDepth integer The target depth
--- @return boolean True if the transition is allowed
function LevelTransitionSystem:canTransitionTo(actor, targetDepth)
   local depthTracker = actor:get(prism.components.DepthTracker)
   if not depthTracker then return false end

   -- Allow returning to any previously visited depth
   if targetDepth <= depthTracker:getMaxDepthReached() then return true end

   -- Allow going one level deeper than max reached
   if targetDepth == depthTracker:getMaxDepthReached() + 1 then return true end

   return false
end

--- Caches a generated level for future use
--- @param depth integer The depth level
--- @param levelData table The level data to cache
function LevelTransitionSystem:cacheLevel(depth, levelData)
   self.levelCache[depth] = levelData
end

--- Retrieves a cached level
--- @param depth integer The depth level
--- @return table? The cached level data, or nil if not cached
function LevelTransitionSystem:getCachedLevel(depth)
   return self.levelCache[depth]
end

--- Clears the level cache (useful for memory management)
function LevelTransitionSystem:clearCache()
   self.levelCache = {}
end

return LevelTransitionSystem
