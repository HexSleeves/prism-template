--- @class SellAction : Action
local SellAction = prism.Action:extend("SellAction")
SellAction.name = "Sell"

--- @param actor Actor The player selling the item
--- @param shop Actor The shop actor
--- @param itemType string The type of item to sell
--- @param quantity integer? The quantity to sell (default 1)
function SellAction:__new(actor, shop, itemType, quantity)
   self.actor = actor
   self.shop = shop
   self.itemType = itemType
   self.quantity = quantity or 1
end

function SellAction:perform()
   local cityService = self.shop:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if player has the item to sell
   local playerItemCount = playerInventory:getItemCount(self.itemType) or 0
   if playerItemCount < self.quantity then return false, "Not enough items to sell" end

   -- Calculate sell price (typically lower than buy price)
   local basePrice = cityService.prices[self.itemType]
   if not basePrice then return false, "Shop doesn't buy this item" end

   -- Sell for 60% of buy price
   local sellPrice = math.floor(basePrice * 0.6)
   local totalValue = sellPrice * self.quantity

   -- Perform the transaction
   playerInventory:removeItem(self.itemType, self.quantity)
   playerInventory:addItem("coins", totalValue)

   -- Send transaction message
   local message = prism.messages.ActionMessage(self.actor, "sell", {
      shop = self.shop,
      itemType = self.itemType,
      quantity = self.quantity,
      totalValue = totalValue,
   })

   prism.MessageBus:send(message)

   return true
end

function SellAction:canPerform()
   local cityService = self.shop:getComponent("CityService")
   local playerInventory = self.actor:getComponent("Inventory")

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   local playerItemCount = playerInventory:getItemCount(self.itemType) or 0
   if playerItemCount < self.quantity then return false, "Not enough items to sell" end

   local basePrice = cityService.prices[self.itemType]
   if not basePrice then return false, "Shop doesn't buy this item" end

   return true
end

return SellAction
