--- Enhanced Sight System that considers light sources and depth-based darkness
--- @class EnhancedSightSystem : System
local EnhancedSightSystem = prism.System:extend("EnhancedSightSystem")

function EnhancedSightSystem:getRequirements()
   return prism.systems.Senses
end

--- Calculate the ambient light level based on depth
--- @param depth integer Current depth level (0 = surface)
--- @return number Ambient light level (0.0 to 1.0)
function EnhancedSightSystem:getAmbientLightLevel(depth)
   if depth <= 0 then
      return 1.0 -- Full light on surface
   elseif depth <= 3 then
      return 0.7 -- Moderate light at shallow depths
   elseif depth <= 7 then
      return 0.3 -- Low light at medium depths
   else
      return 0.1 -- Very dark at deep levels
   end
end

--- Calculate the base sight range considering ambient light and actor's own light source
--- @param originalRange integer Original sight range from Sight component
--- @param ambientLight number Ambient light level (0.0 to 1.0)
--- @param actor Actor The actor whose sight is being calculated
--- @return integer Adjusted sight range
function EnhancedSightSystem:getBaseSightRange(originalRange, ambientLight, actor)
   -- Check if the actor has an active light source
   local ownLightSource = actor:get(prism.components.LightSource)
   local hasActiveLight = ownLightSource and ownLightSource.isActive and ownLightSource:getEffectiveRadius() > 0
   
   -- In very dark conditions (deep underground), without a light source, sight is extremely limited
   if ambientLight <= 0.1 and not hasActiveLight then
      return 2 -- Only 2 cells in the mine without light
   elseif ambientLight <= 0.3 and not hasActiveLight then
      return 3 -- Slightly better in moderate darkness
   elseif ambientLight <= 0.1 then
      return math.max(3, math.floor(originalRange * 0.3)) -- Even with light, very dark areas limit sight
   elseif ambientLight <= 0.3 then
      return math.max(4, math.floor(originalRange * 0.6)) -- Moderate darkness
   elseif ambientLight <= 0.7 then
      return math.max(5, math.floor(originalRange * 0.8)) -- Low light conditions
   else
      return originalRange -- Full range in good light (surface)
   end
end

--- Get all active light sources affecting an actor
--- @param level Level The current level
--- @param actor Actor The actor to check light sources for
--- @return table List of {source: LightSource, distance: number, actor: Actor}
function EnhancedSightSystem:getActiveLightSources(level, actor)
   local actorPos = actor:getPosition()
   if not actorPos then return {} end
   
   local lightSources = {}
   
   -- Check the actor's own light sources
   local ownLightSource = actor:get(prism.components.LightSource)
   if ownLightSource and ownLightSource:getEffectiveRadius() > 0 then
      table.insert(lightSources, {
         source = ownLightSource,
         distance = 0,
         actor = actor
      })
   end
   
   -- Check other actors' light sources
   for otherActor in level:query(prism.components.LightSource):iter() do
      if otherActor ~= actor then
         local otherPos = otherActor:getPosition()
         if otherPos then
            local lightSource = otherActor:get(prism.components.LightSource)
            if lightSource and lightSource:getEffectiveRadius() > 0 then
               local distance = actorPos:distance(otherPos)
               if distance <= lightSource:getEffectiveRadius() then
                  table.insert(lightSources, {
                     source = lightSource,
                     distance = distance,
                     actor = otherActor
                  })
               end
            end
         end
      end
   end
   
   return lightSources
end

--- Calculate the effective sight range considering light sources
--- @param baseSightRange integer Base sight range from ambient light
--- @param lightSources table List of active light sources
--- @param actor Actor The actor whose sight is being calculated
--- @return integer Effective sight range
function EnhancedSightSystem:calculateEffectiveSightRange(baseSightRange, lightSources, actor)
   local maxLightRadius = 0
   local hasOwnActiveLight = false
   
   for _, lightInfo in ipairs(lightSources) do
      local effectiveRadius = lightInfo.source:getEffectiveRadius()
      -- Light effectiveness decreases with distance
      if lightInfo.distance == 0 then
         -- Own light source - full effectiveness
         hasOwnActiveLight = true
         maxLightRadius = math.max(maxLightRadius, effectiveRadius)
      else
         -- Other light source - reduced effectiveness based on distance
         local effectiveness = math.max(0, 1 - (lightInfo.distance / effectiveRadius))
         local adjustedRadius = math.floor(effectiveRadius * effectiveness)
         maxLightRadius = math.max(maxLightRadius, adjustedRadius)
      end
   end
   
   -- If we have an active light source, combine base sight with light sources
   if hasOwnActiveLight or maxLightRadius > 0 then
      return math.max(baseSightRange, maxLightRadius)
   else
      -- No active light sources - use the restricted base sight range
      return baseSightRange
   end
end

--- Enhanced FOV computation that considers light sources
--- @param level Level The current level
--- @param sensesComponent Senses The actor's senses component
--- @param origin Vector2 The actor's position
--- @param maxDepth integer Maximum sight range
--- @param lightSources table List of active light sources
function EnhancedSightSystem:computeEnhancedFOV(level, sensesComponent, origin, maxDepth, lightSources)
   -- Clear existing sight data
   sensesComponent.cells = prism.SparseGrid()
   
   -- Always see the current position
   sensesComponent.cells:set(origin.x, origin.y, level:getCell(origin.x, origin.y))
   
   -- Create a light map to track illuminated areas
   local lightMap = prism.SparseGrid()
   
   -- Mark areas illuminated by light sources
   for _, lightInfo in ipairs(lightSources) do
      local lightPos = lightInfo.actor:getPosition()
      if lightPos then
         local lightRadius = lightInfo.source:getEffectiveRadius()
         
         -- Use FOV algorithm to determine what the light source illuminates
         prism.computeFOV(level, lightPos, lightRadius, function(x, y)
            local distance = lightPos:distance(prism.Vector2(x, y))
            if distance <= lightRadius then
               -- Store light intensity at this position
               local intensity = math.max(0, 1 - (distance / lightRadius))
               local existingIntensity = lightMap:get(x, y) or 0
               lightMap:set(x, y, math.max(existingIntensity, intensity))
            end
         end)
      end
   end
   
   -- Compute FOV with light-enhanced visibility
   prism.computeFOV(level, origin, maxDepth, function(x, y)
      local distance = origin:distance(prism.Vector2(x, y))
      local lightIntensity = lightMap:get(x, y) or 0
      
      -- Determine if this cell is visible
      local visible = false
      
      if distance <= maxDepth then
         if lightIntensity > 0 then
            -- Cell is illuminated by a light source
            visible = true
         else
            -- Cell relies on ambient light and base sight
            -- In very dark conditions, only see adjacent cells without light
            local actorWithDepthTracker = level:query(prism.components.DepthTracker):first()
            local currentDepth = 0
            if actorWithDepthTracker then
               local depthTracker = actorWithDepthTracker:get(prism.components.DepthTracker)
               currentDepth = depthTracker and depthTracker:getCurrentDepth() or 0
            end
            local ambientLight = self:getAmbientLightLevel(currentDepth)
            
            if ambientLight > 0.3 or distance <= 2 then
               visible = true
            end
         end
      end
      
      if visible then
         sensesComponent.cells:set(x, y, level:getCell(x, y))
      end
   end)
end

--- Main sight processing function
--- @param level Level The current level
--- @param actor Actor The actor whose sight is being processed
function EnhancedSightSystem:onSenses(level, actor)
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end
   
   local sightComponent = actor:get(prism.components.Sight)
   if not sightComponent then return end
   
   local actorPos = actor:getPosition()
   if not actorPos then return end
   
   -- Get current depth for ambient light calculation
   local depthTracker = actor:get(prism.components.DepthTracker)
   local currentDepth = depthTracker and depthTracker:getCurrentDepth() or 0
   
   -- Calculate ambient light level
   local ambientLight = self:getAmbientLightLevel(currentDepth)
   
   -- Get base sight range adjusted for ambient light and own light source
   local baseSightRange = self:getBaseSightRange(sightComponent.range, ambientLight, actor)
   
   -- Get active light sources
   local lightSources = self:getActiveLightSources(level, actor)
   
   -- Calculate effective sight range
   local effectiveSightRange = self:calculateEffectiveSightRange(baseSightRange, lightSources, actor)
   
   if sightComponent.fov then
      -- Use enhanced FOV computation
      self:computeEnhancedFOV(level, sensesComponent, actorPos, effectiveSightRange, lightSources)
   else
      -- Simple radius-based sight (for simple actors)
      sensesComponent.cells = prism.SparseGrid()
      for x = actorPos.x - effectiveSightRange, actorPos.x + effectiveSightRange do
         for y = actorPos.y - effectiveSightRange, actorPos.y + effectiveSightRange do
            if level:inBounds(x, y) then
               local distance = actorPos:distance(prism.Vector2(x, y))
               if distance <= effectiveSightRange then
                  sensesComponent.cells:set(x, y, level:getCell(x, y))
               end
            end
         end
      end
   end
   
   -- Add visible light sources (they should be visible even outside normal FOV)
   self:addVisibleLightSources(level, actor, sensesComponent, actorPos)
   
   -- Update seen actors
   self:updateSeenActors(level, actor)
end

--- Add the illuminated area around a light source to the actor's sight
--- @param level Level The current level
--- @param sensesComponent Senses The actor's senses component
--- @param lightPos Vector2 The position of the light source
--- @param lightRadius integer The radius of the light source
function EnhancedSightSystem:addIlluminatedArea(level, sensesComponent, lightPos, lightRadius)
   -- Use FOV computation from the light source's position to determine what it illuminates
   prism.computeFOV(level, lightPos, lightRadius, function(x, y)
      if level:inBounds(x, y) then
         -- Add this cell to the actor's visible cells
         sensesComponent.cells:set(x, y, level:getCell(x, y))
      end
   end)
end

--- Add visible light sources to the actor's sight
--- Light sources should be visible even when outside normal FOV if they're active
--- @param level Level The current level
--- @param actor Actor The actor whose sight is being processed
--- @param sensesComponent Senses The actor's senses component
--- @param actorPos Vector2 The actor's position
function EnhancedSightSystem:addVisibleLightSources(level, actor, sensesComponent, actorPos)
   -- Find all active light sources in the level
   for lightActor in level:query(prism.components.LightSource):iter() do
      if lightActor ~= actor then -- Don't process the actor's own light source
         local lightSource = lightActor:get(prism.components.LightSource)
         local lightPos = lightActor:getPosition()
         
         if lightSource and lightPos and lightSource.isActive and lightSource:getEffectiveRadius() > 0 then
            local distance = actorPos:distance(lightPos)
            
            -- Light sources illuminate their area if they're within a reasonable distance
            -- Light can be seen through walls, so no line of sight check needed
            -- Make light sources visible from much farther away in open areas
            local maxVisibleDistance = math.max(lightSource:getEffectiveRadius() * 8, 50)
            
            if distance <= maxVisibleDistance then
               -- Add the illuminated area around this light source
               self:addIlluminatedArea(level, sensesComponent, lightPos, lightSource:getEffectiveRadius())
            end
         end
      end
   end
end

--- Update which actors this actor can see
--- @param level Level The current level
--- @param actor Actor The actor whose sight is being processed
function EnhancedSightSystem:updateSeenActors(level, actor)
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end
   
   -- Clear existing sight relationships
   actor:removeAllRelationships(prism.relationships.Sees)
   
   -- Add relationships for all actors in visible cells
   for x, y, _ in sensesComponent.cells:each() do
      for other, _ in pairs(level.actorStorage:getSparseMap():get(x, y)) do
         actor:addRelationship(prism.relationships.Sees, other)
         actor:addRelationship(prism.relationships.Senses, other)
      end
   end
end

return EnhancedSightSystem