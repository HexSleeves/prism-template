--- Inventory utility functions for the game
local InventoryUtils = {}

--- Helper function to count items by name in inventory
--- @param inventory Inventory The inventory component
--- @param itemName string The name of the item to count
--- @return integer The total count of items with that name
function InventoryUtils.getItemCount(inventory, itemName)
   if not inventory then return 0 end

   local count = 0
   for actor in inventory:query(prism.components.Name):iter() do
      local name = actor:get(prism.components.Name)
      if name and name.name:lower() == itemName:lower() then
         local item = actor:get(prism.components.Item)
         count = count + (item and item.stackCount or 1)
      end
   end
   return count
end

--- Helper function to check if inventory can add items by name
--- @param inventory Inventory The inventory component
--- @param itemName string The name of the item type
--- @param quantity integer The quantity to add
--- @return boolean True if can add
function InventoryUtils.canAddItem(inventory, itemName, quantity)
   -- For now, just check if we have space for new items
   -- This is a simplified implementation
   if not inventory then return false end

   if inventory.totalCount + quantity > inventory.limitCount then return false end

   return true
end

--- Helper function to add items by name to inventory
--- @param inventory Inventory The inventory component
--- @param itemName string The name of the item type
--- @param quantity integer The quantity to add
--- @return boolean True if successfully added
function InventoryUtils.addItem(inventory, itemName, quantity)
   -- This is a placeholder - in a real implementation, you'd need to:
   -- 1. Create actual item actors with the specified name
   -- 2. Add them to the inventory
   -- For now, this is just a stub that returns true
   return true
end

--- Helper function to remove items by name from inventory
--- @param inventory Inventory The inventory component
--- @param itemName string The name of the item type
--- @param quantity integer The quantity to remove
--- @return boolean True if successfully removed
function InventoryUtils.removeItem(inventory, itemName, quantity)
   if not inventory then return false end

   local currentCount = InventoryUtils.getItemCount(inventory, itemName)
   if currentCount < quantity then return false end

   -- Find and remove items
   local toRemove = {}
   local remaining = quantity

   for actor in inventory:query(prism.components.Name):iter() do
      if remaining <= 0 then break end

      local name = actor:get(prism.components.Name)
      if name and name.name:lower() == itemName:lower() then
         local item = actor:get(prism.components.Item)
         local stackCount = item and item.stackCount or 1

         if stackCount <= remaining then
            -- Remove entire stack
            table.insert(toRemove, actor)
            remaining = remaining - stackCount
         else
            -- Remove partial stack
            if item and item.stackable then
               item.stackCount = item.stackCount - remaining
               remaining = 0
            end
         end
      end
   end

   -- Remove actors that were fully consumed
   for _, actor in ipairs(toRemove) do
      inventory:removeItem(actor)
   end

   return remaining == 0
end

return InventoryUtils
