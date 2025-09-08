local MineTarget = prism.Target():isPrototype(prism.Vector2):range(1)

---@class Mine : Action
---@field name string
---@field targets Target[]
local Mine = prism.Action:extend("Mine")
Mine.name = "mine"
Mine.targets = { MineTarget }

Mine.requiredComponents = {
   prism.components.Controller,
}

-- Load required components
local MiningTool = require("modules.game.components.miningtool")
local MinableResource = require("modules.game.components.minableresource")

--- Checks if the actor can perform mining at the target location
--- @param level Level
--- @param target Vector2
--- @return boolean canPerform
--- @return string? errorMessage
function Mine:canPerform(level, target)
   -- Check if target is adjacent (already handled by range(1) in target)

   -- Check if actor has a mining tool
   local miningTool = self.owner:get(MiningTool)
   if not miningTool then return false, "No mining tool equipped" end

   -- Check if tool is not broken
   if miningTool:isBroken() then return false, "Mining tool is broken" end

   -- Check if target cell exists and is valid
   local cell = level:getCell(target.x, target.y)
   if not cell then return false, "Invalid target location" end

   -- Check if target has mineable resources
   local resource = cell:get(MinableResource)
   if not resource then return false, "Nothing to mine here" end

   -- Check if resource is depleted
   if resource:isDepleted() then return false, "Resource is depleted" end

   -- Check if tool can mine this resource
   if not miningTool:canMine(resource.hardness) then return false, "Tool not powerful enough for this resource" end

   return true
end

--- Performs the mining action
--- @param level Level
--- @param target Vector2
function Mine:perform(level, target)
   local miningTool = self.owner:expect(MiningTool)
   local cell = level:getCell(target.x, target.y)
   local resource = cell:expect(MinableResource)

   -- Calculate mining success
   local successChance = miningTool:getMiningSuccessChance(resource.hardness)
   local success = math.random() <= successChance

   -- Always degrade the tool when mining
   local degradation = miningTool:degrade(resource.hardness)

   if success then
      -- Extract resource
      local extractedAmount = resource:extract(1)

      if extractedAmount > 0 then
         -- Try to add to inventory if actor has one
         local inventory = self.owner:get(prism.components.Inventory)
         if inventory then self:addResourceToInventory(inventory, resource.resourceType, extractedAmount) end

         -- Send success message
         level:sendMessage(prism.messages.ActionMessage({
            actor = self.owner,
            action = "mine",
            success = true,
            message = string.format("Mined %d %s", extractedAmount, resource:getDisplayName()),
            resourceType = resource.resourceType,
            amount = extractedAmount,
         }))
      end

      -- Remove resource component if depleted
      if resource:isDepleted() then
         cell:remove(MinableResource)

         -- Optionally convert cell to a different type (e.g., mined-out cell)
         -- This could be handled by a system or level generation logic
      end
   else
      -- Mining failed
      level:sendMessage(prism.messages.ActionMessage({
         actor = self.owner,
         action = "mine",
         success = false,
         message = "Mining attempt failed",
         resourceType = resource.resourceType,
      }))
   end

   -- Send tool degradation message if significant
   if degradation > 0 then
      level:sendMessage(prism.messages.ActionMessage({
         actor = self.owner,
         action = "tool_degrade",
         message = string.format("Tool degraded by %d durability", degradation),
         degradation = degradation,
         toolCondition = miningTool:getConditionString(),
      }))

      -- Warn if tool is about to break
      if miningTool:needsRepair() and not miningTool:isBroken() then
         level:sendMessage(prism.messages.ActionMessage({
            actor = self.owner,
            action = "tool_warning",
            message = string.format(
               "%s needs repair (%s condition)",
               miningTool:getDisplayName(),
               miningTool:getConditionString()
            ),
         }))
      elseif miningTool:isBroken() then
         level:sendMessage(prism.messages.ActionMessage({
            actor = self.owner,
            action = "tool_broken",
            message = string.format("%s has broken!", miningTool:getDisplayName()),
         }))
      end
   end
end

--- Adds extracted resource to the actor's inventory
--- @param inventory Inventory
--- @param resourceType string
--- @param amount integer
function Mine:addResourceToInventory(inventory, resourceType, amount)
   -- Create a resource item actor
   -- This assumes we have a resource item factory - we'll create a simple one
   local resourceActor = self:createResourceItem(resourceType, amount)

   if resourceActor then
      local canAdd, error = inventory:canAddItem(resourceActor)
      if canAdd then
         inventory:addItem(resourceActor)
      else
         -- Handle inventory full - could drop item on ground or show message
         -- For now, just send a message
         local level = self.owner.level
         if level then
            level:sendMessage(prism.messages.ActionMessage({
               actor = self.owner,
               action = "inventory_full",
               message = "Inventory full! " .. (error or "Cannot add item."),
               resourceType = resourceType,
               amount = amount,
            }))
         end
      end
   end
end

--- Creates a resource item actor for the given resource type and amount
--- @param resourceType string
--- @param amount integer
--- @return Actor? resourceItem
function Mine:createResourceItem(resourceType, amount)
   -- Create a basic resource item actor
   -- This is a simplified implementation - in a full game you'd have proper item factories
   local resourceActor = prism.Actor()

   -- Add Item component for inventory compatibility
   local resourceDef = MinableResource.TYPES[resourceType:upper()]
   if not resourceDef then
      -- Fallback for custom resource types
      resourceDef = { value = 1, name = resourceType }
   end

   resourceActor:add(prism.components.Item({
      weight = 1, -- Base weight per unit
      volume = 1, -- Base volume per unit
      stackable = function()
         return Mine.createResourceItem(nil, resourceType, 1)
      end,
      stackLimit = 99, -- Max stack size
      stackCount = amount,
   }))

   -- Add a name component for identification
   resourceActor:add(prism.components.Name(resourceDef.name or resourceType))

   -- Store resource type for later reference
   resourceActor.resourceType = resourceType
   resourceActor.unitValue = resourceDef.value or 1

   return resourceActor
end

--- Static method to create resource items (used by stackable function)
--- @param resourceType string
--- @param amount integer
--- @return Actor
function Mine.createResourceItem(_, resourceType, amount)
   local mine = Mine()
   return mine:createResourceItem(resourceType, amount or 1)
end

--- Gets the time cost of mining (for turn-based systems)
--- @param miningTool MiningTool
--- @param resource MinableResource
--- @return number timeCost
function Mine:getTimeCost(miningTool, resource)
   if not miningTool or not resource then
      return 1.0 -- Default time cost
   end

   -- Base time cost affected by tool efficiency and resource hardness
   local baseCost = 1.0
   local hardnessFactor = 1.0 + (resource.hardness - 1) * 0.2 -- Harder resources take longer
   local efficiencyFactor = 1.0 / miningTool:getEffectiveEfficiency()

   return baseCost * hardnessFactor * efficiencyFactor
end

--- Validates mining action parameters
--- @param level Level
--- @param target Vector2
--- @return boolean isValid
--- @return string? errorMessage
function Mine:validate(level, target)
   -- Basic validation
   if not level then return false, "No level provided" end

   if not target then return false, "No target provided" end

   if not self.owner then return false, "No owner actor" end

   -- Check if target is within bounds
   if not level:isInBounds(target.x, target.y) then return false, "Target out of bounds" end

   return true
end

return Mine
