-- Unit tests for MiningTool component
-- This is a basic test suite to verify MiningTool functionality

local MiningTool = require("modules.game.components.miningtool")

-- Simple test framework
local tests = {}
local testCount = 0
local passCount = 0

local function assert_equal(expected, actual, message)
   testCount = testCount + 1
   if expected == actual then
      passCount = passCount + 1
      print("✓ " .. (message or "Test passed"))
   else
      print(
         "✗ " .. (message or "Test failed") .. " - Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual)
      )
   end
end

local function assert_true(condition, message)
   assert_equal(true, condition, message)
end

local function assert_false(condition, message)
   assert_equal(false, condition, message)
end

-- Test tool creation
function tests.test_tool_creation()
   print("\n--- Testing Tool Creation ---")

   -- Test creating with string parameter
   local tool1 = MiningTool("basic_pickaxe")
   assert_equal("basic_pickaxe", tool1.toolType, "Tool type set correctly")
   assert_equal(2, tool1.power, "Power set from definition")
   assert_equal(100, tool1.maxDurability, "Max durability set from definition")
   assert_equal(100, tool1.durability, "Durability starts at max")

   -- Test creating with table parameter
   local tool2 = MiningTool({
      toolType = "iron_pickaxe",
      durability = 50,
   })
   assert_equal("iron_pickaxe", tool2.toolType, "Tool type set from table")
   assert_equal(4, tool2.power, "Power set from definition")
   assert_equal(50, tool2.durability, "Custom durability set")
end

-- Test tool validation
function tests.test_tool_validation()
   print("\n--- Testing Tool Validation ---")

   -- Test invalid tool type
   local success, err = pcall(function()
      MiningTool("invalid_tool")
   end)
   assert_false(success, "Invalid tool type should throw error")

   -- Test missing tool type
   success, err = pcall(function()
      MiningTool({})
   end)
   assert_false(success, "Missing tool type should throw error")
end

-- Test mining capability checks
function tests.test_mining_capability()
   print("\n--- Testing Mining Capability ---")

   local basicTool = MiningTool("basic_pickaxe") -- power 2
   local powerfulTool = MiningTool("magical_pickaxe") -- power 10

   -- Test can mine checks
   assert_true(basicTool:canMine(1), "Basic tool can mine hardness 1")
   assert_true(basicTool:canMine(2), "Basic tool can mine hardness 2")
   assert_false(basicTool:canMine(3), "Basic tool cannot mine hardness 3")

   assert_true(powerfulTool:canMine(10), "Powerful tool can mine hardness 10")
   assert_true(powerfulTool:canMine(1), "Powerful tool can mine hardness 1")
end

-- Test durability system
function tests.test_durability_system()
   print("\n--- Testing Durability System ---")

   local tool = MiningTool("basic_pickaxe")

   -- Test initial state
   assert_false(tool:isBroken(), "New tool is not broken")
   assert_equal(1.0, tool:getDurabilityPercentage(), "New tool at 100% durability")
   assert_false(tool:needsRepair(), "New tool doesn't need repair")

   -- Test degradation
   local degraded = tool:degrade(2) -- Mine hardness 2 material
   assert_true(degraded > 0, "Tool degraded after mining")
   assert_true(tool.durability < tool.maxDurability, "Durability decreased")

   -- Test repair
   local repaired = tool:repair(10)
   assert_true(repaired > 0, "Tool was repaired")

   -- Test breaking
   tool.durability = 0
   assert_true(tool:isBroken(), "Tool with 0 durability is broken")
   assert_false(tool:canMine(1), "Broken tool cannot mine")
end

-- Test mining success calculations
function tests.test_mining_success()
   print("\n--- Testing Mining Success ---")

   local tool = MiningTool("iron_pickaxe") -- power 4

   -- Test success chances
   local easyChance = tool:getMiningSuccessChance(1)
   local hardChance = tool:getMiningSuccessChance(4)
   local impossibleChance = tool:getMiningSuccessChance(10)

   assert_true(easyChance > hardChance, "Easier materials have higher success chance")
   assert_equal(0.0, impossibleChance, "Impossible materials have 0% chance")

   -- Test efficiency
   local efficiency = tool:getEffectiveEfficiency()
   assert_true(efficiency > 0, "Tool has positive efficiency")

   -- Test degraded efficiency
   tool.durability = 10 -- Very low durability
   local degradedEfficiency = tool:getEffectiveEfficiency()
   assert_true(degradedEfficiency < efficiency, "Degraded tool has lower efficiency")
end

-- Test utility functions
function tests.test_utility_functions()
   print("\n--- Testing Utility Functions ---")

   local tool = MiningTool("steel_pickaxe")

   -- Test display functions
   local displayName = tool:getDisplayName()
   assert_true(type(displayName) == "string", "Display name is string")
   assert_true(#displayName > 0, "Display name is not empty")

   local condition = tool:getConditionString()
   assert_equal("Excellent", condition, "New tool has excellent condition")

   local description = tool:toString()
   assert_true(type(description) == "string", "Description is string")
   assert_true(string.find(description, "Steel Pickaxe"), "Description contains tool name")
end

-- Test static functions
function tests.test_static_functions()
   print("\n--- Testing Static Functions ---")

   -- Test available types
   local types = MiningTool.getAvailableTypes()
   assert_true(#types > 0, "Has available tool types")

   -- Test tools for hardness
   local toolsForHardness2 = MiningTool.getToolsForHardness(2)
   assert_true(#toolsForHardness2 > 0, "Has tools for hardness 2")

   local toolsForHardness20 = MiningTool.getToolsForHardness(20)
   assert_equal(0, #toolsForHardness20, "No tools for impossible hardness")
end

-- Run all tests
function run_tests()
   print("Running MiningTool Component Tests")
   print("==================================")

   for testName, testFunc in pairs(tests) do
      testFunc()
   end

   print("\n==================================")
   print(string.format("Tests completed: %d/%d passed", passCount, testCount))

   if passCount == testCount then
      print("All tests passed! ✓")
      return true
   else
      print("Some tests failed! ✗")
      return false
   end
end

-- Export for external use
return {
   run_tests = run_tests,
   tests = tests,
}
