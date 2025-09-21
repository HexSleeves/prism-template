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

--- Create an item actor based on the item type
--- @param itemType string
--- @return Actor?
function BuyAction:createItemActor(itemType)
   -- Map item types to actor constructors
   local itemActors = {
      coal = function()
         return prism.Actor.fromComponents {
            prism.components.Name("Coal"),
            prism.components.Item { weight = 1, volume = 1, stackable = true, stackLimit = 99 },
         }
      end,
      copper = function()
         return prism.Actor.fromComponents {
            prism.components.Name("Copper Ore"),
            prism.components.Item { weight = 2, volume = 1, stackable = true, stackLimit = 50 },
         }
      end,
      iron = function()
         return prism.Actor.fromComponents {
            prism.components.Name("Iron Ore"),
            prism.components.Item { weight = 3, volume = 2, stackable = true, stackLimit = 25 },
         }
      end,
      torch = function()
         return prism.Actor.fromComponents {
            prism.components.Name("Torch"),
            prism.components.Item { weight = 1, volume = 1, stackable = true, stackLimit = 20 },
            prism.components.LightSource { radius = 3, duration = 100 },
         }
      end,
      basic_pickaxe = function()
         return prism.actors.Pickaxe()
      end,
   }

   local createActor = itemActors[itemType]
   if createActor then return createActor() end

   return nil
end

function BuyAction:perform()
   local cityService = self.shop:get(prism.components.CityService)
   local playerInventory = self.actor:get(prism.components.Inventory)

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   -- Check if item is available and get price
   local price = cityService.prices[self.itemType]
   if not price then return false, "Item not available in shop" end

   local totalCost = price * self.quantity

   -- Check if player has enough money
   local playerCoins = 0
   for coinActor in playerInventory:query(prism.components.Name):iter() do
      local name = coinActor:get(prism.components.Name)
      if name and name.name:lower() == "coins" then
         local item = coinActor:get(prism.components.Item)
         playerCoins = playerCoins + (item and item.stackCount or 1)
      end
   end

   if playerCoins < totalCost then return false, "Not enough coins" end

   -- Create item actors and add them to inventory
   for i = 1, self.quantity do
      local itemActor = self:createItemActor(self.itemType)
      if itemActor then playerInventory:addItem(itemActor) end
   end

   -- Remove coins (simplified - in a real game you'd have proper coin items)
   local coinsToRemove = totalCost
   for coinActor in playerInventory:query(prism.components.Name):iter() do
      if coinsToRemove <= 0 then break end
      local name = coinActor:get(prism.components.Name)
      if name and name.name:lower() == "coins" then
         local item = coinActor:get(prism.components.Item)
         local stackCount = item and item.stackCount or 1

         if stackCount <= coinsToRemove then
            playerInventory:removeItem(coinActor)
            coinsToRemove = coinsToRemove - stackCount
         else
            item.stackCount = item.stackCount - coinsToRemove
            coinsToRemove = 0
         end
      end
   end

   -- Message is automatically sent by the level when action completes

   return true
end

function BuyAction:canPerform()
   local cityService = self.shop:get(prism.components.CityService)
   local playerInventory = self.actor:get(prism.components.Inventory)

   if not cityService or cityService.serviceType ~= "shop" then return false, "Not a shop" end

   if not playerInventory then return false, "Player has no inventory" end

   local price = cityService.prices[self.itemType]
   if not price then return false, "Item not available" end

   local totalCost = price * self.quantity

   -- Check if player has enough coins
   local playerCoins = 0
   for coinActor in playerInventory:query(prism.components.Name):iter() do
      local name = coinActor:get(prism.components.Name)
      if name and name.name:lower() == "coins" then
         local item = coinActor:get(prism.components.Item)
         playerCoins = playerCoins + (item and item.stackCount or 1)
      end
   end

   if playerCoins < totalCost then return false, "Not enough coins" end

   -- Check if we can create the item
   if not self:createItemActor(self.itemType) then return false, "Cannot create item" end

   return true
end

return BuyAction
