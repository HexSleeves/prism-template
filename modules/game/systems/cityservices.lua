--- @class CityServicesSystem : System
local CityServicesSystem = prism.System:extend("CityServicesSystem")

function CityServicesSystem:__new()
   -- Listen for interaction messages
   prism.MessageBus:listen("ActionMessage", function(message)
      if message.actionType == "interact" then self:handleInteraction(message) end
   end)
end

--- Handle interaction with city services
--- @param message ActionMessage
function CityServicesSystem:handleInteraction(message)
   local actor = message.actor
   local data = message.data
   local target = data.target
   local serviceType = data.serviceType

   if serviceType == "shop" then
      self:handleShopInteraction(actor, target)
   elseif serviceType == "storage" then
      self:handleStorageInteraction(actor, target)
   elseif serviceType == "inn" then
      self:handleInnInteraction(actor, target)
   elseif serviceType == "foreman" then
      self:handleForemanInteraction(actor, target)
   end
end

--- Handle shop interaction
--- @param actor Actor
--- @param shop Actor
function CityServicesSystem:handleShopInteraction(actor, shop)
   local cityService = shop:getComponent("CityService")
   local playerInventory = actor:getComponent("Inventory")

   if not playerInventory then return end

   -- Display shop menu
   self:displayShopMenu(actor, shop)
end

--- Display shop menu and available items
--- @param actor Actor
--- @param shop Actor
function CityServicesSystem:displayShopMenu(actor, shop)
   local cityService = shop:getComponent("CityService")
   local playerInventory = actor:getComponent("Inventory")

   if not cityService or not playerInventory then return end

   local playerCoins = playerInventory:getItemCount("coins") or 0

   prism.log.info("=== SHOP MENU ===")
   prism.log.info("Your coins: " .. playerCoins)
   prism.log.info("Available items:")

   for itemType, price in pairs(cityService.prices) do
      local canAfford = playerCoins >= price
      local affordText = canAfford and "[AFFORDABLE]" or "[TOO EXPENSIVE]"
      prism.log.info("  " .. itemType .. " - " .. price .. " coins " .. affordText)
   end

   prism.log.info("Items you can sell:")
   for itemType, _ in pairs(cityService.prices) do
      local playerCount = playerInventory:getItemCount(itemType) or 0
      if playerCount > 0 then
         local sellPrice = math.floor(cityService.prices[itemType] * 0.6)
         prism.log.info("  " .. itemType .. " x" .. playerCount .. " - " .. sellPrice .. " coins each")
      end
   end

   prism.log.info("Use 'b <item>' to buy, 's <item>' to sell")
end

--- Handle buy command
--- @param actor Actor
--- @param shop Actor
--- @param itemType string
--- @param quantity integer?
function CityServicesSystem:handleBuyCommand(actor, shop, itemType, quantity)
   local buyAction = prism.actions.Buy(actor, shop, itemType, quantity)
   local success, message = buyAction:perform()

   if success then
      prism.log.info("Bought " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.log.info("Cannot buy: " .. (message or "Unknown error"))
   end
end

--- Handle sell command
--- @param actor Actor
--- @param shop Actor
--- @param itemType string
--- @param quantity integer?
function CityServicesSystem:handleSellCommand(actor, shop, itemType, quantity)
   local sellAction = prism.actions.Sell(actor, shop, itemType, quantity)
   local success, message = sellAction:perform()

   if success then
      prism.log.info("Sold " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.log.info("Cannot sell: " .. (message or "Unknown error"))
   end
end

--- Handle storage interaction
--- @param actor Actor
--- @param storage Actor
function CityServicesSystem:handleStorageInteraction(actor, storage)
   local cityService = storage:getComponent("CityService")
   local playerInventory = actor:getComponent("Inventory")

   if not playerInventory then return end

   -- Display storage menu
   self:displayStorageMenu(actor, storage)
end

--- Display storage menu and available items
--- @param actor Actor
--- @param storage Actor
function CityServicesSystem:displayStorageMenu(actor, storage)
   local cityService = storage:getComponent("CityService")
   local playerInventory = actor:getComponent("Inventory")

   if not cityService or not playerInventory then return end

   prism.log.info("=== STORAGE VAULT ===")

   -- Show items in storage
   local hasStoredItems = false
   prism.log.info("Items in storage:")
   for itemType, quantity in pairs(cityService.storageItems) do
      if quantity > 0 then
         prism.log.info("  " .. itemType .. " x" .. quantity)
         hasStoredItems = true
      end
   end

   if not hasStoredItems then prism.log.info("  (empty)") end

   -- Show player inventory (items they can deposit)
   prism.log.info("Your inventory:")
   local hasPlayerItems = false

   -- This is a simplified version - in a real implementation you'd iterate through actual inventory
   local commonItems = { "coal", "copper", "iron", "gold", "gems", "torch", "food" }
   for _, itemType in ipairs(commonItems) do
      local count = playerInventory:getItemCount(itemType) or 0
      if count > 0 then
         prism.log.info("  " .. itemType .. " x" .. count)
         hasPlayerItems = true
      end
   end

   if not hasPlayerItems then prism.log.info("  (no depositable items)") end

   prism.log.info("Use 'd <item>' to deposit, 'w <item>' to withdraw")
end

--- Handle deposit command
--- @param actor Actor
--- @param storage Actor
--- @param itemType string
--- @param quantity integer?
function CityServicesSystem:handleDepositCommand(actor, storage, itemType, quantity)
   local depositAction = prism.actions.Deposit(actor, storage, itemType, quantity)
   local success, message = depositAction:perform()

   if success then
      prism.log.info("Deposited " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.log.info("Cannot deposit: " .. (message or "Unknown error"))
   end
end

--- Handle withdraw command
--- @param actor Actor
--- @param storage Actor
--- @param itemType string
--- @param quantity integer?
function CityServicesSystem:handleWithdrawCommand(actor, storage, itemType, quantity)
   local withdrawAction = prism.actions.Withdraw(actor, storage, itemType, quantity)
   local success, message = withdrawAction:perform()

   if success then
      prism.log.info("Withdrew " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.log.info("Cannot withdraw: " .. (message or "Unknown error"))
   end
end

--- Handle inn interaction
--- @param actor Actor
--- @param inn Actor
function CityServicesSystem:handleInnInteraction(actor, inn)
   local cityService = inn:getComponent("CityService")

   -- Restore player health (if health system exists)
   -- For now, just log the interaction
   prism.log.info("Player rested at inn: " .. cityService:getInteractionText())
end

--- Handle foreman interaction
--- @param actor Actor
--- @param foreman Actor
function CityServicesSystem:handleForemanInteraction(actor, foreman)
   local cityService = foreman:getComponent("CityService")
   local depthTracker = actor:getComponent("DepthTracker")

   local info = "Welcome to the mines! "
   if depthTracker then
      info = info .. "Current depth: " .. depthTracker.currentDepth .. ". "
      info = info .. "Max depth reached: " .. depthTracker.maxDepthReached .. "."
   end

   prism.log.info("Mine Foreman: " .. info)
end

--- Find nearby city services
--- @param actor Actor
--- @param range integer
--- @return Actor[]
function CityServicesSystem:findNearbyCityServices(actor, range)
   local position = actor:getComponent("Position")
   if not position then return {} end

   local level = actor:getLevel()
   if not level then return {} end

   local services = {}
   local query = prism.Query():hasComponent("CityService"):hasComponent("Position")

   for serviceActor in query:iterate(level) do
      local servicePos = serviceActor:getComponent("Position")
      local distance = math.abs(position.x - servicePos.x) + math.abs(position.y - servicePos.y)

      if distance <= range then table.insert(services, serviceActor) end
   end

   return services
end

return CityServicesSystem
