--- @class BuyAction : Action
local BuyAction = prism.Action:extend("BuyAction")
BuyAction.name = "Buy"

--- @param actor Actor The player buying the item
--- @param shop Actor The shop actor
--- @param itemType string The type of item to buy
--- @param quantity integer? The quantity to buy (default 1)
function BuyAction:__new(actor, shop, itemType, quantity)
   self.actor = actor
   self.shop = shop
   self.itemType = itemType
   self.quantity = quantity or 1
end

function BuyAction:perform()
   local cityService = self.shop:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if item is available and get price
   local price = cityService.prices[self.itemType]
   if not price then return false, "Item not available in shop" end

   local totalCost = price * self.quantity

   -- Check if player has enough money (assuming money is stored as "coins" in inventory)
   local playerCoins = playerInventory:getItemCount("coins") or 0
   if playerCoins < totalCost then return false, "Not enough coins" end

   -- Check if player has inventory space
   if not playerInventory:canAddItem(self.itemType, self.quantity) then return false, "Not enough inventory space" end

   -- Perform the transaction
   playerInventory:removeItem("coins", totalCost)
   playerInventory:addItem(self.itemType, self.quantity)

   -- Send transaction message
   local message = prism.messages.ActionMessage(self.actor, "buy", {
      shop = self.shop,
      itemType = self.itemType,
      quantity = self.quantity,
      totalCost = totalCost,
   })

   prism.MessageBus:send(message)

   return true
end

function BuyAction:canPerform()
   local cityService = self.shop:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   local price = cityService.prices[self.itemType]
   if not price then return false, "Item not available" end

   local totalCost = price * self.quantity
   local playerCoins = playerInventory:getItemCount("coins") or 0

   if playerCoins < totalCost then return false, "Not enough coins" end

   if not playerInventory:canAddItem(self.itemType, self.quantity) then return false, "Not enough inventory space" end

   return true
end

return BuyAction
