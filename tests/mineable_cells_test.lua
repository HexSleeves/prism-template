-- Unit tests for mineable resource cells

-- Load prism engine for testing
prism = require("prism")
prism.loadModule("modules/game")

local MinableResource = require("modules.game.components.minableresource")

-- Test helper functions
local function createTestLevel()
   local level = prism.Level()
   level:setSize(10, 10)
   return level
end

local function createTestCell(cellType)
   return prism.cells[cellType]()
end

-- Test coal deposit cell
local function testCoalDepositCell()
   local cell = createTestCell("CoalDeposit")

   -- Check basic properties
   assert(cell:hasComponent("Name"), "Coal deposit should have Name component")
   assert(cell:hasComponent("Drawable"), "Coal deposit should have Drawable component")
   assert(cell:hasComponent("Collider"), "Coal deposit should have Collider component")
   assert(cell:hasComponent("Opaque"), "Coal deposit should have Opaque component")
   assert(cell:hasComponent("GameMinableResource"), "Coal deposit should have MinableResource component")

   -- Check resource properties
   local resource = cell:getComponent("GameMinableResource")
   assert(resource.resourceType == "coal", "Coal deposit should have coal resource type")
   assert(resource.hardness == 1, "Coal should have hardness 1")
   assert(resource.quantity > 0, "Coal deposit should have positive quantity")
   assert(resource.depthRequired == 1, "Coal should require depth 1")

   print("✓ Coal deposit cell test passed")
end

-- Test copper ore cell
local function testCopperOreCell()
   local cell = createTestCell("CopperOre")

   -- Check basic properties
   assert(cell:hasComponent("Name"), "Copper ore should have Name component")
   assert(cell:hasComponent("Drawable"), "Copper ore should have Drawable component")
   assert(cell:hasComponent("Collider"), "Copper ore should have Collider component")
   assert(cell:hasComponent("Opaque"), "Copper ore should have Opaque component")
   assert(cell:hasComponent("GameMinableResource"), "Copper ore should have MinableResource component")

   -- Check resource properties
   local resource = cell:getComponent("GameMinableResource")
   assert(resource.resourceType == "copper", "Copper ore should have copper resource type")
   assert(resource.hardness == 2, "Copper should have hardness 2")
   assert(resource.quantity > 0, "Copper ore should have positive quantity")
   assert(resource.depthRequired == 2, "Copper should require depth 2")

   print("✓ Copper ore cell test passed")
end

-- Test gold vein cell
local function testGoldVeinCell()
   local cell = createTestCell("GoldVein")

   -- Check basic properties
   assert(cell:hasComponent("Name"), "Gold vein should have Name component")
   assert(cell:hasComponent("Drawable"), "Gold vein should have Drawable component")
   assert(cell:hasComponent("Collider"), "Gold vein should have Collider component")
   assert(cell:hasComponent("Opaque"), "Gold vein should have Opaque component")
   assert(cell:hasComponent("GameMinableResource"), "Gold vein should have MinableResource component")

   -- Check resource properties
   local resource = cell:getComponent("GameMinableResource")
   assert(resource.resourceType == "gold", "Gold vein should have gold resource type")
   assert(resource.hardness == 4, "Gold should have hardness 4")
   assert(resource.quantity > 0, "Gold vein should have positive quantity")
   assert(resource.depthRequired == 5, "Gold should require depth 5")

   print("✓ Gold vein cell test passed")
end

-- Test gem deposit cell
local function testGemDepositCell()
   local cell = createTestCell("GemDeposit")

   -- Check basic properties
   assert(cell:hasComponent("Name"), "Gem deposit should have Name component")
   assert(cell:hasComponent("Drawable"), "Gem deposit should have Drawable component")
   assert(cell:hasComponent("Collider"), "Gem deposit should have Collider component")
   assert(cell:hasComponent("Opaque"), "Gem deposit should have Opaque component")
   assert(cell:hasComponent("GameMinableResource"), "Gem deposit should have MinableResource component")

   -- Check resource properties
   local resource = cell:getComponent("GameMinableResource")
   assert(resource.resourceType == "gems", "Gem deposit should have gems resource type")
   assert(resource.hardness == 5, "Gems should have hardness 5")
   assert(resource.quantity > 0, "Gem deposit should have positive quantity")
   assert(resource.depthRequired == 7, "Gems should require depth 7")

   print("✓ Gem deposit cell test passed")
end

-- Test bedrock cell
local function testBedrockCell()
   local cell = createTestCell("Bedrock")

   -- Check basic properties
   assert(cell:hasComponent("Name"), "Bedrock should have Name component")
   assert(cell:hasComponent("Drawable"), "Bedrock should have Drawable component")
   assert(cell:hasComponent("Collider"), "Bedrock should have Collider component")
   assert(cell:hasComponent("Opaque"), "Bedrock should have Opaque component")

   -- Check that bedrock is NOT mineable
   assert(not cell:hasComponent("GameMinableResource"), "Bedrock should NOT have MinableResource component")

   print("✓ Bedrock cell test passed")
end

-- Test mining interaction simulation
local function testMiningInteraction()
   local level = createTestLevel()
   local coalCell = createTestCell("CoalDeposit")

   -- Place cell in level
   level:setCell(5, 5, coalCell)

   -- Get the resource component
   local resource = coalCell:getComponent("GameMinableResource")
   local initialQuantity = resource.quantity

   -- Simulate mining (extract 1 unit)
   local extracted = resource:extract(1)

   assert(extracted == 1, "Should extract 1 unit of coal")
   assert(resource.quantity == initialQuantity - 1, "Resource quantity should decrease by 1")

   -- Test complete depletion
   resource:extract(resource.quantity)
   assert(resource:isDepleted(), "Resource should be depleted after extracting all")

   print("✓ Mining interaction test passed")
end

-- Test depth requirements
local function testDepthRequirements()
   local coalResource = MinableResource("coal")
   local goldResource = MinableResource("gold")

   -- Test coal at various depths
   assert(coalResource:canSpawnAtDepth(1), "Coal should spawn at depth 1")
   assert(coalResource:canSpawnAtDepth(5), "Coal should spawn at depth 5")

   -- Test gold at various depths
   assert(not goldResource:canSpawnAtDepth(1), "Gold should NOT spawn at depth 1")
   assert(not goldResource:canSpawnAtDepth(4), "Gold should NOT spawn at depth 4")
   assert(goldResource:canSpawnAtDepth(5), "Gold should spawn at depth 5")
   assert(goldResource:canSpawnAtDepth(10), "Gold should spawn at depth 10")

   print("✓ Depth requirements test passed")
end

-- Run all tests
local function runAllTests()
   print("Running mineable cells tests...")

   testCoalDepositCell()
   testCopperOreCell()
   testGoldVeinCell()
   testGemDepositCell()
   testBedrockCell()
   testMiningInteraction()
   testDepthRequirements()

   print("All mineable cells tests passed! ✓")
end

-- Export test runner
return {
   runAllTests = runAllTests,
   testCoalDepositCell = testCoalDepositCell,
   testCopperOreCell = testCopperOreCell,
   testGoldVeinCell = testGoldVeinCell,
   testGemDepositCell = testGemDepositCell,
   testBedrockCell = testBedrockCell,
   testMiningInteraction = testMiningInteraction,
   testDepthRequirements = testDepthRequirements,
}
