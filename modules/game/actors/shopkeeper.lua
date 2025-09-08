prism.registerActor("Shopkeeper", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shopkeeper"),
      prism.components.Position(),
      prism.components.Drawable { index = "@", color = prism.Color4.YELLOW },
      prism.components.Collider({ movetype = "walk" }),
      prism.components.CityService("shop", nil, {
         -- Shop prices for equipment and resources
         coal = 5,
         copper = 15,
         gold = 50,
         gems = 100,
         pickaxe = 25,
         torch = 10,
         lantern = 50,
      }),
   }
end)
