prism.registerCell("ShopFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Shop Floor"),
      prism.components.Drawable { index = "$", color = prism.Color4.YELLOW },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.CityService("shop", nil, {
         -- Default shop prices
         coal = 5,
         copper = 15,
         gold = 50,
         gems = 100,
         pickaxe = 25,
         torch = 10,
      }),
   }
end)
