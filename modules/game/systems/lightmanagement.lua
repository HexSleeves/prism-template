--- Light Management System that handles fuel consumption and light source updates
--- @class LightManagementSystem : System
local LightManagementSystem = prism.System:extend("LightManagementSystem")

function LightManagementSystem:getRequirements()
   return {}
end

--- Called at the end of each actor's turn to consume fuel from their light sources
--- @param level Level The current level
--- @param actor Actor The actor whose turn just ended
function LightManagementSystem:onTurnEnd(level, actor)
   local lightSource = actor:get(prism.components.LightSource)
   if not lightSource then return end
   
   -- Consume fuel if the light is active
   if lightSource.isActive then
      local wasActive = lightSource:consumeFuel()
      
      -- If the light went out, we might want to notify the player
      if not wasActive and actor:has(prism.components.PlayerController) then
         -- The player's light went out - this could trigger a message or event
         level:trigger("lightSourceDepleted", actor, lightSource)
      end
   end
end

--- Called when an actor is added to the level to initialize light sources
--- @param level Level The current level
--- @param actor Actor The actor that was added
function LightManagementSystem:onActorAdded(level, actor)
   local lightSource = actor:get(prism.components.LightSource)
   if lightSource then
      -- Trigger a sight update when a light source is added
      level:trigger("lightSourceChanged", actor, lightSource)
   end
end

--- Called when an actor is removed from the level
--- @param level Level The current level
--- @param actor Actor The actor that was removed
function LightManagementSystem:onActorRemoved(level, actor)
   local lightSource = actor:get(prism.components.LightSource)
   if lightSource then
      -- Trigger a sight update when a light source is removed
      level:trigger("lightSourceChanged", actor, lightSource)
   end
end

--- Custom event handler for when light sources change state
--- @param actor Actor The actor with the light source
--- @param lightSource LightSource The light source component
function LightManagementSystem:lightSourceChanged(actor, lightSource)
   -- Force a sight update for all actors when light sources change
   -- This ensures that changes in lighting are immediately reflected in visibility
   local level = self.owner -- Systems have an owner property that points to the level
   for sightedActor in level:query(prism.components.Sight):iter() do
      local sensesComponent = sightedActor:get(prism.components.Senses)
      if sensesComponent then
         -- Clear the senses to force a recalculation
         sensesComponent.cells = prism.SparseGrid()
      end
   end
end

--- Custom event handler for when light sources are depleted
--- @param actor Actor The actor whose light source was depleted
--- @param lightSource LightSource The light source component that was depleted
function LightManagementSystem:lightSourceDepleted(actor, lightSource)
   -- Handle light depletion - could show a message, play a sound, etc.
   if prism.logger then
      prism.logger.info(actor:getName() .. "'s " .. lightSource.lightType .. " has run out of fuel!")
   end
end

return LightManagementSystem