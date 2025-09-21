-- Simple validation test for mine infrastructure cells
-- This test validates the cell files exist and have correct structure

local function fileExists(path)
   local file = io.open(path, "r")
   if file then
      file:close()
      return true
   end
   return false
end

local function validateMineCellFile(path, expectedName, shouldBeWalkable, shouldBeOpaque)
   if not fileExists(path) then error("Mine cell file does not exist: " .. path) end

   local file = io.open(path, "r")
   local content = file:read("*all")
   file:close()

   -- Check for required components
   if not content:find("prism%.registerCell") then error("Mine cell file missing registerCell call: " .. path) end

   if not content:find("prism%.components%.Name") then error("Mine cell file missing Name component: " .. path) end

   if not content:find("prism%.components%.Drawable") then
      error("Mine cell file missing Drawable component: " .. path)
   end

   if not content:find("prism%.components%.Collider") then
      error("Mine cell file missing Collider component: " .. path)
   end

   -- Check walkability
   if shouldBeWalkable then
      if not content:find("allowedMovetypes") then
         error("Mine cell file missing allowedMovetypes in Collider: " .. path)
      end

      if not content:find("walk") then error("Mine cell file should allow walk movement: " .. path) end
   else
      -- Should not have allowedMovetypes (blocking cell)
      if content:find("allowedMovetypes") then
         error("Mine cell file should NOT have allowedMovetypes (should be blocking): " .. path)
      end
   end

   -- Check opacity
   if shouldBeOpaque then
      if not content:find("prism%.components%.Opaque") then
         error("Mine cell file missing Opaque component: " .. path)
      end
   else
      if content:find("prism%.components%.Opaque") then
         error("Mine cell file should NOT have Opaque component: " .. path)
      end
   end

   print("✓ " .. path .. " validation passed")
end

-- Run validation tests
local function runValidationTests()
   print("Running mine infrastructure cells validation tests...")

   -- Validate mine infrastructure cells
   -- MineShaft: walkable, not opaque (for transitions)
   validateMineCellFile("modules/game/cells/mineshaft.lua", "MineShaft", true, false)

   -- SupportBeam: not walkable, opaque (structural obstacle)
   validateMineCellFile("modules/game/cells/supportbeam.lua", "SupportBeam", false, true)

   -- MineCartTrack: walkable, not opaque (decorative floor)
   validateMineCellFile("modules/game/cells/minecarttrack.lua", "MineCartTrack", true, false)

   print("All mine infrastructure cells validation tests passed! ✓")
end

-- Run the tests
runValidationTests()
