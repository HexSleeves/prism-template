prism.registerActor("Torch", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Torch"),
      prism.components.Drawable { index = "T", color = prism.Color4.YELLOW },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.LightSource {
         radius = 4,
         lightType = "torch",
         fuel = 150, -- 150 turns of light
         isActive = true,
      },
   }
end)
