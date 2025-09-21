local MinableResource = require("modules.game.components.minableresource")

prism.registerCell("GoldVein", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Gold Vein"),
      prism.components.Drawable { index = "*" },
      prism.components.Collider(),
      prism.components.Opaque(),
      MinableResource("gold"),
   }
end)
