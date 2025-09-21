--- @class InteractAction : Action
local InteractAction = prism.Action:extend("InteractAction")
InteractAction.name = "Interact"

--- @param actor Actor
--- @param target Actor
function InteractAction:__new(actor, target)
   self.actor = actor
   self.target = target
end

function InteractAction:perform()
   local cityService = self.target:get(prism.components.CityService)
   if not cityService then return false, "No service available" end

   if not cityService:canInteract(self.actor) then return false, "Cannot interact with this service" end

   -- Message is automatically sent by the level when action completes

   return true
end

function InteractAction:canPerform()
   if not self.target then return false, "No target specified" end

   local cityService = self.target:get(prism.components.CityService)
   if not cityService then return false, "Target is not a city service" end

   return cityService:canInteract(self.actor)
end

return InteractAction
