-- Mock prism before requiring the module
prism = {
   System = {
      extend = function(self, name)
         local class = {}
         class.__index = class
         setmetatable(class, {
            __call = function(cls, ...)
               local instance = setmetatable({}, cls)
               if instance.__new then instance:__new(...) end
               return instance
            end,
         })
         return class
      end,
   },
   log = {
      warn = function(msg)
         print("WARN: " .. msg)
      end,
      info = function(msg)
         print("INFO: " .. msg)
      end,
   },
   rng = {
      random = function()
         return math.random()
      end,
   },
}

-- Unit tests for monster scaling system
local MonsterScalingSystem = require("modules.game.systems.monsterscaling")

-- Test suite
local tests = {}
local testCount = 0
local passCount = 0

local function assert_equal(actual, expected, message)
   testCount = testCount + 1
   if actual == expected then
      passCount = passCount + 1
      print("✓ " .. (message or "Test passed"))
   else
      print(
         "✗ " .. (message or "Test failed") .. " - Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual)
      )
   end
end

local function assert_not_nil(value, message)
   testCount = testCount + 1
   if value ~= nil then
      passCount = passCount + 1
      print("✓ " .. (message or "Test passed"))
   else
      print("✗ " .. (message or "Test failed") .. " - Expected non-nil value")
   end
end

local function assert_nil(value, message)
   testCount = testCount + 1
   if value == nil then
      passCount = passCount + 1
      print("✓ " .. (message or "Test passed"))
   else
      print("✗ " .. (message or "Test failed") .. " - Expected nil value, got: " .. tostring(value))
   end
end

local function assert_true(value, message)
   testCount = testCount + 1
   if value == true then
      passCount = passCount + 1
      print("✓ " .. (message or "Test passed"))
   else
      print("✗ " .. (message or "Test failed") .. " - Expected true, got: " .. tostring(value))
   end
end

-- Test calculateScaledStats
function tests.test_calculate_scaled_stats_basic()
   local system = MonsterScalingSystem()

   -- Test CaveRat at minimum depth (should have base stats)
   local stats = system:calculateScaledStats("CaveRat", 1)
   assert_not_nil(stats, "CaveRat stats should not be nil at depth 1")
   assert_equal(stats.health, 15, "CaveRat health should be 15 at minimum depth")
   assert_equal(stats.attack, 3, "CaveRat attack should be 3 at minimum depth")
   assert_equal(stats.defense, 1, "CaveRat defense should be 1 at minimum depth")
end

function tests.test_calculate_scaled_stats_scaling()
   local system = MonsterScalingSystem()

   -- Test CaveRat at depth 3 (2 levels above minimum, scaling factor 0.2)
   -- Expected multiplier: 1.0 + (2 * 0.2) = 1.4
   local stats = system:calculateScaledStats("CaveRat", 3)
   assert_not_nil(stats, "CaveRat stats should not be nil at depth 3")
   assert_equal(stats.health, 21, "CaveRat health should be scaled at depth 3") -- 15 * 1.4 = 21
   assert_equal(stats.attack, 4, "CaveRat attack should be scaled at depth 3") -- 3 * 1.4 = 4.2 -> 4
   assert_equal(stats.defense, 1, "CaveRat defense should be scaled at depth 3") -- 1 * 1.4 = 1.4 -> 1
end

function tests.test_calculate_scaled_stats_invalid_depth()
   local system = MonsterScalingSystem()

   -- Test CaveRat at depth 0 (below minimum)
   local stats = system:calculateScaledStats("CaveRat", 0)
   assert_nil(stats, "CaveRat should not spawn at depth 0")

   -- Test CaveRat at depth 6 (above maximum)
   stats = system:calculateScaledStats("CaveRat", 6)
   assert_nil(stats, "CaveRat should not spawn at depth 6")
end

function tests.test_calculate_scaled_stats_unknown_monster()
   local system = MonsterScalingSystem()

   local stats = system:calculateScaledStats("UnknownMonster", 5)
   assert_nil(stats, "Unknown monster should return nil stats")
end

-- Test getValidMonstersForDepth
function tests.test_get_valid_monsters_surface()
   local system = MonsterScalingSystem()

   local monsters = system:getValidMonstersForDepth(0)
   local count = 0
   for _ in pairs(monsters) do
      count = count + 1
   end
   assert_equal(count, 0, "No monsters should be valid at surface level")
end

function tests.test_get_valid_monsters_shallow()
   local system = MonsterScalingSystem()

   local monsters = system:getValidMonstersForDepth(2)
   assert_not_nil(monsters.CaveRat, "CaveRat should be valid at depth 2")
   assert_not_nil(monsters.SmallSpider, "SmallSpider should be valid at depth 2")
   assert_not_nil(monsters.BatSwarm, "BatSwarm should be valid at depth 2")
   assert_nil(monsters.Troll, "Troll should not be valid at depth 2")
end

function tests.test_get_valid_monsters_deep()
   local system = MonsterScalingSystem()

   local monsters = system:getValidMonstersForDepth(10)
   assert_not_nil(monsters.Troll, "Troll should be valid at depth 10")
   assert_not_nil(monsters.ShadowWraith, "ShadowWraith should be valid at depth 10")
   assert_nil(monsters.CaveRat, "CaveRat should not be valid at depth 10")
end

-- Test calculateSpawnDensity
function tests.test_calculate_spawn_density()
   local system = MonsterScalingSystem()

   assert_equal(system:calculateSpawnDensity(0), 0, "Surface should have 0 spawn density")
   assert_equal(system:calculateSpawnDensity(1), 1.5, "Depth 1 should have 1.5 spawn density")
   assert_equal(system:calculateSpawnDensity(5), 3.5, "Depth 5 should have 3.5 spawn density")
   assert_equal(system:calculateSpawnDensity(20), 8.0, "Deep levels should be capped at 8.0 density")
end

-- Test shouldSpawnMonster
function tests.test_should_spawn_monster_surface()
   local system = MonsterScalingSystem()

   -- Mock RNG that always returns 0.5
   local mockRng = {
      random = function()
         return 0.5
      end,
   }

   local shouldSpawn = system:shouldSpawnMonster(0, 100, mockRng)
   assert_equal(shouldSpawn, false, "Should never spawn monsters on surface")
end

function tests.test_should_spawn_monster_depth()
   local system = MonsterScalingSystem()

   -- Mock RNG that always returns 0.001 (very low, should spawn)
   local mockRng = {
      random = function()
         return 0.001
      end,
   }

   local shouldSpawn = system:shouldSpawnMonster(5, 100, mockRng)
   assert_true(shouldSpawn, "Should spawn monsters at depth with low random value")

   -- Mock RNG that always returns 0.999 (very high, should not spawn)
   mockRng = {
      random = function()
         return 0.999
      end,
   }

   shouldSpawn = system:shouldSpawnMonster(5, 100, mockRng)
   assert_equal(shouldSpawn, false, "Should not spawn monsters at depth with high random value")
end

-- Run all tests
print("Running Monster Scaling System Tests...")
print("=====================================")

for testName, testFunc in pairs(tests) do
   print("\n" .. testName .. ":")
   testFunc()
end

print("\n=====================================")
print("Test Results: " .. passCount .. "/" .. testCount .. " passed")

if passCount == testCount then
   print("All tests passed! ✓")
   return 0
else
   print("Some tests failed! ✗")
   return 1
end
