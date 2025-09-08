local MinableResource = require("modules.game.components.minableresource")

prism.registerCell("CoalDeposit", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Coal Deposit"),
      prism.components.Drawable { index = "♦", color = prism.Color4.BLACK },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      MinableResource("coal"),
   }
end)
