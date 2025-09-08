--- Game utilities module
--- Contains shared utility functions used across the game

local Utils = {}

--- Converts an underscore-separated string to title case
--- @param str string The string to convert (e.g., "basic_pickaxe")
--- @return string The converted string (e.g., "Basic Pickaxe")
function Utils.toTitleCase(str)
   if not str then return "" end

   -- Replace underscores with spaces
   local name = str:gsub("_", " ")

   -- Capitalize first letter of each word
   return (name:gsub("(%a)([%w_']*)", function(first, rest)
      return first:upper() .. rest:lower()
   end))
end

return Utils
