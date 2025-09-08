-- Mock prism before requiring modules
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
   Component = {
      extend = function(self, name)
         local class = {}
         class.__index = class
         class.name = name
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
   Actor = {
      fromComponents = function(components)
         local actor = {
            components = {},
            addComponent = function(self, component)
               self.components[component.name] = component
            end,
            get = function(self, componentType)
               return self.components[componentType.name]
            end,
         }
         for _, component in ipairs(components) do
            if component.name then actor.components[component.name] = component end
         end
         return actor
      end,
   },
   actors = {
      CaveRat = function()
         return prism.Actor.fromComponents({
            { name = "Name", value = "Cave Rat" },
            { name = "Position", x = 0, y = 0 },
            { name = "Drawable", index = "r" },
         })
      end,
      SmallSpider = function()
         return prism.Actor.fromComponents({
            { name = "Name", value = "Small Spider" },
            { name = "Position", x = 0, y = 0 },
            { name = "Drawable", index = "s" },
         })
      end,
      BatSwarm = function()
         return prism.Actor.fromComponents({
            { name = "Name", value = "Bat Swarm" },
            { name = "Position", x = 0, y = 0 },
            { name = "Drawable", index = "b" },
         })
      end,
      Troll = function()
         return prism.Actor.fromComponents({
            { name = "Name", value = "Troll" },
            { name = "Position", x = 0, y = 0 },
            { name = "Drawable", index = "T" },
         })
      end,
   },
   components = {
      Position = { name = "Position" },
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

-- Unit tests for monster factory system
local MonsterFactory = require("modules.game.systems.monsterfactory")
local CombatStats = require("modules.game.components.combatstats")

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

-- Test CombatStats component
function tests.test_combat_stats_creation()
   local stats = CombatStats(20, 5, 2)
   assert_equal(stats.health, 20, "Health should be set correctly")
   assert_equal(stats.maxHealth, 20, "Max health should be set correctly")
   assert_equal(stats.attack, 5, "Attack should be set correctly")
   assert_equal(stats.defense, 2, "Defense should be set correctly")
end

function tests.test_combat_stats_from_scaled()
   local scaledStats = { health = 30, attack = 8, defense = 4 }
   local stats = CombatStats.fromScaledStats(scaledStats)
   assert_equal(stats.health, 30, "Health should match scaled stats")
   assert_equal(stats.attack, 8, "Attack should match scaled stats")
   assert_equal(stats.defense, 4, "Defense should match scaled stats")
end

function tests.test_combat_stats_take_damage()
   local stats = CombatStats(20, 5, 2)

   -- Take 5 damage, defense reduces it to 3
   local died = stats:takeDamage(5)
   assert_equal(stats.health, 17, "Health should be reduced by damage minus defense")
   assert_equal(died, false, "Should not die from non-lethal damage")

   -- Take massive damage
   died = stats:takeDamage(20)
   assert_equal(died, true, "Should die from lethal damage")
end

function tests.test_combat_stats_heal()
   local stats = CombatStats(20, 5, 2)
   stats:takeDamage(10) -- Reduce to 12 health (20 - 8)

   stats:heal(5)
   assert_equal(stats.health, 17, "Should heal correctly")

   stats:heal(10) -- Try to overheal
   assert_equal(stats.health, 20, "Should not exceed max health")
end

-- Test MonsterFactory
function tests.test_create_monster_valid()
   local factory = MonsterFactory()
   local monster = factory:createMonster("CaveRat", 2)

   assert_not_nil(monster, "Should create valid monster")
   local combatStats = monster:get(CombatStats)
   assert_not_nil(combatStats, "Monster should have combat stats")
   assert_equal(combatStats.health, 18, "Monster should have scaled health") -- 15 * 1.2 = 18
end

function tests.test_create_monster_invalid_depth()
   local factory = MonsterFactory()
   local monster = factory:createMonster("CaveRat", 0) -- Surface level

   assert_nil(monster, "Should not create monster at invalid depth")
end

function tests.test_create_monster_with_position()
   local factory = MonsterFactory()
   local monster = factory:createMonster("CaveRat", 2, { x = 5, y = 10 })

   assert_not_nil(monster, "Should create monster with position")
   local position = monster:get(prism.components.Position)
   assert_not_nil(position, "Monster should have position component")
   assert_equal(position.x, 5, "X position should be set correctly")
   assert_equal(position.y, 10, "Y position should be set correctly")
end

function tests.test_create_random_monster()
   local factory = MonsterFactory()

   -- Mock RNG to always select first monster
   local mockRng = {
      random = function()
         return 0.001
      end,
   }

   local monster = factory:createRandomMonster(2, nil, mockRng)
   assert_not_nil(monster, "Should create random monster")

   if monster then
      local combatStats = monster:get(CombatStats)
      assert_not_nil(combatStats, "Random monster should have combat stats")
   end
end

function tests.test_create_random_monster_invalid_depth()
   local factory = MonsterFactory()
   local monster = factory:createRandomMonster(0) -- Surface level

   assert_nil(monster, "Should not create random monster at surface")
end

-- Run all tests
print("Running Monster Factory Tests...")
print("===============================")

for testName, testFunc in pairs(tests) do
   print("\n" .. testName .. ":")
   testFunc()
end

print("\n===============================")
print("Test Results: " .. passCount .. "/" .. testCount .. " passed")

if passCount == testCount then
   print("All tests passed! ✓")
   return 0
else
   print("Some tests failed! ✗")
   return 1
end
