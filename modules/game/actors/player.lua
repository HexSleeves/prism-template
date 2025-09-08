-- local MiningTool = require("modules.game.components.miningtool") -- Unused for now

prism.registerActor("Player", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Player"),
      prism.components.Drawable { index = "@", color = prism.Color4.BLUE },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.PlayerController(),
      prism.components.Senses(),
      prism.components.Sight { range = 6, fov = true },
      prism.components.Mover { "walk" },
      prism.components.DepthTracker(0), -- Start at surface level
      prism.components.LightSource {
         radius = 8,
         lightType = "lantern",
         fuel = 200,
         isActive = true,
      },
      prism.components.Inventory {
         limitCount = 50,
         limitWeight = 100,
      },
      prism.components.MiningTool("basic_pickaxe"),
   }
end)
