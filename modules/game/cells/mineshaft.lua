prism.registerCell("MineShaft", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Mine Shaft"),
      prism.components.Drawable { index = "O", color = prism.Color4.BROWN },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
   }
end)
