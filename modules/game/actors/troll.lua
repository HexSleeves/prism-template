--- Troll - Massive, regenerating creature found in deep levels
prism.registerActor("Troll", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Troll"),
      prism.components.Position(),
      prism.components.Drawable { index = "T", color = prism.Color4.GREEN },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
