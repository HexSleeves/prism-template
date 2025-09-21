--- @class MonsterFactory : System
--- Factory system for creating monsters with scaled stats based on depth
local MonsterFactory = prism.System:extend("MonsterFactory")
local MonsterScalingSystem = require("modules.game.systems.monsterscaling")
local CombatStats = require("modules.game.components.combatstats")

--- Creates a monster actor with scaled stats for the given depth
--- @param monsterType string The type of monster to create
--- @param depth integer The current depth level
--- @param position table? Optional position {x, y}
--- @return Actor? The created monster actor or nil if invalid
function MonsterFactory:createMonster(monsterType, depth, position)
   local scalingSystem = MonsterScalingSystem()
   local scaledStats = scalingSystem:calculateScaledStats(monsterType, depth)

   if not scaledStats then
      prism.logger.warn("Cannot create " .. monsterType .. " at depth " .. depth)
      return nil
   end

   -- Create the base monster actor
   local actorFactory = prism.actors[monsterType]
   if not actorFactory then
      prism.logger.warn("Unknown monster type: " .. monsterType)
      return nil
   end

   local monster = actorFactory()
   if not monster then
      prism.logger.warn("Failed to create monster: " .. monsterType)
      return nil
   end

   -- Add scaled combat stats
   local combatStats = CombatStats.fromScaledStats(scaledStats)
   monster:give(combatStats)

   -- Set position if provided
   if position then
      local posComponent = monster:get(prism.components.Position)
      if posComponent then monster:give(prism.components.Position(prism.Vector2(position.x, position.y))) end
   end

   return monster
end

--- Creates a random monster appropriate for the given depth
--- @param depth integer The current depth level
--- @param position table? Optional position {x, y}
--- @param rng table? Random number generator (uses prism.rng if not provided)
--- @return Actor? The created monster actor or nil if no valid monsters
function MonsterFactory:createRandomMonster(depth, position, rng)
   local scalingSystem = MonsterScalingSystem()
   local monsterType = scalingSystem:selectRandomMonster(depth, rng)

   if not monsterType then return nil end

   return self:createMonster(monsterType, depth, position)
end

--- Spawns monsters in a level based on depth and spawn density
--- @param level Level The level to spawn monsters in
--- @param depth integer The current depth level
--- @param rng table? Random number generator (uses prism.rng if not provided)
--- @return integer Number of monsters spawned
function MonsterFactory:spawnMonstersInLevel(level, depth, rng)
   rng = rng or prism.rng
   local scalingSystem = MonsterScalingSystem()

   if depth == 0 then
      return 0 -- No monsters on surface
   end

   local spawnedCount = 0
   local levelSize = level.map.w * level.map.h

   -- Iterate through all floor tiles and potentially spawn monsters
   for x = 1, level.map.w do
      for y = 1, level.map.h do
         local cell = level:getCell(x, y)

         -- Only spawn on walkable floor tiles that don't have actors
         local actorsAtPos = level.actorStorage:getSparseMap():get(x, y)
         if cell and cell.name == "Floor" and not actorsAtPos then
            if scalingSystem:shouldSpawnMonster(depth, levelSize, rng) then
               local monster = self:createRandomMonster(depth, { x = x, y = y }, rng)
               if monster then
                  level:addActor(monster)
                  spawnedCount = spawnedCount + 1
               end
            end
         end
      end
   end

   prism.logger.info("Spawned " .. spawnedCount .. " monsters at depth " .. depth)
   return spawnedCount
end

return MonsterFactory
