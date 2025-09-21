--- @class GameDisplayHandler
--- Handles all display and rendering logic for the Into the Depths game
local GameDisplayHandler = {}

local PlayerUITools = require("modules.game.ui.player")
local InventoryUtils = require("modules.game.utils.inventory")

--- Renders the main level view with player-centered camera
--- @param display Display The display object
--- @param level Level The current level
--- @param player Actor The player actor
function GameDisplayHandler.renderLevel(display, level, player)
   display:clear()

   if not player then
      -- If no player, just show the full level
      display:putLevel(level)
      return
   end

   local position = player:expectPosition()
   local x, y = display:getCenterOffset(position:decompose())
   display:setCamera(x, y)

   -- Get primary and secondary senses for rendering
   local senses = player:get(prism.components.Senses)
   local sight = player:get(prism.components.Sight)

   local primary = senses
   local secondary = sight

   -- Render the level using the player's senses
   display:putSenses(primary, secondary, level)
end

--- Renders the player's light source status
--- @param display Display The display object
--- @param player Actor The player actor
function GameDisplayHandler.renderLightStatus(display, player)
   if not player then return end

   PlayerUITools.DisplayLightSource(display, player)
end

--- Renders the current depth information
--- @param display Display The display object
--- @param player Actor The player actor
--- @param yOffset integer? Y offset for positioning (default 2)
function GameDisplayHandler.renderDepthInfo(display, player, yOffset)
   if not player then return end

   yOffset = yOffset or 2

   local depthTracker = player:get(prism.components.DepthTracker)
   if depthTracker then
      local depth = depthTracker:getCurrentDepth()
      local depthText = depth == 0 and "Surface" or ("Depth: " .. depth)
      display:putString(2, yOffset, depthText, prism.Color4.WHITE)
   end
end

--- Renders game status information (health, inventory, etc.)
--- @param display Display The display object
--- @param player Actor The player actor
function GameDisplayHandler.renderGameStatus(display, player)
   if not player then return end

   local yPos = 6 -- Start below light and depth info

   -- Render inventory status if available
   local inventory = player:get(prism.components.Inventory)
   if inventory then
      -- Show coin count
      local coins = InventoryUtils.getItemCount(inventory, "coins")
      display:putString(1, yPos, "Coins: " .. coins, prism.Color4.YELLOW)
      yPos = yPos + 1

      -- Show inventory weight/count if there are limits
      if inventory.limitCount and inventory.limitCount > 0 then
         display:putString(
            1,
            yPos,
            "Items: " .. inventory.totalCount .. "/" .. inventory.limitCount,
            prism.Color4.WHITE
         )
         yPos = yPos + 1
      end
   end

   -- Render mining tool status
   local miningTool = player:get(prism.components.MiningTool)
   if miningTool then
      local toolStatus = miningTool:getConditionString()
      local toolColor = prism.Color4.WHITE

      if miningTool:isBroken() then
         toolColor = prism.Color4.RED
      elseif miningTool:needsRepair() then
         toolColor = prism.Color4.YELLOW
      end

      display:putString(1, yPos, "Tool: " .. toolStatus, toolColor)
      yPos = yPos + 1
   end
end

--- Renders help text and controls information
--- @param display Display The display object
--- @param screenWidth integer Width of the display
--- @param screenHeight integer Height of the display
function GameDisplayHandler.renderHelpText(display, screenWidth, screenHeight)
   local helpLines = {
      "Arrow keys: Move",
      "Space: Wait",
      "T: Toggle light",
      "M: Mine nearby",
      "Enter: Interact",
      "Q: Quit",
   }

   local startY = screenHeight - #helpLines - 1

   for i, line in ipairs(helpLines) do
      display:putString(screenWidth - 20, startY + i - 1, line, prism.Color4.GREY)
   end
end

--- Main rendering function that orchestrates all display elements
--- @param display Display The display object
--- @param level Level The current level
--- @param player Actor? The player actor
--- @param showHelp boolean? Whether to show help text (default false)
function GameDisplayHandler.render(display, level, player, showHelp)
   -- Render the main level view
   GameDisplayHandler.renderLevel(display, level, player)

   -- Render UI elements if player exists
   if player then
      GameDisplayHandler.renderLightStatus(display, player)
      -- GameDisplayHandler.renderDepthInfo(display, player, 3)
      -- GameDisplayHandler.renderGameStatus(display, player)
   end

   -- Render help text if requested
   if showHelp then
      local screenWidth = display.width or 80
      local screenHeight = display.height or 24
      GameDisplayHandler.renderHelpText(display, screenWidth, screenHeight)
   end

   -- Final draw call
   display:draw()
end

return GameDisplayHandler
