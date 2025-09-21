-- Simple validation test for mineable resource cells
-- This test validates the cell files exist and have correct structure

local function fileExists(path)
   local file = io.open(path, "r")
   if file then
      file:close()
      return true
   end
   return false
end

local function validateCellFile(path, expectedName, expectedResourceType)
   if not fileExists(path) then error("Cell file does not exist: " .. path) end

   local file = io.open(path, "r")
   local content = file:read("*all")
   file:close()

   -- Check for required components
   if not content:find("prism%.registerCell") then error("Cell file missing registerCell call: " .. path) end

   if not content:find("prism%.components%.Name") then error("Cell file missing Name component: " .. path) end

   if not content:find("prism%.components%.Drawable") then error("Cell file missing Drawable component: " .. path) end

   if not content:find("prism%.components%.Collider") then error("Cell file missing Collider component: " .. path) end

   if not content:find("prism%.components%.Opaque") then error("Cell file missing Opaque component: " .. path) end

   if expectedResourceType and not content:find("MinableResource") then
      error("Cell file missing MinableResource component: " .. path)
   end

   if expectedResourceType and not content:find('"' .. expectedResourceType .. '"') then
      error("Cell file missing expected resource type " .. expectedResourceType .. ": " .. path)
   end

   print("✓ " .. path .. " validation passed")
end

local function validateBedrockFile(path)
   if not fileExists(path) then error("Bedrock file does not exist: " .. path) end

   local file = io.open(path, "r")
   local content = file:read("*all")
   file:close()

   -- Check for required components
   if not content:find("prism%.registerCell") then error("Bedrock file missing registerCell call: " .. path) end

   if not content:find("prism%.components%.Name") then error("Bedrock file missing Name component: " .. path) end

   if not content:find("prism%.components%.Drawable") then
      error("Bedrock file missing Drawable component: " .. path)
   end

   if not content:find("prism%.components%.Collider") then
      error("Bedrock file missing Collider component: " .. path)
   end

   if not content:find("prism%.components%.Opaque") then error("Bedrock file missing Opaque component: " .. path) end

   -- Check that bedrock does NOT have MinableResource
   if content:find("MinableResource") then error("Bedrock should NOT have MinableResource component: " .. path) end

   print("✓ " .. path .. " validation passed")
end

-- Run validation tests
local function runValidationTests()
   print("Running mineable cells validation tests...")

   -- Validate mineable resource cells
   validateCellFile("modules/game/cells/coaldeposit.lua", "CoalDeposit", "coal")
   validateCellFile("modules/game/cells/copperore.lua", "CopperOre", "copper")
   validateCellFile("modules/game/cells/goldvein.lua", "GoldVein", "gold")
   validateCellFile("modules/game/cells/gemdeposit.lua", "GemDeposit", "gems")

   -- Validate bedrock (non-mineable)
   validateBedrockFile("modules/game/cells/bedrock.lua")

   print("All mineable cells validation tests passed! ✓")
end

-- Run the tests
runValidationTests()
