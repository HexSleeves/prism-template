-- Unit tests for Mine action
-- This is a basic test suite to verify Mine action functionality

-- Mock the prism framework for testing
local prism = {
   Action = {
      extend = function(_, name)
         return {
            name = name,
            requiredComponents = {},
            targets = {},
         }
      end,
   },
   Target = function()
      return {
         isPrototype = function(self)
            return self
         end,
         range = function(self)
            return self
         end,
      }
   end,
   Vector2 = {},
   components = {
      Controller = "Controller",
      Inventory = "Inventory",
      Name = "Name",
      Item = "Item",
   },
   messages = {
      ActionMessage = function(data)
         return data
      end,
   },
   Actor = function()
      return {
         components = {},
         add = function(self, component)
            table.insert(self.components, component)
         end,
         get = function(self, componentType)
            for _, comp in ipairs(self.components) do
               if comp.name == componentType.name then return comp end
            end
            return nil
         end,
         expect = function(self, componentType)
            local comp = self:get(componentType)
            if not comp then error("Expected component " .. tostring(componentType.name)) end
            return comp
         end,
      }
   end,
}

-- Set up global prism for the modules
_G.prism = prism

local MiningTool = require("modules.game.components.miningtool")
local MinableResource = require("modules.game.components.minableresource")
local Mine = require("modules.game.actions.mine")

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

-- Helper function to create a mock level
local function createMockLevel()
   return {
      cells = {},
      messages = {},
      getCell = function(self, x, y)
         local key = x .. "," .. y
         return self.cells[key]
      end,
      setCell = function(self, x, y, cell)
         local key = x .. "," .. y
         self.cells[key] = cell
      end,
      isInBounds = function(self, x, y)
         return x >= 0 and x < 100 and y >= 0 and y < 100
      end,
      sendMessage = function(self, message)
         table.insert(self.messages, message)
      end,
   }
end

-- Helper function to create a mock cell
local function createMockCell()
   return {
      components = {},
      add = function(self, component)
         self.components[component.name] = component
      end,
      get = function(self, componentType)
         -- Handle both string names and component types
         local name = type(componentType) == "string" and componentType or componentType.name or tostring(componentType)
         for _, comp in pairs(self.components) do
            if comp.name == name or tostring(comp):find(name) then return comp end
         end
         return nil
      end,
      expect = function(self, componentType)
         local comp = self:get(componentType)
         if not comp then
            local name = type(componentType) == "string" and componentType
               or componentType.name
               or tostring(componentType)
            error("Expected component " .. name)
         end
         return comp
      end,
      remove = function(self, componentType)
         local name = type(componentType) == "string" and componentType or componentType.name or tostring(componentType)
         for key, comp in pairs(self.components) do
            if comp.name == name or tostring(comp):find(name) then
               self.components[key] = nil
               break
            end
         end
      end,
   }
end

-- Helper function to create a mock actor with mining tool
local function createMockMiner(toolType, toolDurability)
   local actor = prism.Actor()
   local tool = MiningTool(toolType or "basic_pickaxe")
   if toolDurability then tool.durability = toolDurability end
   actor:add(tool)
   return actor
end

-- Test mining action validation
function tests.test_mining_validation()
   print("\n--- Testing Mining Validation ---")

   local level = createMockLevel()
   local target = { x = 5, y = 5 }
   local miner = createMockMiner()

   local mine = Mine()
   mine.owner = miner

   -- Test basic validation
   local valid, error = mine:validate(level, target)
   assert_true(valid, "Basic validation should pass")

   -- Test invalid level
   valid, error = mine:validate(nil, target)
   assert_false(valid, "Should fail with no level")

   -- Test invalid target
   valid, error = mine:validate(level, nil)
   assert_false(valid, "Should fail with no target")

   -- Test out of bounds
   valid, error = mine:validate(level, { x = -1, y = 5 })
   assert_false(valid, "Should fail with out of bounds target")
end

-- Test canPerform checks
function tests.test_can_perform()
   print("\n--- Testing Can Perform Checks ---")

   local level = createMockLevel()
   local target = { x = 5, y = 5 }
   local cell = createMockCell()
   level:setCell(5, 5, cell)

   local mine = Mine()

   -- Test without mining tool
   local minerNoTool = prism.Actor()
   mine.owner = minerNoTool
   local canPerform, error = mine:canPerform(level, target)
   assert_false(canPerform, "Should fail without mining tool")

   -- Test with broken tool
   local minerBrokenTool = createMockMiner("basic_pickaxe", 0)
   mine.owner = minerBrokenTool
   canPerform, error = mine:canPerform(level, target)
   assert_false(canPerform, "Should fail with broken tool")

   -- Test without mineable resource
   local minerGoodTool = createMockMiner("basic_pickaxe")
   mine.owner = minerGoodTool
   canPerform, error = mine:canPerform(level, target)
   assert_false(canPerform, "Should fail without mineable resource")

   -- Test with mineable resource
   local resource = MinableResource("coal")
   cell:add(resource)
   canPerform, error = mine:canPerform(level, target)
   assert_true(canPerform, "Should succeed with tool and resource")

   -- Test with tool too weak
   local hardResource = MinableResource("magical_ore") -- hardness 6
   cell.components = {} -- Clear previous resource
   cell:add(hardResource)
   canPerform, error = mine:canPerform(level, target)
   assert_false(canPerform, "Should fail with tool too weak")
end

-- Test resource extraction
function tests.test_resource_extraction()
   print("\n--- Testing Resource Extraction ---")

   local level = createMockLevel()
   local target = { x = 5, y = 5 }
   local cell = createMockCell()
   level:setCell(5, 5, cell)

   local resource = MinableResource("coal")
   cell:add(resource)

   local miner = createMockMiner("basic_pickaxe")
   miner.level = level

   local mine = Mine()
   mine.owner = miner

   -- Store initial quantities
   local initialQuantity = resource.quantity
   local initialDurability = miner:get(MiningTool).durability

   -- Perform mining (may succeed or fail due to randomness)
   mine:perform(level, target)

   -- Check that tool degraded
   local finalDurability = miner:get(MiningTool).durability
   assert_true(finalDurability < initialDurability, "Tool should have degraded")

   -- Check that messages were sent
   assert_true(#level.messages > 0, "Should have sent messages")
end

-- Test time cost calculation
function tests.test_time_cost()
   print("\n--- Testing Time Cost Calculation ---")

   local mine = Mine()

   -- Test with no parameters
   local cost = mine:getTimeCost(nil, nil)
   assert_equal(1.0, cost, "Should return default cost with no parameters")

   -- Test with tool and resource
   local tool = MiningTool("basic_pickaxe")
   local resource = MinableResource("coal")

   cost = mine:getTimeCost(tool, resource)
   assert_true(cost > 0, "Should return positive time cost")

   -- Test that harder resources take longer
   local hardResource = MinableResource("gold")
   local hardCost = mine:getTimeCost(tool, hardResource)
   assert_true(hardCost > cost, "Harder resources should take longer")
end

-- Test resource item creation
function tests.test_resource_item_creation()
   print("\n--- Testing Resource Item Creation ---")

   local mine = Mine()

   -- Test creating resource item
   local resourceItem = mine:createResourceItem("coal", 5)
   assert_true(resourceItem ~= nil, "Should create resource item")
   assert_equal("coal", resourceItem.resourceType, "Should set resource type")

   -- Test item component
   local itemComp = resourceItem:get({ name = "Item" })
   assert_true(itemComp ~= nil, "Should have Item component")
end

-- Run all tests
function run_tests()
   print("Running Mine Action Tests")
   print("=========================")

   for testName, testFunc in pairs(tests) do
      testFunc()
   end

   print("\n=========================")
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
