local MiningTool = require("modules.game.components.miningtool")

prism.registerActor("Pickaxe", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Basic Pickaxe"),
      prism.components.Drawable { index = "⛏", color = prism.Color4.BROWN },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Item {
         weight = 5,
         volume = 3,
         stackable = false,
      },
      MiningTool("basic_pickaxe"),
   }
end)
