--- Shadow Wraith - Incorporeal, darkness-dwelling creature found in deep levels
prism.registerActor("ShadowWraith", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shadow Wraith"),
      prism.components.Position(),
      prism.components.Drawable { index = "W", color = prism.Color4.BLACK },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 15, fov = true },
      prism.components.Mover { "fly" }, -- Incorporeal, can move through obstacles
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
