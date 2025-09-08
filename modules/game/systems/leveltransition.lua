--- @class LevelTransitionSystem : System
--- System for managing transitions between different depth levels
local LevelTransitionSystem = prism.System:extend("LevelTransitionSystem")

--- Handles level transition requests
--- @param actor Actor The actor requesting the transition
--- @param targetDepth integer The target depth level
--- @param level Level The current level
--- @return boolean True if transition was successful
function LevelTransitionSystem:requestTransition(actor, targetDepth, level)
   local depthTracker = actor:get(prism.components.DepthTracker)

   if not depthTracker then
      prism.log.warn("Actor attempting level transition without DepthTracker component")
      return false
   end

   -- Validate depth access
   if not depthTracker:canAccessDepth(targetDepth) then
      prism.log.info(
         "Cannot access depth " .. targetDepth .. " from current max depth " .. depthTracker:getMaxDepthReached()
      )
      return false
   end

   -- Update depth tracker
   depthTracker:setDepth(targetDepth)

   -- Log the transition
   prism.log.info("Transitioning to depth " .. targetDepth)

   -- TODO: In future tasks, this will trigger level generation/loading
   -- For now, we just update the depth tracker

   return true
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
   return depthTracker and depthTracker:canAccessDepth(targetDepth) or false
end

return LevelTransitionSystem
