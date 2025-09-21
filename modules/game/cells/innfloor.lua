local CityService = require("modules.game.components.cityservice")

prism.registerCell("InnFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Inn Floor"),
      prism.components.Drawable { index = "." },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      CityService("inn"),
   }
end)
