--- @class CityService : Component
--- @field serviceType string Type of service ("shop", "storage", "inn")
--- @field inventory Inventory? Shop inventory (for shops)
--- @field prices table<string, integer>? Item prices (for shops)
local CityService = prism.Component:extend("CityService")
CityService.name = "CityService"

--- Creates a new CityService component
--- @param serviceType string Type of service ("shop", "storage", "inn")
--- @param inventory Inventory? Shop inventory (for shops)
--- @param prices table<string, integer>? Item prices (for shops)
function CityService:__new(serviceType, inventory, prices)
   self.serviceType = serviceType or "shop"
   self.inventory = inventory
   self.prices = prices or {}
end

--- Gets the service type
--- @return string The service type
function CityService:getServiceType()
   return self.serviceType
end

--- Gets the shop inventory (if applicable)
--- @return Inventory? The inventory or nil
function CityService:getInventory()
   return self.inventory
end

--- Gets the price for an item (if applicable)
--- @param itemType string The item type to check
--- @return integer? The price or nil
function CityService:getPrice(itemType)
   return self.prices[itemType]
end

--- Sets the price for an item
--- @param itemType string The item type
--- @param price integer The price
function CityService:setPrice(itemType, price)
   self.prices[itemType] = price
end

return CityService
