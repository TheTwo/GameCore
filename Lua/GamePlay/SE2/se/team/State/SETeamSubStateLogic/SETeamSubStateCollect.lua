local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")

local SETeamSubUnitState = require("SETeamSubUnitState")

---@class SETeamSubStateCollect:SETeamSubUnitState
---@field new fun():SETeamSubStateCollect
---@field super SETeamSubUnitState
local SETeamSubStateCollect = class('SETeamSubStateCollect', SETeamSubUnitState)

function SETeamSubStateCollect:Enter()
    local env = self._team:GetEnvironment()
    local status = self.logic._currentStatus
    ---@type wds.SeInteractor
    local entity = g_Game.DatabaseManager:GetEntity(status.interactId, DBEntityType.SeInteractor)
    local brithPos = env:ServerPos2Client(CS.UnityEngine.Vector3(entity.MapBasics.Position.X, entity.MapBasics.Position.Y, entity.MapBasics.Position.Z))
    local interactModelConf = ConfigRefer.ArtResource:Find(status.config:InteractModel())
    local hpYOffset = interactModelConf:HpYOffset()
    local dir = (brithPos - self.seUnit:GetActor():GetPosition())
    dir.y = 0
    dir = dir.normalized
    if dir.sqrMagnitude > 0.001 then
        self.seUnit:GetActor():SetForward(dir, 0.1)
    end
    self.hudLogic = env:CreateManualInteractorLogic(entity, brithPos, hpYOffset)
    self.hudLogic:ShowHud(status.startTime * 0.001, status.endTime * 0.001, nil, false)
    self.hudLogic._isInteracting = true
    self._seqId = nil
    self.performData = nil
    local interAni = status.config:TimelineConf()
    if string.IsNullOrEmpty(interAni) then
        return
    end
    local p, seqId = self.seUnit:GetStateMachine():GetPriority(0)
    self._seqId = (seqId or 0) + 1
    ---@type skillclient.data.Animation
    local performData = {}
    performData.AnimName = interAni
    performData.Priority = p
    performData.FadeTime = 0.01
    performData.Layer = 0
    performData.TimeBegin = 0
    performData.Time = (status.endTime - status.startTime) * 0.001
    self.performData = performData
    self.seUnit:GetStateMachine():OnPerform(self.performData, self._seqId)
end

function SETeamSubStateCollect:Tick(dt)
    self.hudLogic:Tick(dt)
end

function SETeamSubStateCollect:Refresh()
    if self.hudLogic then
        local status = self.logic._currentStatus
        self.hudLogic:ShowHud(status.startTime * 0.001, status.endTime * 0.001, nil, false)
        self.hudLogic:Tick(0)
    end
end

function SETeamSubStateCollect:Exit()
    if self.performData and self._seqId then
        self.seUnit:GetStateMachine():OnPerformEnd(self.performData, self._seqId, true)
        self.seUnit:GetStateMachine():OnIdle(true)
    end
    self.hudLogic:HideHud()
    self.hudLogic:Dispose()
    self.hudLogic = nil
end

return SETeamSubStateCollect