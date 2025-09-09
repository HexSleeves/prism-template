-- Unit tests for Shop System
-- This is a basic test suite to verify shop functionality

local CityService = require("modules.game.components.cityservice")
local BuyAction = require("modules.game.actions.buy")
local SellAction = require("modules.game.actions.sell")

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

-- Mock shop actor
local function createMockShop(cityService)
   return {
      getComponent = function(self, componentName)
         if componentName == "CityService" then return cityService end
         return nil
      end,
   }
end

-- Test shop service creation with default prices
function tests.test_shop_default_prices()
   print("\n--- Testing Shop Default Prices ---")

   local shopService = CityService("shop")

   assert_equal("shop", shopService.serviceType, "Shop service type set correctly")
   assert_type("table", shopService.prices, "Shop has prices table")

   -- Test some default prices
   assert_true(shopService.prices.coal > 0, "Coal has a price")
   assert_true(shopService.prices.gold > shopService.prices.coal, "Gold is more expensive than coal")
   assert_true(shopService.prices.gems > shopService.prices.gold, "Gems are more expensive than gold")
end

-- Test rarity multipliers
function tests.test_rarity_multipliers()
   print("\n--- Testing Rarity Multipliers ---")

   local shopService = CityService("shop")

   local coalMultiplier = shopService:getRarityMultiplier("coal")
   local goldMultiplier = shopService:getRarityMultiplier("gold")
   local gemsMultiplier = shopService:getRarityMultiplier("gems")

   assert_equal(1.0, coalMultiplier, "Coal has base rarity multiplier")
   assert_true(goldMultiplier > coalMultiplier, "Gold has higher rarity multiplier than coal")
   assert_true(gemsMultiplier > goldMultiplier, "Gems have higher rarity multiplier than gold")
end

-- Test price updates
function tests.test_price_updates()
   print("\n--- Testing Price Updates ---")

   local shopService = CityService("shop")
   local originalPrice = shopService.prices.coal

   -- Test price increase
   shopService:updatePrice("coal", 1.5)
   assert_true(shopService.prices.coal > originalPrice, "Price increased with demand multiplier")

   -- Test price decrease
   shopService:updatePrice("coal", 0.8)
   assert_true(shopService.prices.coal < originalPrice, "Price decreased with low demand multiplier")
end

-- Test buy action
function tests.test_buy_action()
   print("\n--- Testing Buy Action ---")

   local shopService = CityService("shop")
   local playerInventory = createMockInventory({ coins = 100 })
   local player = createMockActor(playerInventory)
   local shop = createMockShop(shopService)

   -- Test successful buy
   local buyAction = BuyAction(player, shop, "coal", 2)
   assert_true(buyAction:canPerform(), "Can buy coal with enough coins")

   local success, message = buyAction:perform()
   assert_true(success, "Buy action succeeded")
   assert_equal(2, playerInventory.items.coal, "Coal added to inventory")
   assert_equal(90, playerInventory.items.coins, "Coins deducted (5 * 2 = 10)")
end

-- Test sell action
function tests.test_sell_action()
   print("\n--- Testing Sell Action ---")

   local shopService = CityService("shop")
   local playerInventory = createMockInventory({ coal = 5, coins = 0 })
   local player = createMockActor(playerInventory)
   local shop = createMockShop(shopService)

   -- Test successful sell
   local sellAction = SellAction(player, shop, "coal", 3)
   assert_true(sellAction:canPerform(), "Can sell coal when player has it")

   local success, message = sellAction:perform()
   assert_true(success, "Sell action succeeded")
   assert_equal(2, playerInventory.items.coal, "Coal removed from inventory")

   -- Sell price is 60% of buy price: 5 * 0.6 = 3, so 3 * 3 = 9 coins
   assert_equal(9, playerInventory.items.coins, "Coins added from sale")
end

-- Test insufficient funds
function tests.test_insufficient_funds()
   print("\n--- Testing Insufficient Funds ---")

   local shopService = CityService("shop")
   local playerInventory = createMockInventory({ coins = 3 }) -- Not enough for coal (5 coins)
   local player = createMockActor(playerInventory)
   local shop = createMockShop(shopService)

   local buyAction = BuyAction(player, shop, "coal", 1)
   assert_true(not buyAction:canPerform(), "Cannot buy coal without enough coins")

   local success, message = buyAction:perform()
   assert_true(not success, "Buy action failed")
   assert_equal(0, playerInventory.items.coal or 0, "No coal added to inventory")
   assert_equal(3, playerInventory.items.coins, "Coins unchanged")
end

-- Test selling items not owned
function tests.test_sell_without_items()
   print("\n--- Testing Sell Without Items ---")

   local shopService = CityService("shop")
   local playerInventory = createMockInventory({ coins = 0 }) -- No coal
   local player = createMockActor(playerInventory)
   local shop = createMockShop(shopService)

   local sellAction = SellAction(player, shop, "coal", 1)
   assert_true(not sellAction:canPerform(), "Cannot sell coal without having it")

   local success, message = sellAction:perform()
   assert_true(not success, "Sell action failed")
   assert_equal(0, playerInventory.items.coins, "No coins added")
end

-- Run all tests
local function run_tests()
   print("Running Shop System Tests")
   print("=========================")

   for _, testFunc in pairs(tests) do
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
