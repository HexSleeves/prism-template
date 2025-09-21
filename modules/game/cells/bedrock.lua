prism.registerCell("Bedrock", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Bedrock"),
      prism.components.Drawable { index = "#" },
      prism.components.Collider(),
      prism.components.Opaque(),
   }
end)
