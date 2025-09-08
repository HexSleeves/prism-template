--- @class Transition : Action
--- Action for transitioning between depth levels
local Transition = prism.Action:extend("Transition")
Transition.name = "transition"
Transition.targets = {}

Transition.requiredComponents = {
   prism.components.DepthTracker,
}

--- @param targetDepth integer The target depth level
function Transition:__new(targetDepth)
   self.targetDepth = targetDepth
end

--- Validates if the transition action can be performed
--- @param _level Level The current level
--- @return boolean True if the action is valid
function Transition:canPerform(_level)
   local depthTracker = self.owner:expect(prism.components.DepthTracker)
   return depthTracker:canAccessDepth(self.targetDepth)
end

--- Executes the transition action
--- @param level Level The current level
function Transition:perform(level)
   local depthTracker = self.owner:expect(prism.components.DepthTracker)

   -- Get the level transition system
   local transitionSystem = level:getSystem(prism.systems.LevelTransition)
   if not transitionSystem then error("No LevelTransitionSystem found in level") end

   -- Perform the transition
   transitionSystem:requestTransition(self.owner, self.targetDepth, level)
end

return Transition
