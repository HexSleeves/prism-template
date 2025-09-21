prism.registerCell("MineShaft", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Mine Shaft"),
      prism.components.Drawable { index = ">" },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
   }
end)
