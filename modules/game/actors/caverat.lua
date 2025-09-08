--- Cave Rat - Fast, weak scavenger found in shallow depths
prism.registerActor("CaveRat", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Cave Rat"),
      prism.components.Position(),
      prism.components.Drawable { index = "r", color = prism.Color4.BROWN },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
