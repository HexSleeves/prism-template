--- @class CityService : Component
--- @field serviceType string Type of service ("shop", "storage", "inn", "foreman")
--- @field inventory Inventory? Shop inventory (for shops)
--- @field prices table<string, integer>? Item prices (for shops)
--- @field storageItems table<string, integer>? Stored items (for storage)
--- @field isActive boolean Whether the service is currently available
local CityService = prism.Component:extend("CityService")
CityService.name = "CityService"

--- @param serviceType string
--- @param config table?
function CityService:__new(serviceType, config)
   self.serviceType = serviceType
   self.isActive = true

   config = config or {}

   if serviceType == "shop" then
      self.inventory = config.inventory or {}
      self.prices = config.prices or self:getDefaultPrices()
   elseif serviceType == "storage" then
      self.storageItems = config.storageItems or {}
   end
end

--- Get default prices based on resource rarity
--- @return table<string, integer>
function CityService:getDefaultPrices()
   return {
      -- Basic resources (common)
      coal = 5,
      copper = 15,

      -- Intermediate resources (uncommon)
      iron = 25,
      silver = 40,

      -- Rare resources (rare)
      gold = 75,
      gems = 150,

      -- Equipment (varies by quality)
      basic_pickaxe = 25,
      iron_pickaxe = 75,
      steel_pickaxe = 150,

      -- Light sources
      torch = 10,
      lantern = 50,
      magical_light = 200,

      -- Consumables
      food = 5,
      healing_potion = 30,
   }
end

--- Update prices based on supply and demand
--- @param itemType string
--- @param demandMultiplier number
function CityService:updatePrice(itemType, demandMultiplier)
   if self.prices[itemType] then
      local basePrice = self:getDefaultPrices()[itemType] or self.prices[itemType]
      self.prices[itemType] = math.floor(basePrice * demandMultiplier)
   end
end

--- Get rarity multiplier for an item
--- @param itemType string
--- @return number
function CityService:getRarityMultiplier(itemType)
   local rarityMultipliers = {
      -- Common items
      coal = 1.0,
      copper = 1.0,
      torch = 1.0,
      food = 1.0,

      -- Uncommon items
      iron = 1.5,
      silver = 1.5,
      basic_pickaxe = 1.2,

      -- Rare items
      gold = 2.0,
      gems = 3.0,
      steel_pickaxe = 2.5,

      -- Very rare items
      magical_light = 4.0,
      healing_potion = 2.0,
   }

   return rarityMultipliers[itemType] or 1.0
end

--- Get total items stored in storage
--- @return integer
function CityService:getTotalStoredItems()
   if self.serviceType ~= "storage" then return 0 end

   local total = 0
   for _, quantity in pairs(self.storageItems) do
      total = total + quantity
   end
   return total
end

--- Get storage capacity (for future expansion)
--- @return integer
function CityService:getStorageCapacity()
   return 1000 -- Default capacity
end

--- Check if storage has space for more items
--- @param quantity integer
--- @return boolean
function CityService:hasStorageSpace(quantity)
   if self.serviceType ~= "storage" then return false end

   return self:getTotalStoredItems() + quantity <= self:getStorageCapacity()
end

--- Clear all stored items (for testing/admin purposes)
function CityService:clearStorage()
   if self.serviceType == "storage" then self.storageItems = {} end
end

--- Get service interaction text
--- @return string
function CityService:getInteractionText()
   if self.serviceType == "shop" then
      return "Press 'b' to buy items, 's' to sell items"
   elseif self.serviceType == "storage" then
      return "Press 'd' to deposit items, 'w' to withdraw items"
   elseif self.serviceType == "inn" then
      return "Press 'r' to rest and recover health"
   elseif self.serviceType == "foreman" then
      return "Press 't' to talk with the mine foreman"
   end
   return "Press 'i' to interact"
end

--- Check if player can interact with this service
--- @param player Actor
--- @return boolean
function CityService:canInteract(player)
   return self.isActive and player:hasComponent("Position")
end

return CityService
