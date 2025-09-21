local MinableResource = require("modules.game.components.minableresource")

prism.registerCell("GemDeposit", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Gem Deposit"),
      prism.components.Drawable { index = "*" },
      prism.components.Collider(),
      prism.components.Opaque(),
      MinableResource("gems"),
   }
end)
