--- @class MonsterScalingSystem : System
--- System for managing monster spawning and scaling based on depth level
local MonsterScalingSystem = prism.System:extend("MonsterScalingSystem")

--- @class MonsterConfig
--- @field baseStats {health: integer, attack: integer, defense: integer}
--- @field scalingFactor number
--- @field spawnWeight number
--- @field minDepth integer
--- @field maxDepth integer?

--- Monster configuration data for different depth ranges
--- Monster configuration type definition
--- @type table<string, MonsterConfig>
MonsterScalingSystem.monsterConfigs = {
   -- Shallow depth monsters (1-3)
   CaveRat = {
      baseStats = { health = 15, attack = 3, defense = 1 },
      scalingFactor = 0.2,
      spawnWeight = 3.0,
      minDepth = 1,
      maxDepth = 5,
   },
   SmallSpider = {
      baseStats = { health = 12, attack = 4, defense = 0 },
      scalingFactor = 0.25,
      spawnWeight = 2.5,
      minDepth = 1,
      maxDepth = 4,
   },
   BatSwarm = {
      baseStats = { health = 8, attack = 2, defense = 0 },
      scalingFactor = 0.3,
      spawnWeight = 2.0,
      minDepth = 2,
      maxDepth = 6,
   },

   -- Medium depth monsters (4-7)
   GoblinMiner = {
      baseStats = { health = 25, attack = 6, defense = 3 },
      scalingFactor = 0.4,
      spawnWeight = 2.5,
      minDepth = 4,
      maxDepth = 9,
   },
   CaveBear = {
      baseStats = { health = 40, attack = 8, defense = 4 },
      scalingFactor = 0.3,
      spawnWeight = 1.5,
      minDepth = 5,
      maxDepth = 10,
   },
   RockWorm = {
      baseStats = { health = 30, attack = 7, defense = 5 },
      scalingFactor = 0.35,
      spawnWeight = 2.0,
      minDepth = 6,
      maxDepth = 12,
   },

   -- Deep level monsters (8+)
   Troll = {
      baseStats = { health = 80, attack = 12, defense = 8 },
      scalingFactor = 0.5,
      spawnWeight = 1.0,
      minDepth = 8,
      maxDepth = nil,
   },
   ShadowWraith = {
      baseStats = { health = 45, attack = 15, defense = 2 },
      scalingFactor = 0.6,
      spawnWeight = 0.8,
      minDepth = 10,
      maxDepth = nil,
   },
   CrystalGolem = {
      baseStats = { health = 120, attack = 10, defense = 15 },
      scalingFactor = 0.4,
      spawnWeight = 0.5,
      minDepth = 12,
      maxDepth = nil,
   },
}

--- Calculates scaled monster stats based on depth
--- @param monsterType string The type of monster
--- @param depth integer The current depth level
--- @return {health: integer, attack: integer, defense: integer}? Scaled stats or nil if monster not valid for depth
function MonsterScalingSystem:calculateScaledStats(monsterType, depth)
   local config = self.monsterConfigs[monsterType]
   if not config then
      prism.log.warn("Unknown monster type: " .. monsterType)
      return nil
   end

   -- Check if monster can spawn at this depth
   if depth < config.minDepth or (config.maxDepth and depth > config.maxDepth) then return nil end

   -- Calculate scaling multiplier (depth above minimum * scaling factor)
   local depthAboveMin = math.max(0, depth - config.minDepth)
   local scalingMultiplier = 1.0 + (depthAboveMin * config.scalingFactor)

   -- Apply scaling to base stats
   local scaledStats = {
      health = math.floor(config.baseStats.health * scalingMultiplier),
      attack = math.floor(config.baseStats.attack * scalingMultiplier),
      defense = math.floor(config.baseStats.defense * scalingMultiplier),
   }

   return scaledStats
end

--- Gets all valid monster types for a given depth
--- @param depth integer The depth level
--- @return table<string, number> Table of monster types with their spawn weights
function MonsterScalingSystem:getValidMonstersForDepth(depth)
   local validMonsters = {}

   for monsterType, config in pairs(self.monsterConfigs) do
      if depth >= config.minDepth and (not config.maxDepth or depth <= config.maxDepth) then
         validMonsters[monsterType] = config.spawnWeight
      end
   end

   return validMonsters
end

--- Selects a random monster type based on spawn weights for the given depth
--- @param depth integer The depth level
--- @param rng table? Random number generator (uses prism.rng if not provided)
--- @return string? Selected monster type or nil if no valid monsters
function MonsterScalingSystem:selectRandomMonster(depth, rng)
   rng = rng or prism.rng
   local validMonsters = self:getValidMonstersForDepth(depth)

   if not next(validMonsters) then
      return nil -- No valid monsters for this depth
   end

   -- Calculate total weight
   local totalWeight = 0
   for _, weight in pairs(validMonsters) do
      totalWeight = totalWeight + weight
   end

   -- Select random monster based on weights
   local randomValue = rng:random() * totalWeight
   local currentWeight = 0

   for monsterType, weight in pairs(validMonsters) do
      currentWeight = currentWeight + weight
      if randomValue <= currentWeight then return monsterType end
   end

   -- Fallback (should not happen)
   return next(validMonsters)
end

--- Calculates monster spawn density based on depth
--- @param depth integer The depth level
--- @return number Monsters per 100 tiles
function MonsterScalingSystem:calculateSpawnDensity(depth)
   if depth == 0 then
      return 0 -- No monsters on surface
   end

   -- Base density increases with depth
   local baseDensity = 1.0 + (depth * 0.5)

   -- Cap maximum density to prevent overcrowding
   return math.min(baseDensity, 8.0)
end

--- Determines if a monster should spawn at a given location and depth
--- @param depth integer The current depth level
--- @param _tileCount integer Total number of tiles in the level
--- @param rng table? Random number generator (uses prism.rng if not provided)
--- @return boolean True if a monster should spawn
function MonsterScalingSystem:shouldSpawnMonster(depth, _tileCount, rng)
   rng = rng or prism.rng

   if depth == 0 then
      return false -- No spawning on surface
   end

   local density = self:calculateSpawnDensity(depth)
   local spawnChance = density / 100.0 -- Convert density to probability per tile

   return rng:random() < spawnChance
end

return MonsterScalingSystem
