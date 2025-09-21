--- Component utility functions for easy component access
local ComponentUtils = {}

--- Helper function to safely get a component from an entity
--- @param entity Entity The entity to get the component from
--- @param componentPrototype Component The component prototype/class
--- @return Component? The component instance or nil if not found
function ComponentUtils.getComponent(entity, componentPrototype)
   if not entity or not componentPrototype then return nil end
   return entity:get(componentPrototype)
end

--- Helper function to check if an entity has a specific component
--- @param entity Entity The entity to check
--- @param componentPrototype Component The component prototype/class
--- @return boolean True if the entity has the component
function ComponentUtils.hasComponent(entity, componentPrototype)
   if not entity or not componentPrototype then return false end
   return entity:get(componentPrototype) ~= nil
end

--- Helper function to get a component or error if not found
--- @param entity Entity The entity to get the component from
--- @param componentPrototype Component The component prototype/class
--- @return Component The component instance (never nil)
function ComponentUtils.expectComponent(entity, componentPrototype)
   if not entity or not componentPrototype then error("Entity or component prototype cannot be nil") end
   return entity:expect(componentPrototype)
end

return ComponentUtils
