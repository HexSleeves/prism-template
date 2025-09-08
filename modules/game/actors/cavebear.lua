--- Cave Bear - Strong, territorial creature found in medium depths
prism.registerActor("CaveBear", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Cave Bear"),
      prism.components.Position(),
      prism.components.Drawable { index = "B", color = prism.Color4.BROWN },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
