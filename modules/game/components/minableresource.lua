--- @class MinableResource : Component
--- @field resourceType string Type of resource ("coal", "copper", "gold", etc.)
--- @field hardness integer Mining difficulty (affects tool requirements)
--- @field quantity integer Amount of resource available
--- @field depthRequired integer Minimum depth where this resource appears
--- @field maxQuantity integer Maximum quantity this resource can contain
--- @field rarity number Spawn probability (0.0 to 1.0)
--- @field value integer Base market value per unit
local MinableResource = prism.Component:extend("MinableResource")
MinableResource.name = "GameMinableResource"

--- Resource type definitions with their properties
MinableResource.TYPES = {
   COAL = {
      name = "coal",
      hardness = 1,
      depthRequired = 1,
      rarity = 0.8,
      value = 5,
      maxQuantity = 10,
   },
   COPPER = {
      name = "copper",
      hardness = 2,
      depthRequired = 2,
      rarity = 0.6,
      value = 15,
      maxQuantity = 8,
   },
   IRON = {
      name = "iron",
      hardness = 3,
      depthRequired = 3,
      rarity = 0.5,
      value = 25,
      maxQuantity = 6,
   },
   GOLD = {
      name = "gold",
      hardness = 4,
      depthRequired = 5,
      rarity = 0.3,
      value = 100,
      maxQuantity = 4,
   },
   GEMS = {
      name = "gems",
      hardness = 5,
      depthRequired = 7,
      rarity = 0.1,
      value = 250,
      maxQuantity = 2,
   },
   MAGICAL_ORE = {
      name = "magical_ore",
      hardness = 6,
      depthRequired = 10,
      rarity = 0.05,
      value = 500,
      maxQuantity = 1,
   },
}

--- Creates a new MinableResource component
--- @param options table|string Configuration options or resource type name
--- @param options.resourceType string? Type of resource (required if options is table)
--- @param options.quantity integer? Starting quantity (defaults based on type)
--- @param options.hardness integer? Mining difficulty override
--- @param options.depthRequired integer? Minimum depth override
--- @param options.value integer? Base value override
--- @return MinableResource
function MinableResource:__new(options)
   -- Handle string parameter (just resource type)
   if type(options) == "string" then options = { resourceType = options } end

   options = options or {}

   -- Validate resource type
   local resourceType = options.resourceType
   if not resourceType then error("MinableResource requires a resourceType") end

   -- Get resource definition
   local resourceDef = self:getResourceDefinition(resourceType)
   if not resourceDef then error("Unknown resource type: " .. tostring(resourceType)) end

   -- Set properties from definition with optional overrides
   self.resourceType = resourceType
   self.hardness = options.hardness or resourceDef.hardness
   self.depthRequired = options.depthRequired or resourceDef.depthRequired
   self.rarity = options.rarity or resourceDef.rarity
   self.value = options.value or resourceDef.value
   self.maxQuantity = options.maxQuantity or resourceDef.maxQuantity

   -- Set quantity (default to random amount based on max)
   if options.quantity then
      self.quantity = math.max(1, math.min(options.quantity, self.maxQuantity))
   else
      self.quantity = math.random(1, self.maxQuantity)
   end

   -- Validate properties
   self:validate()
end

--- Gets the resource definition for a given type
--- @param resourceType string The resource type to look up
--- @return table? Resource definition or nil if not found
function MinableResource:getResourceDefinition(resourceType)
   -- Check predefined types first
   for _, typeDef in pairs(MinableResource.TYPES) do
      if typeDef.name == resourceType then return typeDef end
   end
   return nil
end

--- Validates the resource properties
--- @return boolean True if valid, throws error if invalid
function MinableResource:validate()
   -- Validate hardness
   if not self.hardness or self.hardness < 1 or self.hardness > 10 then
      error("MinableResource hardness must be between 1 and 10, got: " .. tostring(self.hardness))
   end

   -- Validate quantity
   if not self.quantity or self.quantity < 0 then
      error("MinableResource quantity must be non-negative, got: " .. tostring(self.quantity))
   end

   -- Validate depth requirement
   if not self.depthRequired or self.depthRequired < 0 then
      error("MinableResource depthRequired must be non-negative, got: " .. tostring(self.depthRequired))
   end

   -- Validate rarity
   if not self.rarity or self.rarity < 0 or self.rarity > 1 then
      error("MinableResource rarity must be between 0.0 and 1.0, got: " .. tostring(self.rarity))
   end

   -- Validate value
   if not self.value or self.value < 0 then
      error("MinableResource value must be non-negative, got: " .. tostring(self.value))
   end

   return true
end

--- Extracts a specified amount of resource
--- @param amount integer Amount to extract (defaults to 1)
--- @return integer Actual amount extracted
function MinableResource:extract(amount)
   amount = amount or 1
   local extracted = math.min(amount, self.quantity)
   self.quantity = self.quantity - extracted
   return extracted
end

--- Checks if the resource is depleted
--- @return boolean True if no quantity remains
function MinableResource:isDepleted()
   return self.quantity <= 0
end

--- Gets the total value of remaining resources
--- @return integer Total value of remaining quantity
function MinableResource:getTotalValue()
   return self.quantity * self.value
end

--- Checks if this resource can spawn at the given depth
--- @param depth integer The depth level to check
--- @return boolean True if resource can spawn at this depth
function MinableResource:canSpawnAtDepth(depth)
   return depth >= self.depthRequired
end

--- Gets a display name for the resource
--- @return string Human-readable resource name
function MinableResource:getDisplayName()
   local name = self.resourceType:gsub("_", " ")
   return name:gsub("(%a)([%w_']*)", function(first, rest)
      return first:upper() .. rest:lower()
   end)
end

--- Gets a string representation of the resource
--- @return string Resource description
function MinableResource:toString()
   return string.format(
      "%s (x%d, hardness %d, value %d each)",
      self:getDisplayName(),
      self.quantity,
      self.hardness,
      self.value
   )
end

--- Creates a resource appropriate for the given depth
--- @param depth integer The depth level
--- @param resourceType string? Specific resource type (optional)
--- @return MinableResource? New resource or nil if none appropriate
function MinableResource.createForDepth(depth, resourceType)
   local availableTypes = {}

   if resourceType then
      -- Use specific type if provided and valid for depth
      local resource = MinableResource({ resourceType = resourceType })
      if resource:canSpawnAtDepth(depth) then
         return resource
      else
         return nil
      end
   end

   -- Find all types that can spawn at this depth
   for _, typeDef in pairs(MinableResource.TYPES) do
      if depth >= typeDef.depthRequired then table.insert(availableTypes, typeDef) end
   end

   if #availableTypes == 0 then return nil end

   -- Weight selection by rarity (higher rarity = more likely to spawn)
   local totalWeight = 0
   for _, typeDef in ipairs(availableTypes) do
      totalWeight = totalWeight + typeDef.rarity
   end

   local random = math.random() * totalWeight
   local currentWeight = 0

   for _, typeDef in ipairs(availableTypes) do
      currentWeight = currentWeight + typeDef.rarity
      if random <= currentWeight then return MinableResource({ resourceType = typeDef.name }) end
   end

   -- Fallback to first available type
   return MinableResource({ resourceType = availableTypes[1].name })
end

--- Gets all resource types that can spawn at a given depth
--- @param depth integer The depth level
--- @return table List of resource type names
function MinableResource.getAvailableTypesForDepth(depth)
   local types = {}
   for _, typeDef in pairs(MinableResource.TYPES) do
      if depth >= typeDef.depthRequired then table.insert(types, typeDef.name) end
   end
   return types
end

return MinableResource
