-- Unit tests for CityService component
-- This is a basic test suite to verify CityService functionality

local CityService = require("modules.game.components.cityservice")

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

-- Test CityService component creation
function tests.test_cityservice_creation()
   print("\n--- Testing CityService Creation ---")

   -- Test shop service
   local shopService = CityService("shop", {
      prices = { coal = 5, copper = 15 },
   })

   assert_equal("shop", shopService.serviceType, "Shop service type set correctly")
   assert_equal(5, shopService.prices.coal, "Coal price set correctly")
   assert_equal(15, shopService.prices.copper, "Copper price set correctly")
   assert_true(shopService.isActive, "Service is active by default")

   -- Test storage service
   local storageService = CityService("storage")
   assert_equal("storage", storageService.serviceType, "Storage service type set correctly")
   assert_type("table", storageService.storageItems, "Storage has storageItems table")

   -- Test inn service
   local innService = CityService("inn")
   assert_equal("inn", innService.serviceType, "Inn service type set correctly")

   -- Test foreman service
   local foremanService = CityService("foreman")
   assert_equal("foreman", foremanService.serviceType, "Foreman service type set correctly")
end

-- Test interaction text
function tests.test_interaction_text()
   print("\n--- Testing Interaction Text ---")

   local shopService = CityService("shop")
   local storageService = CityService("storage")
   local innService = CityService("inn")
   local foremanService = CityService("foreman")

   assert_type("string", shopService:getInteractionText(), "Shop returns interaction text")
   assert_type("string", storageService:getInteractionText(), "Storage returns interaction text")
   assert_type("string", innService:getInteractionText(), "Inn returns interaction text")
   assert_type("string", foremanService:getInteractionText(), "Foreman returns interaction text")

   -- Test specific interaction texts
   local shopText = shopService:getInteractionText()
   assert_true(string.find(shopText, "buy") ~= nil, "Shop text mentions buying")
   assert_true(string.find(shopText, "sell") ~= nil, "Shop text mentions selling")

   local storageText = storageService:getInteractionText()
   assert_true(string.find(storageText, "deposit") ~= nil, "Storage text mentions deposit")
   assert_true(string.find(storageText, "withdraw") ~= nil, "Storage text mentions withdraw")
end

-- Test service interaction capability
function tests.test_interaction_capability()
   print("\n--- Testing Interaction Capability ---")

   local service = CityService("shop")

   -- Test with mock player (has Position component)
   local mockPlayer = {
      hasComponent = function(self, componentName)
         return componentName == "Position"
      end,
   }

   assert_true(service:canInteract(mockPlayer), "Player with Position can interact")

   -- Test with mock player without Position
   local mockPlayerNoPos = {
      hasComponent = function(self, componentName)
         return false
      end,
   }

   assert_true(not service:canInteract(mockPlayerNoPos), "Player without Position cannot interact")

   -- Test inactive service
   service.isActive = false
   assert_true(not service:canInteract(mockPlayer), "Inactive service cannot be interacted with")
end

-- Run all tests
local function run_tests()
   print("Running CityService Component Tests")
   print("===================================")

   for _, testFunc in pairs(tests) do
      testFunc()
   end

   print("\n===================================")
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
