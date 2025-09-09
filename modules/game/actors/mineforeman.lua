prism.registerActor("MineForeman", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Mine Foreman"),
      prism.components.Position(),
      prism.components.Drawable { index = "@", color = prism.Color4.BROWN },
      prism.components.Collider({ movetype = "walk" }),
      prism.components.CityService("foreman"),
   }
end)
