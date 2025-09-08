prism.registerActor("Innkeeper", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Innkeeper"),
      prism.components.Position(),
      prism.components.Drawable { index = "@", color = prism.Color4.GREEN },
      prism.components.Collider({ movetype = "walk" }),
      prism.components.CityService("inn"),
   }
end)
