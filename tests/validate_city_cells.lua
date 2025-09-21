-- Simple validation test for city infrastructure cells
-- This test validates the cell files exist and have correct structure

local function fileExists(path)
   local file = io.open(path, "r")
   if file then
      file:close()
      return true
   end
   return false
end

local function validateCityCellFile(path, expectedName, expectedServiceType)
   if not fileExists(path) then error("City cell file does not exist: " .. path) end

   local file = io.open(path, "r")
   local content = file:read("*all")
   file:close()

   -- Check for required components
   if not content:find("prism%.registerCell") then error("City cell file missing registerCell call: " .. path) end

   if not content:find("prism%.components%.Name") then error("City cell file missing Name component: " .. path) end

   if not content:find("prism%.components%.Drawable") then
      error("City cell file missing Drawable component: " .. path)
   end

   if not content:find("prism%.components%.Collider") then
      error("City cell file missing Collider component: " .. path)
   end

   -- Check for CityService component
   if not content:find("CityService") then error("City cell file missing CityService component: " .. path) end

   if not content:find('"' .. expectedServiceType .. '"') then
      error("City cell file missing expected service type " .. expectedServiceType .. ": " .. path)
   end

   -- Check for walkable collider (city cells should be walkable)
   if not content:find("allowedMovetypes") then
      error("City cell file missing allowedMovetypes in Collider: " .. path)
   end

   if not content:find("walk") then error("City cell file should allow walk movement: " .. path) end

   print("✓ " .. path .. " validation passed")
end

-- Run validation tests
local function runValidationTests()
   print("Running city infrastructure cells validation tests...")

   -- Validate city infrastructure cells
   validateCityCellFile("modules/game/cells/shopfloor.lua", "ShopFloor", "shop")
   validateCityCellFile("modules/game/cells/storagevault.lua", "StorageVault", "storage")
   validateCityCellFile("modules/game/cells/innfloor.lua", "InnFloor", "inn")

   print("All city infrastructure cells validation tests passed! ✓")
end

-- Run the tests
runValidationTests()
