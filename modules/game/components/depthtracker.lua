--- @class DepthTracker : Component
--- @field currentDepth integer Current mine depth (0 = surface)
--- @field maxDepthReached integer Deepest level player has accessed
local DepthTracker = prism.Component:extend("DepthTracker")
DepthTracker.name = "DepthTracker"

--- Creates a new DepthTracker component
--- @param currentDepth integer? Starting depth (defaults to 0 for surface)
--- @param maxDepthReached integer? Maximum depth reached (defaults to currentDepth)
--- @return DepthTracker
function DepthTracker:__new(currentDepth, maxDepthReached)
   currentDepth = currentDepth or 0
   maxDepthReached = maxDepthReached or currentDepth
   
   self.currentDepth = currentDepth
   self.maxDepthReached = maxDepthReached
end

--- Updates the current depth and tracks maximum depth reached
--- @param newDepth integer The new depth level
function DepthTracker:setDepth(newDepth)
   self.currentDepth = newDepth
   if newDepth > self.maxDepthReached then
      self.maxDepthReached = newDepth
   end
end

--- Gets the current depth
--- @return integer Current depth level
function DepthTracker:getCurrentDepth()
   return self.currentDepth
end

--- Gets the maximum depth reached
--- @return integer Maximum depth reached
function DepthTracker:getMaxDepthReached()
   return self.maxDepthReached
end

--- Checks if the player can access a specific depth
--- @param targetDepth integer The depth to check access for
--- @return boolean True if the depth is accessible
function DepthTracker:canAccessDepth(targetDepth)
   -- Players can always go back to shallower levels
   if targetDepth <= self.maxDepthReached then
      return true
   end
   
   -- Players can only go one level deeper than their maximum
   return targetDepth <= self.maxDepthReached + 1
end

return DepthTracker