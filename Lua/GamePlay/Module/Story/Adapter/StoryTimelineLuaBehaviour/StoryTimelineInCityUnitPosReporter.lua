local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@class StoryTimelineInCityUnitPosReporter
---@field behaviour CS.DragonReborn.LuaBehaviour
local StoryTimelineInCityUnitPosReporter = sealedClass('StoryTimelineInCityUnitPosReporter')

function StoryTimelineInCityUnitPosReporter:OnEnable()
    self._city = ModuleRefer.CityModule.myCity
    self._trans = self.behaviour.transform
    local provider = self._city.unitMoveGridEventProvider
    local goPos = self._trans.position
    local cityPosX,cityPosY = self._city:GetCoordFromPosition(goPos)
    self._posHandle = provider:AddUnit(cityPosX, cityPosY, provider.UnitType.TimelineSelfUnit)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.LuaLogicTick))
end

function StoryTimelineInCityUnitPosReporter:OnDisable()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.LuaLogicTick))
    self._posHandle:dispose()
end

function StoryTimelineInCityUnitPosReporter:LuaLogicTick(dt)
    local goPos = self._trans.position
    local cityPosX,cityPosY = self._city:GetCoordFromPosition(goPos)
    self._posHandle:refreshPos(cityPosX, cityPosY)
end

return StoryTimelineInCityUnitPosReporter