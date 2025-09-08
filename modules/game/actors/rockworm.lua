--- Rock Worm - Burrowing, ambush predator found in medium depths
prism.registerActor("RockWorm", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rock Worm"),
      prism.components.Position(),
      prism.components.Drawable { index = "w", color = prism.Color4.GREY },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 6, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
