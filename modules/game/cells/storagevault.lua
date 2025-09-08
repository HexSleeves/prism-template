prism.registerCell("StorageVault", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Storage Vault"),
      prism.components.Drawable { index = "=", color = prism.Color4.BLUE },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.CityService("storage"),
   }
end)
