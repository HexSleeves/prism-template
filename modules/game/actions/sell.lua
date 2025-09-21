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
   local cityService = self.shop:get(prism.components.CityService)
   local playerInventory = self.actor:get(prism.components.Inventory)

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if player has the item to sell
   local playerItemCount = 0
   for itemActor in playerInventory:query(prism.components.Name):iter() do
      local name = itemActor:get(prism.components.Name)
      if name and name.name:lower() == self.itemType:lower() then
         local item = itemActor:get(prism.components.Item)
         playerItemCount = playerItemCount + (item and item.stackCount or 1)
      end
   end

   if playerItemCount < self.quantity then return false, "Not enough items to sell" end

   -- Calculate sell price (typically lower than buy price)
   local basePrice = cityService.prices[self.itemType]
   if not basePrice then return false, "Shop doesn't buy this item" end

   -- Sell for 60% of buy price
   local sellPrice = math.floor(basePrice * 0.6)
   local totalValue = sellPrice * self.quantity

   -- Remove items from inventory
   local itemsToRemove = self.quantity
   for itemActor in playerInventory:query(prism.components.Name):iter() do
      if itemsToRemove <= 0 then break end
      local name = itemActor:get(prism.components.Name)
      if name and name.name:lower() == self.itemType:lower() then
         local item = itemActor:get(prism.components.Item)
         local stackCount = item and item.stackCount or 1

         if stackCount <= itemsToRemove then
            playerInventory:removeItem(itemActor)
            itemsToRemove = itemsToRemove - stackCount
         else
            item.stackCount = item.stackCount - itemsToRemove
            itemsToRemove = 0
         end
      end
   end

   -- Add coins to inventory
   for i = 1, totalValue do
      local coinActor = prism.Actor.fromComponents {
         prism.components.Name("Coins"),
         prism.components.Item { weight = 0.1, volume = 0.1, stackable = true, stackLimit = 1000 },
      }
      playerInventory:addItem(coinActor)
   end

   -- Message is automatically sent by the level when action completes

   return true
end

function SellAction:canPerform()
   local cityService = self.shop:get(prism.components.CityService)
   local playerInventory = self.actor:get(prism.components.Inventory)

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if player has the item to sell
   local playerItemCount = 0
   for itemActor in playerInventory:query(prism.components.Name):iter() do
      local name = itemActor:get(prism.components.Name)
      if name and name.name:lower() == self.itemType:lower() then
         local item = itemActor:get(prism.components.Item)
         playerItemCount = playerItemCount + (item and item.stackCount or 1)
      end
   end

   if playerItemCount < self.quantity then return false, "Not enough items to sell" end

   local basePrice = cityService.prices[self.itemType]
   if not basePrice then return false, "Shop doesn't buy this item" end

   return true
end

return SellAction
