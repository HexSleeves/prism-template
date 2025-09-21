local MinableResource = require("modules.game.components.minableresource")

prism.registerCell("CopperOre", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Copper Ore"),
      prism.components.Drawable { index = "%" },
      prism.components.Collider(),
      prism.components.Opaque(),
      MinableResource("copper"),
   }
end)
