local CityCitizenDefine = require("CityCitizenDefine")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local CityCitizenStateSubGoToTarget = require("CityCitizenStateSubGoToTarget")
local CityCitizenStateSubRandomWait = require("CityCitizenStateSubRandomWait")
local CityCitizenStateSubRandomTarget = require("CityCitizenStateSubRandomTarget")
local CityCitizenStateSubEscape = require("CityCitizenStateSubEscape")

local StateMachine = require("StateMachine")
local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubNotWorking:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubNotWorking
---@field super CityCitizenState
local CityCitizenStateSubNotWorking = class('CityCitizenStateSubNotWorking', CityCitizenState)

---@param cityUnitCitizen CityUnitCitizen
function CityCitizenStateSubNotWorking:ctor(cityUnitCitizen)
    CityCitizenState.ctor(self, cityUnitCitizen)
    self:SetSubStateMachine(StateMachine.new())
    self._subStateMachine:AddState("CityCitizenStateSubRandomWait", CityCitizenStateSubRandomWait.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubRandomTarget", CityCitizenStateSubRandomTarget.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubGoToTarget", CityCitizenStateSubGoToTarget.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubEscape", CityCitizenStateSubEscape.new(cityUnitCitizen))
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self._nextTryTipTime = nil
end

function CityCitizenStateSubNotWorking:Enter()
    local v = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
    local runToHouse = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
    if v then
        self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork)
        self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsFromExitWork, true)
    end
    if runToHouse then
        self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse)
        self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetIsAssignHouse, true)
    end
    self._subStateMachine:ChangeState("CityCitizenStateSubRandomWait")
    if not self._nextTryTipTime then
        local tipTimeMin = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(1)
        local tipTimeMax = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(2)
        self._nextTryTipTime = math.random(tipTimeMin, tipTimeMax)
    end
    g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.CheckShowChapterTaskBubble))
    self:CheckShowChapterTaskBubble()
end

function CityCitizenStateSubNotWorking:Tick(dt)
    if self:HasWorkTask() then
        self.stateMachine:ChangeState("CityCitizenStateSubWorkingLoop")
        return
    end
    self._subStateMachine:Tick(dt)
    if self._subStateMachine:GetCurrentStateName() ~= "CityCitizenStateSubEscape" and self._citizen._data._mgr:CheckIsEnemyEffectRange(self._citizen) then
        self._subStateMachine:ChangeState("CityCitizenStateSubEscape")
    end
    if self._nextTryTipTime then
        if self._citizen:HasChapterTaskBubble() then
            return
        end
        self._nextTryTipTime = self._nextTryTipTime - dt
        if self._nextTryTipTime <= 0 then
            self._citizen:RequestBubbleTip()
            local tipTimeMin = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(1)
            local tipTimeMax = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(2)
            self._nextTryTipTime = math.random(tipTimeMin, tipTimeMax)
        end
    end
end

function CityCitizenStateSubNotWorking:Exit()
    g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.CheckShowChapterTaskBubble))
    self._subStateMachine:ChangeState("")
    self._citizen:ReleaseBubbleTip()
    self._citizen:ReleaseChapterTaskBubble()
end

function CityCitizenStateSubNotWorking:CheckShowChapterTaskBubble()
    self._citizen:ReleaseChapterTaskBubble()
    self._citizen:RequestChapterTaskBubble()
    if self._citizen:HasChapterTaskBubble() then
        self._citizen:ReleaseBubbleTip()
    end
end

function CityCitizenStateSubNotWorking:OnUnitAssetLoaded()
    local subState = self._subStateMachine:GetCurrentState()
    if subState and subState.OnUnitAssetLoaded then
        subState:OnUnitAssetLoaded()
    end
    self:CheckShowChapterTaskBubble()
end

return CityCitizenStateSubNotWorking

