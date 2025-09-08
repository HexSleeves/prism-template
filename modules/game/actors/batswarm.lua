--- Bat Swarm - Flying group creature found in shallow to medium depths
prism.registerActor("BatSwarm", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Bat Swarm"),
      prism.components.Position(),
      prism.components.Drawable { index = "b", color = prism.Color4.GREY },
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 10, fov = true },
      prism.components.Mover { "fly" }, -- Can fly over obstacles
      prism.components.KoboldController(), -- Reuse existing AI controller for now
      -- CombatStats will be added by MonsterFactory with scaled values
   }
end)
