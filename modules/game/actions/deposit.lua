--- @class DepositAction : Action
local DepositAction = prism.Action:extend("DepositAction")
DepositAction.name = "Deposit"

--- @param actor Actor The player depositing the item
--- @param storage Actor The storage actor
--- @param itemType string The type of item to deposit
--- @param quantity integer? The quantity to deposit (default 1)
function DepositAction:__new(actor, storage, itemType, quantity)
   self.actor = actor
   self.storage = storage
   self.itemType = itemType
   self.quantity = quantity or 1
end

function DepositAction:perform()
   local cityService = self.storage:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "storage" then return false, "Not a storage facility" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if player has the item to deposit
   local playerItemCount = playerInventory:getItemCount(self.itemType) or 0
   if playerItemCount < self.quantity then return false, "Not enough items to deposit" end

   -- Perform the deposit
   playerInventory:removeItem(self.itemType, self.quantity)

   -- Add to storage
   local currentStored = cityService.storageItems[self.itemType] or 0
   cityService.storageItems[self.itemType] = currentStored + self.quantity

   -- Send transaction message
   local message = prism.messages.ActionMessage(self.actor, "deposit", {
      storage = self.storage,
      itemType = self.itemType,
      quantity = self.quantity,
   })

   prism.MessageBus:send(message)

   return true
end

function DepositAction:canPerform()
   local cityService = self.storage:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "storage" then return false, "Not a storage facility" end

   if not playerInventory then return false, "Player has no inventory" end

   local playerItemCount = playerInventory:getItemCount(self.itemType) or 0
   if playerItemCount < self.quantity then return false, "Not enough items to deposit" end

   return true
end

return DepositAction
