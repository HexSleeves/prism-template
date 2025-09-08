--- @class MiningTool : Component
--- @field toolType string Type of tool ("pickaxe", "drill", etc.)
--- @field power integer Mining power (affects what can be mined)
--- @field durability integer Current tool durability
--- @field maxDurability integer Maximum tool durability
--- @field efficiency number Mining speed multiplier (1.0 = normal speed)
--- @field repairCost integer Cost to fully repair the tool
local MiningTool = prism.Component:extend("MiningTool")
MiningTool.name = "GameMiningTool"

--- Tool type definitions with their properties
MiningTool.TYPES = {
   BASIC_PICKAXE = {
      name = "basic_pickaxe",
      power = 2,
      maxDurability = 100,
      efficiency = 1.0,
      repairCost = 25,
   },
   IRON_PICKAXE = {
      name = "iron_pickaxe",
      power = 4,
      maxDurability = 200,
      efficiency = 1.2,
      repairCost = 75,
   },
   STEEL_PICKAXE = {
      name = "steel_pickaxe",
      power = 6,
      maxDurability = 300,
      efficiency = 1.5,
      repairCost = 150,
   },
   DRILL = {
      name = "drill",
      power = 8,
      maxDurability = 150,
      efficiency = 2.0,
      repairCost = 200,
   },
   MAGICAL_PICKAXE = {
      name = "magical_pickaxe",
      power = 10,
      maxDurability = 500,
      efficiency = 2.5,
      repairCost = 500,
   },
}

--- Durability degradation rates based on resource hardness
MiningTool.DEGRADATION_RATES = {
   [1] = 1, -- Soft materials (coal)
   [2] = 2, -- Medium materials (copper)
   [3] = 3, -- Hard materials (iron)
   [4] = 5, -- Very hard materials (gold)
   [5] = 8, -- Extremely hard materials (gems)
   [6] = 12, -- Magical materials
}

--- Creates a new MiningTool component
--- @param options table|string Configuration options or tool type name
--- @param options.toolType string? Type of tool (required if options is table)
--- @param options.durability integer? Starting durability (defaults to max)
--- @param options.power integer? Mining power override
--- @param options.efficiency number? Efficiency override
--- @param options.repairCost integer? Repair cost override
--- @return MiningTool
function MiningTool:__new(options)
   -- Handle string parameter (just tool type)
   if type(options) == "string" then options = { toolType = options } end

   options = options or {}

   -- Validate tool type
   local toolType = options.toolType
   if not toolType then error("MiningTool requires a toolType") end

   -- Get tool definition
   local toolDef = self:getToolDefinition(toolType)
   if not toolDef then error("Unknown tool type: " .. tostring(toolType)) end

   -- Set properties from definition with optional overrides
   self.toolType = toolType
   self.power = options.power or toolDef.power
   self.maxDurability = options.maxDurability or toolDef.maxDurability
   self.efficiency = options.efficiency or toolDef.efficiency
   self.repairCost = options.repairCost or toolDef.repairCost

   -- Set durability (default to max unless specified)
   self.durability = options.durability or self.maxDurability

   -- Validate properties
   self:validate()
end

--- Gets the tool definition for a given type
--- @param toolType string The tool type to look up
--- @return table? Tool definition or nil if not found
function MiningTool:getToolDefinition(toolType)
   -- Check predefined types first
   for _, typeDef in pairs(MiningTool.TYPES) do
      if typeDef.name == toolType then return typeDef end
   end
   return nil
end

--- Validates the tool properties
--- @return boolean True if valid, throws error if invalid
function MiningTool:validate()
   -- Validate power
   if not self.power or self.power < 1 or self.power > 20 then
      error("MiningTool power must be between 1 and 20, got: " .. tostring(self.power))
   end

   -- Validate durability
   if not self.durability or self.durability < 0 then
      error("MiningTool durability must be non-negative, got: " .. tostring(self.durability))
   end

   if not self.maxDurability or self.maxDurability < 1 then
      error("MiningTool maxDurability must be positive, got: " .. tostring(self.maxDurability))
   end

   if self.durability > self.maxDurability then error("MiningTool durability cannot exceed maxDurability") end

   -- Validate efficiency
   if not self.efficiency or self.efficiency <= 0 then
      error("MiningTool efficiency must be positive, got: " .. tostring(self.efficiency))
   end

   -- Validate repair cost
   if not self.repairCost or self.repairCost < 0 then
      error("MiningTool repairCost must be non-negative, got: " .. tostring(self.repairCost))
   end

   return true
end

--- Checks if the tool can mine a resource with given hardness
--- @param hardness integer The hardness of the resource to mine
--- @return boolean True if tool is powerful enough
function MiningTool:canMine(hardness)
   return self.power >= hardness and not self:isBroken()
end

--- Checks if the tool is broken (no durability remaining)
--- @return boolean True if tool is broken
function MiningTool:isBroken()
   return self.durability <= 0
end

--- Gets the durability percentage (0.0 to 1.0)
--- @return number Durability percentage
function MiningTool:getDurabilityPercentage()
   if self.maxDurability == 0 then return 1.0 end
   return self.durability / self.maxDurability
end

--- Checks if the tool needs repair (durability < 25%)
--- @return boolean True if tool needs repair
function MiningTool:needsRepair()
   return self:getDurabilityPercentage() < 0.25
end

--- Degrades the tool durability based on resource hardness
--- @param hardness integer The hardness of the mined resource
--- @return integer Amount of durability lost
function MiningTool:degrade(hardness)
   if self:isBroken() then return 0 end

   -- Calculate degradation based on hardness
   local degradationRate = MiningTool.DEGRADATION_RATES[hardness] or hardness

   -- Apply some randomness (±25%)
   local randomFactor = 0.75 + (math.random() * 0.5)
   local actualDegradation = math.ceil(degradationRate * randomFactor)

   -- Apply degradation
   local oldDurability = self.durability
   self.durability = math.max(0, self.durability - actualDegradation)

   return oldDurability - self.durability
end

--- Repairs the tool by a specified amount
--- @param amount integer Amount of durability to restore (defaults to full repair)
--- @return integer Actual amount repaired
function MiningTool:repair(amount)
   if not amount then amount = self.maxDurability - self.durability end

   local oldDurability = self.durability
   self.durability = math.min(self.maxDurability, self.durability + amount)

   return self.durability - oldDurability
end

--- Gets the cost to repair the tool to full durability
--- @return integer Repair cost based on damage percentage
function MiningTool:getRepairCost()
   local damagePercentage = 1.0 - self:getDurabilityPercentage()
   return math.ceil(self.repairCost * damagePercentage)
end

--- Calculates mining success chance against a resource
--- @param hardness integer The hardness of the resource
--- @return number Success chance (0.0 to 1.0)
function MiningTool:getMiningSuccessChance(hardness)
   if not self:canMine(hardness) then return 0.0 end

   -- Base success chance based on power vs hardness
   local powerRatio = self.power / hardness
   local baseChance = math.min(0.95, 0.5 + (powerRatio - 1) * 0.2)

   -- Reduce chance based on tool condition
   local conditionMultiplier = 0.5 + (self:getDurabilityPercentage() * 0.5)

   return math.max(0.1, baseChance * conditionMultiplier)
end

--- Gets the effective mining speed multiplier
--- @return number Effective efficiency considering tool condition
function MiningTool:getEffectiveEfficiency()
   if self:isBroken() then return 0.0 end

   -- Efficiency decreases as tool degrades
   local conditionMultiplier = 0.3 + (self:getDurabilityPercentage() * 0.7)
   return self.efficiency * conditionMultiplier
end

--- Gets a display name for the tool
--- @return string Human-readable tool name
function MiningTool:getDisplayName()
   local name = self.toolType:gsub("_", " ")
   return name:gsub("(%a)([%w_']*)", function(first, rest)
      return first:upper() .. rest:lower()
   end)
end

--- Gets a condition description for the tool
--- @return string Condition description
function MiningTool:getConditionString()
   local percentage = self:getDurabilityPercentage()

   if percentage <= 0 then
      return "Broken"
   elseif percentage < 0.25 then
      return "Poor"
   elseif percentage < 0.5 then
      return "Fair"
   elseif percentage < 0.75 then
      return "Good"
   else
      return "Excellent"
   end
end

--- Gets a string representation of the tool
--- @return string Tool description
function MiningTool:toString()
   return string.format(
      "%s (Power %d, %d/%d durability, %s condition)",
      self:getDisplayName(),
      self.power,
      self.durability,
      self.maxDurability,
      self:getConditionString()
   )
end

--- Creates a tool of the specified type
--- @param toolType string The type of tool to create
--- @param durability integer? Starting durability (optional)
--- @return MiningTool New tool instance
function MiningTool.create(toolType, durability)
   return MiningTool({
      toolType = toolType,
      durability = durability,
   })
end

--- Gets all available tool types
--- @return table List of tool type names
function MiningTool.getAvailableTypes()
   local types = {}
   for _, typeDef in pairs(MiningTool.TYPES) do
      table.insert(types, typeDef.name)
   end
   return types
end

--- Gets tools suitable for mining a specific hardness level
--- @param hardness integer The hardness level to check
--- @return table List of tool type names that can mine this hardness
function MiningTool.getToolsForHardness(hardness)
   local suitableTools = {}
   for _, typeDef in pairs(MiningTool.TYPES) do
      if typeDef.power >= hardness then table.insert(suitableTools, typeDef.name) end
   end
   return suitableTools
end

return MiningTool
