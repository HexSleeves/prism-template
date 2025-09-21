--- @class CityService : Component
--- @field serviceType string Type of service ("shop", "storage", "inn", "foreman")
--- @field inventory table<string, integer|table>? Simplified inventory definition for shops
--- @field prices table<string, integer>? Item prices (for shops)
--- @field storageItems table<string, integer>? Stored items (for storage)
--- @field storageCapacity integer? Optional storage capacity override
--- @field isActive boolean Whether the service is currently available
local CityService = prism.Component:extend("CityService")
CityService.name = "CityService"

local DEFAULT_STORAGE_CAPACITY = 1000

local function cloneTable(source)
   if not source then return nil end
   local copy = {}
   for key, value in pairs(source) do
      if type(value) == "table" then
         copy[key] = cloneTable(value)
      else
         copy[key] = value
      end
   end
   return copy
end

--- @param serviceType string|table
--- @param config table?
function CityService:__new(serviceType, config)
   if type(serviceType) == "table" then
      config = serviceType
      serviceType = config.serviceType
   end

   assert(serviceType, "CityService requires a serviceType")

   config = config and cloneTable(config) or {}

   self.serviceType = serviceType
   self.isActive = config.isActive ~= false
   self.interactionText = config.interactionText

   if serviceType == "shop" then
      self.inventory = config.inventory or {}
      self.prices = config.prices and cloneTable(config.prices) or self:getDefaultPrices()
   elseif serviceType == "storage" then
      self.storageItems = config.storageItems and cloneTable(config.storageItems) or {}
      self.storageCapacity = config.storageCapacity or DEFAULT_STORAGE_CAPACITY
   else
      self.storageCapacity = config.storageCapacity
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
   if self.serviceType ~= "shop" or not self.prices then return end
   if self.prices[itemType] then
      local basePrice = self:getDefaultPrices()[itemType] or self.prices[itemType]
      self.prices[itemType] = math.max(1, math.floor(basePrice * demandMultiplier))
   end
end

--- Get buy price for an item
--- @param itemType string
--- @return integer?
function CityService:getBuyPrice(itemType)
   if self.serviceType ~= "shop" or not self.prices then return nil end
   return self.prices[itemType]
end

--- Get sell price for an item (fixed multiplier)
--- @param itemType string
--- @param sellMultiplier number?
--- @return integer?
function CityService:getSellPrice(itemType, sellMultiplier)
   local buyPrice = self:getBuyPrice(itemType)
   if not buyPrice then return nil end

   local multiplier = sellMultiplier or 0.6
   return math.max(1, math.floor(buyPrice * multiplier))
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
   local storage = self.storageItems or {}
   for _, quantity in pairs(storage) do
      total = total + quantity
   end
   return total
end

--- Get storage capacity (for future expansion)
--- @return integer
function CityService:getStorageCapacity()
   if self.serviceType ~= "storage" then return 0 end
   return self.storageCapacity or DEFAULT_STORAGE_CAPACITY
end

--- Check if storage has space for more items
--- @param quantity integer
--- @return boolean
function CityService:hasStorageSpace(quantity)
   if self.serviceType ~= "storage" then return false end

   return self:getTotalStoredItems() + quantity <= self:getStorageCapacity()
end

--- Get how many of an item are stored
--- @param itemType string
--- @return integer
function CityService:getStoredItemCount(itemType)
   if self.serviceType ~= "storage" then return 0 end
   return (self.storageItems or {})[itemType] or 0
end

--- Deposit items into storage
--- @param itemType string
--- @param quantity integer
function CityService:deposit(itemType, quantity)
   if self.serviceType ~= "storage" then return false, "Not a storage service" end
   if quantity <= 0 then return false, "Quantity must be positive" end
   if not self:hasStorageSpace(quantity) then return false, "Storage is full" end

   self.storageItems[itemType] = (self.storageItems[itemType] or 0) + quantity
   return true
end

--- Withdraw items from storage
--- @param itemType string
--- @param quantity integer
function CityService:withdraw(itemType, quantity)
   if self.serviceType ~= "storage" then return false, "Not a storage service" end
   if quantity <= 0 then return false, "Quantity must be positive" end

   local current = self.storageItems[itemType] or 0
   if current < quantity then return false, "Not enough items stored" end

   local remaining = current - quantity
   if remaining > 0 then
      self.storageItems[itemType] = remaining
   else
      self.storageItems[itemType] = nil
   end

   return true
end

--- Clear all stored items (for testing/admin purposes)
function CityService:clearStorage()
   if self.serviceType == "storage" then self.storageItems = {} end
end

--- Set whether the service is currently enabled
--- @param active boolean
function CityService:setActive(active)
   self.isActive = not not active
end

--- Get service interaction text
--- @return string
function CityService:getInteractionText()
   if self.interactionText then return self.interactionText end

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
   if not self.isActive or not player then return false end

   if player.has and type(player.has) == "function" then
      return player:has(prism.components.Position)
   elseif player.hasComponent and type(player.hasComponent) == "function" then
      return player:hasComponent("Position")
   end

   return false
end

return CityService
