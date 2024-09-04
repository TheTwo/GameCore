local Delegate = require("Delegate")
local SETeamSubStateLogicIdle = require("SETeamSubStateLogicIdle")

local SETeamState = require("SETeamState")
---@class SETeamStateIdle:SETeamState
---@field new fun():SETeamStateIdle
local SETeamStateIdle = class("SETeamStateIdle", SETeamState)

function SETeamStateIdle:Enter()
    self._team:AddOnHeroAddOrRemoveListener(Delegate.GetOrCreate(self, self.OnTeamMemberChanged))
    self._team:AddOnPetAddOrRemoveListener(Delegate.GetOrCreate(self, self.OnTeamMemberChanged))
    ---@type table<number, SETeamSubStateLogicIdle>
    self._currentMemberMap = {}
    for _, seHero in self._team:PairsOfHeroMembers() do
        local logic = SETeamSubStateLogicIdle.new(self._team, seHero)
        self._currentMemberMap[seHero:GetID()] = logic
        logic:OnCreate()
    end
    for _, setPet in self._team:PairsOfPetMembers() do
        local logic = SETeamSubStateLogicIdle.new(self._team, setPet)
        self._currentMemberMap[setPet:GetID()] = logic
        logic:OnCreate()
    end
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function SETeamStateIdle:Exit()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self._team:RemoveOnHeroAddOrRemoveListener(Delegate.GetOrCreate(self, self.OnTeamMemberChanged))
    self._team:RemoveOnPetAddOrRemoveListener(Delegate.GetOrCreate(self, self.OnTeamMemberChanged))
    for _, v in pairs(self._currentMemberMap) do
        v:OnDestroy()
    end
    table.clear(self._currentMemberMap)
end

---@param addUnit SEHero|SEPet|nil
---@param removeUnit SEHero|SEPet|nil
function SETeamStateIdle:OnTeamMemberChanged(addUnit, removeUnit)
    if addUnit then 
        local logic = self._currentMemberMap[addUnit:GetID()]
        if not logic then
            logic = SETeamSubStateLogicIdle.new(self._team, addUnit)
            self._currentMemberMap[addUnit:GetID()] = logic
            logic:OnCreate()
        end
    end
    if removeUnit then
        local logic = self._currentMemberMap[removeUnit:GetID()]
        self._currentMemberMap[removeUnit:GetID()] = nil
        if logic then
            logic:OnDestroy()
        end
    end
end

function SETeamStateIdle:Tick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, v in pairs(self._currentMemberMap) do
        v:Tick(dt, nowTime)
    end
end

return SETeamStateIdle