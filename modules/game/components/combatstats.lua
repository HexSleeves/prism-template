--- @class CombatStats : Component
--- @field health integer Current health points
--- @field maxHealth integer Maximum health points
--- @field attack integer Attack power
--- @field defense integer Defense rating
local CombatStats = prism.Component:extend("CombatStats")
CombatStats.name = "CombatStats"

--- Creates a new CombatStats component
--- @param health integer Current and maximum health
--- @param attack integer Attack power
--- @param defense integer Defense rating
function CombatStats:__new(health, attack, defense)
   self.health = health or 10
   self.maxHealth = health or 10
   self.attack = attack or 1
   self.defense = defense or 0
end

--- Creates CombatStats from scaled stats table
--- @param scaledStats {health: integer, attack: integer, defense: integer}
--- @return CombatStats
function CombatStats.fromScaledStats(scaledStats)
   return CombatStats(scaledStats.health, scaledStats.attack, scaledStats.defense)
end

--- Takes damage and returns true if the entity dies
--- @param damage integer Amount of damage to take
--- @return boolean True if health reaches 0 or below
function CombatStats:takeDamage(damage)
   local actualDamage = math.max(1, damage - self.defense) -- Minimum 1 damage
   self.health = self.health - actualDamage
   return self.health <= 0
end

--- Heals the entity up to maximum health
--- @param amount integer Amount to heal
function CombatStats:heal(amount)
   self.health = math.min(self.maxHealth, self.health + amount)
end

--- Gets the current health percentage
--- @return number Health percentage (0.0 to 1.0)
function CombatStats:getHealthPercentage()
   return self.health / self.maxHealth
end

--- Checks if the entity is alive
--- @return boolean True if health is above 0
function CombatStats:isAlive()
   return self.health > 0
end

return CombatStats
