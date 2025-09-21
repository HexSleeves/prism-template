--- @class CityServicesSystem : System
local CityServicesSystem = prism.System:extend("CityServicesSystem")

function CityServicesSystem:__new()
   -- Message bus is handled through onYield method
end

--- Handle messages from the level
--- @param level Level The level that yielded
--- @param event Message The message event
function CityServicesSystem:onYield(level, event)
   if prism.messages.ActionMessage:is(event) then
      ---@cast event ActionMessage
      if event.action.className == "InteractAction" then self:handleInteraction(event) end
   end
end

--- Handle interaction with city services
--- @param message ActionMessage
function CityServicesSystem:handleInteraction(message)
   local action = message.action
   if not action then return end

   ---@cast action InteractAction
   local actor = action.actor
   local target = action.target

   -- Get the city service to determine service type
   local cityService = target:get(prism.components.CityService)
   if not cityService then return end

   local serviceType = cityService.serviceType

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
   local cityService = shop:get("CityService")
   local playerInventory = actor:get("Inventory")

   if not playerInventory then return end

   -- Display shop menu
   self:displayShopMenu(actor, shop)
end

--- Display shop menu and available items
--- @param actor Actor
--- @param shop Actor
function CityServicesSystem:displayShopMenu(actor, shop)
   local cityService = shop:get("CityService")
   local playerInventory = actor:get("Inventory")

   if not cityService or not playerInventory then return end

   local playerCoins = playerInventory:getItemCount("coins") or 0

   prism.logger.info("=== SHOP MENU ===")
   prism.logger.info("Your coins: " .. playerCoins)
   prism.logger.info("Available items:")

   for itemType, price in pairs(cityService.prices) do
      local canAfford = playerCoins >= price
      local affordText = canAfford and "[AFFORDABLE]" or "[TOO EXPENSIVE]"
      prism.logger.info("  " .. itemType .. " - " .. price .. " coins " .. affordText)
   end

   prism.logger.info("Items you can sell:")
   for itemType, _ in pairs(cityService.prices) do
      local playerCount = playerInventory:getItemCount(itemType) or 0
      if playerCount > 0 then
         local sellPrice = math.floor(cityService.prices[itemType] * 0.6)
         prism.logger.info("  " .. itemType .. " x" .. playerCount .. " - " .. sellPrice .. " coins each")
      end
   end

   prism.logger.info("Use 'b <item>' to buy, 's <item>' to sell")
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
      prism.logger.info("Bought " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.logger.info("Cannot buy: " .. (message or "Unknown error"))
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
      prism.logger.info("Sold " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.logger.info("Cannot sell: " .. (message or "Unknown error"))
   end
end

--- Handle storage interaction
--- @param actor Actor
--- @param storage Actor
function CityServicesSystem:handleStorageInteraction(actor, storage)
   local cityService = storage:get("CityService")
   local playerInventory = actor:get("Inventory")

   if not playerInventory then return end

   -- Display storage menu
   self:displayStorageMenu(actor, storage)
end

--- Display storage menu and available items
--- @param actor Actor
--- @param storage Actor
function CityServicesSystem:displayStorageMenu(actor, storage)
   local cityService = storage:get("CityService")
   local playerInventory = actor:get("Inventory")

   if not cityService or not playerInventory then return end

   prism.logger.info("=== STORAGE VAULT ===")

   -- Show items in storage
   local hasStoredItems = false
   prism.logger.info("Items in storage:")
   for itemType, quantity in pairs(cityService.storageItems) do
      if quantity > 0 then
         prism.logger.info("  " .. itemType .. " x" .. quantity)
         hasStoredItems = true
      end
   end

   if not hasStoredItems then prism.logger.info("  (empty)") end

   -- Show player inventory (items they can deposit)
   prism.logger.info("Your inventory:")
   local hasPlayerItems = false

   -- This is a simplified version - in a real implementation you'd iterate through actual inventory
   local commonItems = { "coal", "copper", "iron", "gold", "gems", "torch", "food" }
   for _, itemType in ipairs(commonItems) do
      local count = playerInventory:getItemCount(itemType) or 0
      if count > 0 then
         prism.logger.info("  " .. itemType .. " x" .. count)
         hasPlayerItems = true
      end
   end

   if not hasPlayerItems then prism.logger.info("  (no depositable items)") end

   prism.logger.info("Use 'd <item>' to deposit, 'w <item>' to withdraw")
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
      prism.logger.info("Deposited " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.logger.info("Cannot deposit: " .. (message or "Unknown error"))
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
      prism.logger.info("Withdrew " .. (quantity or 1) .. "x " .. itemType)
   else
      prism.logger.info("Cannot withdraw: " .. (message or "Unknown error"))
   end
end

--- Handle inn interaction
--- @param actor Actor
--- @param inn Actor
function CityServicesSystem:handleInnInteraction(actor, inn)
   local cityService = inn:get("CityService")

   -- Restore player health (if health system exists)
   -- For now, just log the interaction
   prism.logger.info("Player rested at inn: " .. cityService:getInteractionText())
end

--- Handle foreman interaction
--- @param actor Actor
--- @param foreman Actor
function CityServicesSystem:handleForemanInteraction(actor, foreman)
   local cityService = foreman:get("CityService")
   local depthTracker = actor:get("DepthTracker")

   local info = "Welcome to the mines! "
   if depthTracker then
      info = info .. "Current depth: " .. depthTracker.currentDepth .. ". "
      info = info .. "Max depth reached: " .. depthTracker.maxDepthReached .. "."
   end

   prism.logger.info("Mine Foreman: " .. info)
end

--- Find nearby city services
--- @param actor Actor
--- @param range integer
--- @return Actor[]
function CityServicesSystem:findNearbyCityServices(actor, range)
   local position = actor:get("Position")
   if not position then return {} end

   local level = actor:getLevel()
   if not level then return {} end

   local services = {}
   local query = prism.Query():hasComponent("CityService"):hasComponent("Position")

   for serviceActor in query:iterate(level) do
      local servicePos = serviceActor:get("Position")
      local distance = math.abs(position.x - servicePos.x) + math.abs(position.y - servicePos.y)

      if distance <= range then table.insert(services, serviceActor) end
   end

   return services
end

return CityServicesSystem
