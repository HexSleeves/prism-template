--- @class WithdrawAction : Action
local WithdrawAction = prism.Action:extend("WithdrawAction")
WithdrawAction.name = "Withdraw"

--- @param actor Actor The player withdrawing the item
--- @param storage Actor The storage actor
--- @param itemType string The type of item to withdraw
--- @param quantity integer? The quantity to withdraw (default 1)
function WithdrawAction:__new(actor, storage, itemType, quantity)
   self.actor = actor
   self.storage = storage
   self.itemType = itemType
   self.quantity = quantity or 1
end

function WithdrawAction:perform()
   local cityService = self.storage:get("CityService")
   local playerInventory = self.actor:get("Inventory")

   if not cityService or cityService.serviceType ~= "storage" then return false, "Not a storage facility" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if storage has the item
   local storedCount = cityService.storageItems[self.itemType] or 0
   if storedCount < self.quantity then return false, "Not enough items in storage" end

   -- Check if player has inventory space
   if not playerInventory:canAddItem(self.itemType, self.quantity) then return false, "Not enough inventory space" end

   -- Perform the withdrawal
   cityService.storageItems[self.itemType] = storedCount - self.quantity
   if cityService.storageItems[self.itemType] <= 0 then cityService.storageItems[self.itemType] = nil end

   playerInventory:addItem(self.itemType, self.quantity)

   -- Send transaction message
   local message = prism.messages.ActionMessage(self.actor, "withdraw", {
      storage = self.storage,
      itemType = self.itemType,
      quantity = self.quantity,
   })

   -- Message is automatically sent by the level when action completes

   return true
end

function WithdrawAction:canPerform()
   local cityService = self.storage:get("CityService")
   local playerInventory = self.actor:get("Inventory")

   if not cityService or cityService.serviceType ~= "storage" then return false, "Not a storage facility" end

   if not playerInventory then return false, "Player has no inventory" end

   local storedCount = cityService.storageItems[self.itemType] or 0
   if storedCount < self.quantity then return false, "Not enough items in storage" end

   if not playerInventory:canAddItem(self.itemType, self.quantity) then return false, "Not enough inventory space" end

   return true
end

return WithdrawAction
