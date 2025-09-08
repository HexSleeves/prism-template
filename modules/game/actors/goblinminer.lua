--- Goblin Miner - Tool-using, intelligent creature found in medium depths
prism.registerActor("GoblinMiner", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Goblin Miner"),
      prism.components.Position(),
      prism.components.Drawable { index = "g", color = prism.Color4.YELLOW },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 12, fov = true },
      prism.components.Mover { "walk" },
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
