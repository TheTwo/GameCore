local CityCitizenDefine = require("CityCitizenDefine")
local StateMachine = require("StateMachine")
local CityCitizenStateSubGoToTarget = require("CityCitizenStateSubGoToTarget")
local CityCitizenStateSubRandomWait = require("CityCitizenStateSubRandomWait")
local ConfigRefer = require("ConfigRefer")
local SlgUtils = require("SlgUtils")
local ModuleRefer = require("ModuleRefer")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubEscape:CityCitizenState
---@field new fun(cityUnitCitizen):CityCitizenStateSubEscape
---@field super CityCitizenState
local CityCitizenStateSubEscape = class('CityCitizenStateSubEscape', CityCitizenState)

function CityCitizenStateSubEscape:ctor(cityUnitCitizen)
    CityCitizenState.ctor(self, cityUnitCitizen)
    self:SetSubStateMachine(StateMachine.new())
    self._subStateMachine:AddState("CityCitizenStateSubGoToTarget", CityCitizenStateSubGoToTarget.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubRandomWait", CityCitizenStateSubRandomWait.new(cityUnitCitizen))
end

function CityCitizenStateSubEscape:Enter()
    ---@type CS.UnityEngine.Vector3
    self._targetPos = nil
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    local lastTime = self.stateMachine:ReadBlackboard("CityCitizenStateSubEscapeLastTime", false)
    ---加一个3 秒 冷却 避免特殊情况无限逃跑鬼畜
    if lastTime and (g_Game.ServerTime:GetServerTimestampInSeconds() - lastTime < 3) then
        self.stateMachine:ChangeState("CityCitizenStateSubRandomWait")
    end
end

function CityCitizenStateSubEscape:Tick(dt)
    if not self._targetPos then
        self:FindSafeTarget()
        return
    end
    self._subStateMachine:Tick(dt)
    if not self._citizen._hasTargetPos then
        self.stateMachine:ChangeState("CityCitizenStateSubRandomWait")
    end
end

function CityCitizenStateSubEscape:Exit()
    self._citizen:ReleaseEscapeBubble()
    self._subStateMachine:ChangeState("")
    self._targetPos = nil
end

function CityCitizenStateSubEscape:FindSafeTarget()
    local city = self._citizen._data._mgr.city
    local pos = self._citizen._moveAgent._currentPosition
    if not pos then
        return
    end
    local x,y = city:GetCoordFromPosition(pos, true)
    local currentSafeAreaId = city.safeAreaWallMgr:GetSafeAreaId(math.floor(x),  math.floor(y))
    ---@type CS.UnityEngine.Vector2|nil
    local chooseTargetPos
    local targetSafeAreaCount = ConfigRefer.CityConfig:CitizenEscapeChooseSafeZoneLength()
    if targetSafeAreaCount > 0 then
        local validZones = {}
        for i = 1, targetSafeAreaCount do
            local id = ConfigRefer.CityConfig:CitizenEscapeChooseSafeZone(i)
            if ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(id) and (not currentSafeAreaId or currentSafeAreaId ~= id) then
                table.insert(validZones, id)
            end
        end
        targetSafeAreaCount = #validZones
        if targetSafeAreaCount > 0 then
            local zoneId = validZones[math.random(1, targetSafeAreaCount)]
            local has,rdGrid = city.safeAreaWallController:RandomInSafeAreaGrid(zoneId, city:GetSafeAreaSliceDataUsage())
            if not has then
                chooseTargetPos = nil
            else
                chooseTargetPos = CS.UnityEngine.Vector2(rdGrid.x, rdGrid.y)
            end
        end
    end
    if not chooseTargetPos then
        if currentSafeAreaId then
            local has,rdGrid = city.safeAreaWallController:RandomInSafeAreaGrid(currentSafeAreaId, city:GetSafeAreaSliceDataUsage())
            if has then
                chooseTargetPos = CS.UnityEngine.Vector2(rdGrid.x, rdGrid.y)
            end
        end
        if not chooseTargetPos then
            chooseTargetPos = city.safeAreaWallMgr:FindNearestSafeAreaCenter(x, y, true)
        end
    end
    if not chooseTargetPos then
        self._subStateMachine:ChangeState("CityCitizenStateSubRandomWait")
        return
    end
    self._citizen:RequestEscapeBubble()
    self._targetPos = city:GetWorldPositionFromCoord(chooseTargetPos.x, chooseTargetPos.y)
    self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetPos, self._targetPos)
    self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedForceRun, true, true)
    self._subStateMachine:ChangeState("CityCitizenStateSubGoToTarget")
    self.stateMachine:WriteBlackboard("CityCitizenStateSubEscapeLastTime", g_Game.ServerTime:GetServerTimestampInSeconds(), true)
end

return CityCitizenStateSubEscape