---@class ToggleLightAction : Action
local ToggleLight = prism.Action:extend("ToggleLightAction")
ToggleLight.name = "ToggleLight"
ToggleLight.targets = {}
ToggleLight.requiredComponents = {
   prism.components.LightSource,
}

function ToggleLight:canPerform(level)
   local lightSource = self.owner:get(prism.components.LightSource)
   return lightSource ~= nil
end

--- @param level Level
function ToggleLight:perform(level)
   local lightSource = self.owner:get(prism.components.LightSource)
   if lightSource then
      local wasActive = lightSource.isActive
      lightSource:toggle()

      -- Trigger light source change event for sight updates
      level:trigger("lightSourceChanged", self.owner, lightSource)

      -- Log the action
      if prism.logger then
         local status = lightSource.isActive and "on" or "off"
         prism.logger.info(self.owner:getName() .. " turned their " .. lightSource.lightType .. " " .. status)
      end
   end
end

return ToggleLight
