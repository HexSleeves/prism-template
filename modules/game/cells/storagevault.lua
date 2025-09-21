local CityService = require("modules.game.components.cityservice")

prism.registerCell("StorageVault", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Storage Vault"),
      prism.components.Drawable { index = "=" },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      CityService("storage"),
   }
end)
