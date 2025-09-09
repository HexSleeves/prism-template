prism.registerActor("Shopkeeper", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shopkeeper"),
      prism.components.Position(),
      prism.components.Drawable { index = "@", color = prism.Color4.YELLOW },
      prism.components.Collider({ movetype = "walk" }),
      prism.components.CityService("shop"),
   }
end)
