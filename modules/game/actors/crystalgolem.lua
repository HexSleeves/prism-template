--- Crystal Golem - Heavily armored, magical creature found in deep levels
prism.registerActor("CrystalGolem", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Crystal Golem"),
      prism.components.Position(),
      prism.components.Drawable { index = "G", color = prism.Color4.CYAN },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 12, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
