prism.registerCell("MineCartTrack", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Mine Cart Track"),
      prism.components.Drawable { index = "=" },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
   }
end)
