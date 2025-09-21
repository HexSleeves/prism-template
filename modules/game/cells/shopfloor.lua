local CityService = require("modules.game.components.cityservice")

prism.registerCell("ShopFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Shop Floor"),
      prism.components.Drawable { index = "." },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      CityService("shop"),
   }
end)
