--- Small Spider - Poisonous but fragile arachnid found in shallow depths
prism.registerActor("SmallSpider", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Small Spider"),
      prism.components.Position(),
      prism.components.Drawable { index = "s", color = prism.Color4.GREEN },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 6, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
