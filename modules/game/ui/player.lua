--- @class PlayerUITools
local PlayerUITools = {}

---@param player Actor
---@param display Display
function PlayerUITools.DisplayLightSource(display, player)
   local lightSource = player:get(prism.components.LightSource)
   if lightSource then
      local statusText = lightSource:getStatusString()
      local statusColor = prism.Color4.WHITE

      -- Change color based on fuel level
      if lightSource:needsFuel() then
         statusColor = prism.Color4.RED
      elseif not lightSource.isActive then
         statusColor = prism.Color4.GREY
      elseif lightSource:getFuelPercentage() < 0.5 then
         statusColor = prism.Color4.YELLOW
      end

      display:putString(1, 2, "Light: " .. statusText, statusColor)

      -- Add fuel bar
      local fuelPercent = lightSource:getFuelPercentage()
      local barWidth = 20
      local filledWidth = math.floor(fuelPercent * barWidth)
      local fuelBar = "[" .. string.rep("=", filledWidth) .. string.rep("-", barWidth - filledWidth) .. "]"
      display:putString(1, 3, "Fuel: " .. fuelBar, statusColor)

      -- Add toggle instruction
      display:putString(1, 4, "Press 'T' to toggle light", prism.Color4.GREY)
   end
end

return PlayerUITools
