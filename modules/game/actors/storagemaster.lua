prism.registerActor("StorageMaster", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Storage Master"),
      prism.components.Position(),
      prism.components.Drawable { index = "@", color = prism.Color4.BLUE },
      prism.components.Collider({ movetype = "walk" }),
      prism.components.CityService("storage"),
   }
end)
