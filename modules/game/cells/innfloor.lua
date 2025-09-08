prism.registerCell("InnFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Inn Floor"),
      prism.components.Drawable { index = "~", color = prism.Color4.GREEN },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.CityService("inn"),
   }
end)
