--- @class LevelGenerator
--- Utility class for generating different types of levels based on depth
local LevelGenerator = {}

--- Configuration for different level types
local LEVEL_CONFIGS = {
   surface = {
      width = 40,
      height = 30,
      lightLevel = 1.0, -- Full brightness
      monsterDensity = 0.0, -- No monsters on surface
   },
   mine = {
      width = 50,
      height = 40,
      baseRoomCount = 8,
      corridorWidth = 1,
      resourceDensity = 0.15, -- 15% of walls are mineable
   },
}

--- Generates a surface city level
--- @param builder LevelBuilder The level builder to use
--- @return LevelBuilder The configured builder
function LevelGenerator.generateSurfaceCity(builder)
   local config = LEVEL_CONFIGS.surface

   -- Create outer walls
   builder:rectangle("line", 0, 0, config.width, config.height, prism.cells.Wall)

   -- Fill interior with floor
   builder:rectangle("fill", 1, 1, config.width - 1, config.height - 1, prism.cells.Floor)

   -- Create building structures
   LevelGenerator._createCityBuildings(builder, config)

   -- Place city services
   LevelGenerator._placeCityServices(builder, config)

   -- Place mine entrance
   LevelGenerator._placeMineEntrance(builder, config)

   return builder
end

--- Creates building structures in the city
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
function LevelGenerator._createCityBuildings(builder, config)
   -- Shop building (northwest)
   builder:rectangle("line", 3, 3, 12, 10, prism.cells.Wall)
   builder:rectangle("fill", 4, 4, 11, 9, prism.cells.Floor)
   -- Shop entrance
   builder:setCell(7, 10, prism.cells.Floor())

   -- Storage building (northeast)
   builder:rectangle("line", config.width - 15, 3, config.width - 4, 10, prism.cells.Wall)
   builder:rectangle("fill", config.width - 14, 4, config.width - 5, 9, prism.cells.Floor)
   -- Storage entrance
   builder:setCell(config.width - 10, 10, prism.cells.Floor())

   -- Inn building (southwest)
   builder:rectangle("line", 3, config.height - 12, 15, config.height - 3, prism.cells.Wall)
   builder:rectangle("fill", 4, config.height - 11, 14, config.height - 4, prism.cells.Floor)
   -- Inn entrance
   builder:setCell(9, config.height - 12, prism.cells.Floor())

   -- Mine office (southeast)
   builder:rectangle(
      "line",
      config.width - 12,
      config.height - 10,
      config.width - 4,
      config.height - 3,
      prism.cells.Wall
   )
   builder:rectangle(
      "fill",
      config.width - 11,
      config.height - 9,
      config.width - 5,
      config.height - 4,
      prism.cells.Floor
   )
   -- Office entrance
   builder:setCell(config.width - 8, config.height - 10, prism.cells.Floor())
end

--- Places city service cells and NPCs
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
function LevelGenerator._placeCityServices(builder, config)
   -- Shop service (inside shop building)
   builder:setCell(8, 6, prism.cells.ShopFloor())
   builder:addActor(prism.actors.Shopkeeper(), 9, 6)

   -- Storage service (inside storage building)
   builder:setCell(config.width - 9, 6, prism.cells.StorageVault())
   builder:addActor(prism.actors.StorageMaster(), config.width - 8, 6)

   -- Inn service (inside inn building)
   builder:setCell(9, config.height - 7, prism.cells.InnFloor())
   builder:addActor(prism.actors.Innkeeper(), 10, config.height - 7)

   -- Mine office service (inside mine office)
   builder:addActor(prism.actors.MineForeman(), config.width - 8, config.height - 6)
end

--- Places the mine entrance
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
function LevelGenerator._placeMineEntrance(builder, config)
   -- Place mine shaft in the center of the city
   local centerX = math.floor(config.width / 2)
   local centerY = math.floor(config.height / 2)

   builder:setCell(centerX, centerY, prism.cells.MineShaft())
end

--- Generates a mine level based on depth
--- @param builder LevelBuilder The level builder to use
--- @param depth integer The depth level (1+)
--- @return LevelBuilder The configured builder
function LevelGenerator.generateMineLevel(builder, depth)
   local config = LEVEL_CONFIGS.mine

   -- Adjust config based on depth
   local adjustedConfig = LevelGenerator._adjustConfigForDepth(config, depth)

   -- Fill with walls initially
   builder:rectangle("fill", 0, 0, adjustedConfig.width, adjustedConfig.height, prism.cells.Wall)

   -- Generate rooms and corridors
   local rooms = LevelGenerator._generateRooms(builder, adjustedConfig)
   LevelGenerator._connectRooms(builder, rooms, adjustedConfig)

   -- Place resources based on depth
   LevelGenerator._placeResources(builder, adjustedConfig, depth)

   -- Place mine shafts for transitions
   LevelGenerator._placeMineShafts(builder, adjustedConfig, rooms)

   -- Add monsters and NPCs based on depth
   LevelGenerator._placeMineActors(builder, adjustedConfig, rooms, depth)

   return builder
end

--- Adjusts mine configuration based on depth
--- @param baseConfig table Base configuration
--- @param depth integer Current depth
--- @return table Adjusted configuration
function LevelGenerator._adjustConfigForDepth(baseConfig, depth)
   local config = {}
   for k, v in pairs(baseConfig) do
      config[k] = v
   end

   -- Increase size slightly with depth
   config.width = baseConfig.width + math.floor(depth / 3) * 5
   config.height = baseConfig.height + math.floor(depth / 3) * 5

   -- Increase room count with depth
   config.roomCount = baseConfig.baseRoomCount + math.floor(depth / 2)

   -- Increase resource density slightly with depth
   config.resourceDensity = math.min(baseConfig.resourceDensity + (depth * 0.02), 0.3)

   return config
end

--- Generates rooms for the mine level
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
--- @return table Array of room rectangles
function LevelGenerator._generateRooms(builder, config)
   local rooms = {}
   local attempts = 0
   local maxAttempts = config.roomCount * 10

   while #rooms < config.roomCount and attempts < maxAttempts do
      attempts = attempts + 1

      -- Generate random room size and position
      local roomWidth = love.math.random(6, 12)
      local roomHeight = love.math.random(6, 10)
      local x = love.math.random(2, config.width - roomWidth - 2)
      local y = love.math.random(2, config.height - roomHeight - 2)

      local newRoom = { x = x, y = y, width = roomWidth, height = roomHeight }

      -- Check if room overlaps with existing rooms
      local overlaps = false
      for _, room in ipairs(rooms) do
         if LevelGenerator._roomsOverlap(newRoom, room) then
            overlaps = true
            break
         end
      end

      if not overlaps then
         -- Create the room
         builder:rectangle("fill", x, y, x + roomWidth, y + roomHeight, prism.cells.Floor)
         table.insert(rooms, newRoom)
      end
   end

   return rooms
end

--- Checks if two rooms overlap (with buffer)
--- @param room1 table First room
--- @param room2 table Second room
--- @return boolean True if rooms overlap
function LevelGenerator._roomsOverlap(room1, room2)
   local buffer = 2 -- Minimum distance between rooms

   return not (
      room1.x + room1.width + buffer < room2.x
      or room2.x + room2.width + buffer < room1.x
      or room1.y + room1.height + buffer < room2.y
      or room2.y + room2.height + buffer < room1.y
   )
end

--- Connects rooms with corridors
--- @param builder LevelBuilder The level builder
--- @param rooms table Array of rooms
--- @param config table Level configuration
function LevelGenerator._connectRooms(builder, rooms, config)
   if #rooms < 2 then return end

   -- Connect each room to the next one
   for i = 1, #rooms - 1 do
      local room1 = rooms[i]
      local room2 = rooms[i + 1]

      -- Get center points of rooms
      local x1 = room1.x + math.floor(room1.width / 2)
      local y1 = room1.y + math.floor(room1.height / 2)
      local x2 = room2.x + math.floor(room2.width / 2)
      local y2 = room2.y + math.floor(room2.height / 2)

      -- Create L-shaped corridor
      LevelGenerator._createCorridor(builder, x1, y1, x2, y1, config.corridorWidth) -- Horizontal
      LevelGenerator._createCorridor(builder, x2, y1, x2, y2, config.corridorWidth) -- Vertical
   end

   -- Connect first and last room to create a loop
   if #rooms > 2 then
      local firstRoom = rooms[1]
      local lastRoom = rooms[#rooms]

      local x1 = firstRoom.x + math.floor(firstRoom.width / 2)
      local y1 = firstRoom.y + math.floor(firstRoom.height / 2)
      local x2 = lastRoom.x + math.floor(lastRoom.width / 2)
      local y2 = lastRoom.y + math.floor(lastRoom.height / 2)

      LevelGenerator._createCorridor(builder, x1, y1, x1, y2, config.corridorWidth) -- Vertical
      LevelGenerator._createCorridor(builder, x1, y2, x2, y2, config.corridorWidth) -- Horizontal
   end
end

--- Creates a corridor between two points
--- @param builder LevelBuilder The level builder
--- @param x1 integer Start X
--- @param y1 integer Start Y
--- @param x2 integer End X
--- @param y2 integer End Y
--- @param width integer Corridor width
function LevelGenerator._createCorridor(builder, x1, y1, x2, y2, width)
   local minX, maxX = math.min(x1, x2), math.max(x1, x2)
   local minY, maxY = math.min(y1, y2), math.max(y1, y2)

   for x = minX, maxX do
      for y = minY, maxY do
         builder:setCell(x, y, prism.cells.Floor())
      end
   end
end

--- Places resources in the mine level
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
--- @param depth integer Current depth
function LevelGenerator._placeResources(builder, config, depth)
   -- Count wall cells that could be converted to resources
   local wallCells = {}

   for x = 1, config.width - 1 do
      for y = 1, config.height - 1 do
         -- Check if this is a wall cell adjacent to a floor
         if LevelGenerator._isWallAdjacentToFloor(builder, x, y, config) then
            table.insert(wallCells, { x = x, y = y })
         end
      end
   end

   -- Convert some walls to resources
   local resourceCount = math.floor(#wallCells * config.resourceDensity)

   for i = 1, resourceCount do
      if #wallCells == 0 then break end

      local index = love.math.random(1, #wallCells)
      local cell = wallCells[index]
      table.remove(wallCells, index)

      -- Choose resource type based on depth
      local resourceCell = LevelGenerator._chooseResourceForDepth(depth)
      builder:setCell(cell.x, cell.y, resourceCell)
   end
end

--- Checks if a position is a wall adjacent to floor
--- @param builder LevelBuilder The level builder
--- @param x integer X coordinate
--- @param y integer Y coordinate
--- @param config table Level configuration
--- @return boolean True if wall is adjacent to floor
function LevelGenerator._isWallAdjacentToFloor(builder, x, y, config)
   -- This is a simplified check - in a real implementation,
   -- you'd check the actual cell type at this position
   -- For now, assume walls are anything not explicitly set to floor

   -- Check adjacent cells for floor
   local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

   for _, dir in ipairs(directions) do
      local nx, ny = x + dir[1], y + dir[2]
      if nx >= 0 and nx < config.width and ny >= 0 and ny < config.height then
         -- This would need to check actual cell type in real implementation
         -- For now, assume it's valid if within bounds
         return true
      end
   end

   return false
end

--- Chooses appropriate resource type for depth
--- @param depth integer Current depth
--- @return Cell Resource cell to place
function LevelGenerator._chooseResourceForDepth(depth)
   local rand = love.math.random()

   if depth <= 3 then
      -- Shallow depths: mostly coal, some copper
      if rand < 0.7 then
         return prism.cells.CoalDeposit()
      else
         return prism.cells.CoalDeposit() -- Only coal for now, copper will be added in task 7.1
      end
   elseif depth <= 7 then
      -- Medium depths: coal, copper, rare gold
      if rand < 0.4 then
         return prism.cells.CoalDeposit()
      elseif rand < 0.8 then
         return prism.cells.CoalDeposit() -- Copper will be added in task 7.1
      else
         return prism.cells.CoalDeposit() -- Gold will be added in task 7.1
      end
   else
      -- Deep levels: all resources, more rare ones
      if rand < 0.2 then
         return prism.cells.CoalDeposit()
      elseif rand < 0.4 then
         return prism.cells.CoalDeposit() -- Copper will be added in task 7.1
      elseif rand < 0.7 then
         return prism.cells.CoalDeposit() -- Gold will be added in task 7.1
      else
         return prism.cells.CoalDeposit() -- Gems will be added in task 7.1
      end
   end
end

--- Places mine shafts for level transitions
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
--- @param rooms table Array of rooms
function LevelGenerator._placeMineShafts(builder, config, rooms)
   if #rooms == 0 then return end

   -- Place entrance shaft in first room
   local firstRoom = rooms[1]
   local entranceX = firstRoom.x + math.floor(firstRoom.width / 2)
   local entranceY = firstRoom.y + math.floor(firstRoom.height / 2)
   builder:setCell(entranceX, entranceY, prism.cells.MineShaft())

   -- Place exit shaft in last room (if more than one room)
   if #rooms > 1 then
      local lastRoom = rooms[#rooms]
      local exitX = lastRoom.x + math.floor(lastRoom.width / 2)
      local exitY = lastRoom.y + math.floor(lastRoom.height / 2)
      builder:setCell(exitX, exitY, prism.cells.MineShaft())
   end
end

--- Places actors (monsters, NPCs) in mine levels
--- @param builder LevelBuilder The level builder
--- @param config table Level configuration
--- @param rooms table[] List of generated rooms
--- @param depth integer Current depth
function LevelGenerator._placeMineActors(builder, config, rooms, depth)
   -- Place monsters based on depth
   local monsterCount = math.min(depth * 2, 10) -- Up to 10 monsters max

   for i = 1, monsterCount do
      local roomIndex = math.random(1, #rooms)
      local room = rooms[roomIndex]

      -- Choose monster type based on depth
      local monsterType
      if depth <= 2 then
         monsterType = math.random() < 0.7 and "CaveRat" or "SmallSpider"
      elseif depth <= 5 then
         monsterType = math.random() < 0.5 and "Kobold" or "Rockworm"
      else
         monsterType = math.random() < 0.4 and "ShadowWraith" or "CaveBear"
      end

      -- Place monster in a random position within the room
      local x = math.random(room.x + 1, room.x + room.width - 2)
      local y = math.random(room.y + 1, room.y + room.height - 2)

      local monsterActor = prism.actors[monsterType]()
      builder:addActor(monsterActor, x, y)
   end

   -- Always place at least one kobold controller for player interaction
   if depth >= 1 then
      local roomIndex = math.random(1, #rooms)
      local room = rooms[roomIndex]
      local x = math.floor(room.x + room.width / 2)
      local y = math.floor(room.y + room.height / 2)

      builder:addActor(prism.actors.Kobold(), x, y)
   end
end

return LevelGenerator
