--- @class LightSource : Component
--- @field radius integer Light radius in tiles
--- @field fuel integer Remaining fuel/battery (0 = infinite for magical lights)
--- @field maxFuel integer Maximum fuel capacity
--- @field fuelConsumption number Fuel consumed per turn
--- @field lightType string Type of light ("torch", "lantern", "magical")
--- @field isActive boolean Whether the light source is currently active
local LightSource = prism.Component:extend("LightSource")
LightSource.name = "LightSource"

--- Light source type definitions
LightSource.TYPES = {
   TORCH = "torch",
   LANTERN = "lantern",
   MAGICAL = "magical",
}

--- Creates a new LightSource component
--- @param options table Configuration options
--- @param options.radius integer Light radius in tiles
--- @param options.fuel integer? Starting fuel (defaults based on type)
--- @param options.lightType string? Type of light source (defaults to "torch")
--- @param options.isActive boolean? Whether light starts active (defaults to true)
--- @return LightSource
function LightSource:__new(options)
   options = options or {}

   self.lightType = options.lightType or LightSource.TYPES.TORCH
   self.radius = options.radius or self:getDefaultRadius()
   self.isActive = options.isActive ~= false -- defaults to true unless explicitly false

   -- Set fuel and consumption based on light type
   if self.lightType == LightSource.TYPES.MAGICAL then
      self.fuel = 0 -- Infinite fuel for magical lights
      self.maxFuel = 0
      self.fuelConsumption = 0
   else
      self.maxFuel = options.fuel or self:getDefaultFuel()
      self.fuel = self.maxFuel
      self.fuelConsumption = options.fuelConsumption or self:getDefaultConsumption()
   end
end

--- Gets the default radius for the light type
--- @return integer Default radius
function LightSource:getDefaultRadius()
   if self.lightType == LightSource.TYPES.TORCH then
      return 3
   elseif self.lightType == LightSource.TYPES.LANTERN then
      return 4
   elseif self.lightType == LightSource.TYPES.MAGICAL then
      return 5
   end
   return 3
end

--- Gets the default fuel for the light type
--- @return integer Default fuel amount
function LightSource:getDefaultFuel()
   if self.lightType == LightSource.TYPES.TORCH then
      return 100 -- 100 turns
   elseif self.lightType == LightSource.TYPES.LANTERN then
      return 200 -- 200 turns
   end
   return 100
end

--- Gets the default fuel consumption for the light type
--- @return number Default fuel consumption per turn
function LightSource:getDefaultConsumption()
   if self.lightType == LightSource.TYPES.TORCH then
      return 1.0 -- 1 fuel per turn
   elseif self.lightType == LightSource.TYPES.LANTERN then
      return 0.5 -- 0.5 fuel per turn (lasts longer)
   end
   return 1.0
end

--- Consumes fuel for one turn
--- @return boolean True if light is still active, false if fuel depleted
function LightSource:consumeFuel()
   if not self.isActive or self.fuel == 0 then return self.isActive end

   self.fuel = math.max(0, self.fuel - self.fuelConsumption)

   -- Automatically deactivate if fuel runs out
   if self.fuel <= 0 then
      self.isActive = false
      return false
   end

   return true
end

--- Toggles the light source on/off
--- @return boolean New active state
function LightSource:toggle()
   if self.fuel > 0 or self.lightType == LightSource.TYPES.MAGICAL then
      self.isActive = not self.isActive
   else
      self.isActive = false
   end
   return self.isActive
end

--- Activates the light source if it has fuel
--- @return boolean True if successfully activated
function LightSource:activate()
   if self.fuel > 0 or self.lightType == LightSource.TYPES.MAGICAL then
      self.isActive = true
      return true
   end
   return false
end

--- Deactivates the light source
function LightSource:deactivate()
   self.isActive = false
end

--- Gets the effective light radius (0 if inactive or no fuel)
--- @return integer Effective light radius
function LightSource:getEffectiveRadius()
   if not self.isActive or (self.fuel <= 0 and self.lightType ~= LightSource.TYPES.MAGICAL) then return 0 end
   return self.radius
end

--- Refuels the light source
--- @param amount integer Amount of fuel to add
--- @return integer Actual amount added (limited by max fuel)
function LightSource:refuel(amount)
   if self.lightType == LightSource.TYPES.MAGICAL then
      return 0 -- Magical lights don't need fuel
   end

   local oldFuel = self.fuel
   self.fuel = math.min(self.maxFuel, self.fuel + amount)
   return self.fuel - oldFuel
end

--- Gets fuel percentage (0.0 to 1.0)
--- @return number Fuel percentage, or 1.0 for magical lights
function LightSource:getFuelPercentage()
   if self.lightType == LightSource.TYPES.MAGICAL or self.maxFuel == 0 then return 1.0 end
   return self.fuel / self.maxFuel
end

--- Checks if the light source needs fuel
--- @return boolean True if fuel is low (< 25%)
function LightSource:needsFuel()
   if self.lightType == LightSource.TYPES.MAGICAL then return false end
   return self:getFuelPercentage() < 0.25
end

--- Gets a string representation of the light source status
--- @return string Status description
function LightSource:getStatusString()
   if self.lightType == LightSource.TYPES.MAGICAL then
      return self.isActive and "Magical light (active)" or "Magical light (inactive)"
   end

   local status = string.format("%s (%d/%d fuel)", self.lightType, math.floor(self.fuel), self.maxFuel)

   if not self.isActive then
      status = status .. " [OFF]"
   elseif self:needsFuel() then
      status = status .. " [LOW FUEL]"
   end

   return status
end

return LightSource
