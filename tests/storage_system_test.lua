-- Unit tests for Storage System
-- This is a basic test suite to verify storage functionality

local CityService = require("modules.game.components.cityservice")
local DepositAction = require("modules.game.actions.deposit")
local WithdrawAction = require("modules.game.actions.withdraw")

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

local function assert_type(expectedType, value, message)
   testCount = testCount + 1
   local actualType = type(value)
   if expectedType == actualType then
      passCount = passCount + 1
      print("✓ " .. (message or "Type test passed"))
   else
      print("✗ " .. (message or "Type test failed") .. " - Expected: " .. expectedType .. ", Got: " .. actualType)
   end
end

-- Mock inventory for testing
local function createMockInventory(items)
   items = items or {}
   return {
      getItemCount = function(self, itemType)
         return items[itemType] or 0
      end,
      canAddItem = function(self, itemType, quantity)
         return true -- Simplified for testing
      end,
      addItem = function(self, itemType, quantity)
         items[itemType] = (items[itemType] or 0) + quantity
      end,
      removeItem = function(self, itemType, quantity)
         items[itemType] = math.max(0, (items[itemType] or 0) - quantity)
      end,
      items = items,
   }
end

-- Mock actor for testing
local function createMockActor(inventory)
   return {
      getComponent = function(self, componentName)
         if componentName == "Inventory" then return inventory end
         return nil
      end,
   }
end

-- Mock storage actor
local function createMockStorage(cityService)
   return {
      getComponent = function(self, componentName)
         if componentName == "CityService" then return cityService end
         return nil
      end,
   }
end

-- Test storage service creation
function tests.test_storage_creation()
   print("\n--- Testing Storage Creation ---")

   local storageService = CityService("storage")

   assert_equal("storage", storageService.serviceType, "Storage service type set correctly")
   assert_type("table", storageService.storageItems, "Storage has storageItems table")
   assert_equal(0, storageService:getTotalStoredItems(), "New storage is empty")
   assert_true(storageService:hasStorageSpace(100), "New storage has space")
end

-- Test deposit action
function tests.test_deposit_action()
   print("\n--- Testing Deposit Action ---")

   local storageService = CityService("storage")
   local playerInventory = createMockInventory({ coal = 10 })
   local player = createMockActor(playerInventory)
   local storage = createMockStorage(storageService)

   -- Test successful deposit
   local depositAction = DepositAction(player, storage, "coal", 5)
   assert_true(depositAction:canPerform(), "Can deposit coal when player has it")

   local success, message = depositAction:perform()
   assert_true(success, "Deposit action succeeded")
   assert_equal(5, playerInventory.items.coal, "Coal removed from player inventory")
   assert_equal(5, storageService.storageItems.coal, "Coal added to storage")
   assert_equal(5, storageService:getTotalStoredItems(), "Total stored items updated")
end

-- Test withdraw action
function tests.test_withdraw_action()
   print("\n--- Testing Withdraw Action ---")

   local storageService = CityService("storage", { storageItems = { coal = 8 } })
   local playerInventory = createMockInventory({ coal = 2 })
   local player = createMockActor(playerInventory)
   local storage = createMockStorage(storageService)

   -- Test successful withdraw
   local withdrawAction = WithdrawAction(player, storage, "coal", 3)
   assert_true(withdrawAction:canPerform(), "Can withdraw coal when storage has it")

   local success, message = withdrawAction:perform()
   assert_true(success, "Withdraw action succeeded")
   assert_equal(5, playerInventory.items.coal, "Coal added to player inventory")
   assert_equal(5, storageService.storageItems.coal, "Coal removed from storage")
   assert_equal(5, storageService:getTotalStoredItems(), "Total stored items updated")
end

-- Test deposit without items
function tests.test_deposit_without_items()
   print("\n--- Testing Deposit Without Items ---")

   local storageService = CityService("storage")
   local playerInventory = createMockInventory({ coal = 2 }) -- Not enough for deposit of 5
   local player = createMockActor(playerInventory)
   local storage = createMockStorage(storageService)

   local depositAction = DepositAction(player, storage, "coal", 5)
   assert_true(not depositAction:canPerform(), "Cannot deposit more than player has")

   local success, message = depositAction:perform()
   assert_true(not success, "Deposit action failed")
   assert_equal(2, playerInventory.items.coal, "Player inventory unchanged")
   assert_equal(0, storageService:getTotalStoredItems(), "Storage remains empty")
end

-- Test withdraw without storage
function tests.test_withdraw_without_storage()
   print("\n--- Testing Withdraw Without Storage ---")

   local storageService = CityService("storage") -- Empty storage
   local playerInventory = createMockInventory({})
   local player = createMockActor(playerInventory)
   local storage = createMockStorage(storageService)

   local withdrawAction = WithdrawAction(player, storage, "coal", 1)
   assert_true(not withdrawAction:canPerform(), "Cannot withdraw from empty storage")

   local success, message = withdrawAction:perform()
   assert_true(not success, "Withdraw action failed")
   assert_equal(0, playerInventory.items.coal or 0, "Player inventory unchanged")
end

-- Test storage capacity
function tests.test_storage_capacity()
   print("\n--- Testing Storage Capacity ---")

   local storageService = CityService("storage")

   assert_equal(1000, storageService:getStorageCapacity(), "Storage has default capacity")
   assert_true(storageService:hasStorageSpace(500), "Storage has space for 500 items")
   assert_true(storageService:hasStorageSpace(1000), "Storage has space for 1000 items")
   assert_true(not storageService:hasStorageSpace(1001), "Storage doesn't have space for 1001 items")
end

-- Test storage clearing
function tests.test_storage_clearing()
   print("\n--- Testing Storage Clearing ---")

   local storageService = CityService("storage", {
      storageItems = { coal = 10, copper = 5, gold = 2 },
   })

   assert_equal(17, storageService:getTotalStoredItems(), "Storage has items initially")

   storageService:clearStorage()
   assert_equal(0, storageService:getTotalStoredItems(), "Storage is empty after clearing")
   assert_type("table", storageService.storageItems, "Storage items table still exists")
end

-- Test multiple deposits and withdrawals
function tests.test_multiple_operations()
   print("\n--- Testing Multiple Operations ---")

   local storageService = CityService("storage")
   local playerInventory = createMockInventory({ coal = 20, copper = 10 })
   local player = createMockActor(playerInventory)
   local storage = createMockStorage(storageService)

   -- Deposit coal
   local depositCoal = DepositAction(player, storage, "coal", 15)
   depositCoal:perform()

   -- Deposit copper
   local depositCopper = DepositAction(player, storage, "copper", 8)
   depositCopper:perform()

   assert_equal(23, storageService:getTotalStoredItems(), "Total items after deposits")
   assert_equal(15, storageService.storageItems.coal, "Coal in storage")
   assert_equal(8, storageService.storageItems.copper, "Copper in storage")

   -- Withdraw some coal
   local withdrawCoal = WithdrawAction(player, storage, "coal", 5)
   withdrawCoal:perform()

   assert_equal(18, storageService:getTotalStoredItems(), "Total items after withdrawal")
   assert_equal(10, storageService.storageItems.coal, "Coal remaining in storage")
   assert_equal(10, playerInventory.items.coal, "Coal back in player inventory")
end

-- Run all tests
local function run_tests()
   print("Running Storage System Tests")
   print("============================")

   for _, testFunc in pairs(tests) do
      testFunc()
   end

   print("\n============================")
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
