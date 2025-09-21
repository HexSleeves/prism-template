prism.registerCell("SupportBeam", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Support Beam"),
      prism.components.Drawable { index = "|" },
      prism.components.Collider(),
      prism.components.Opaque(),
   }
end)
