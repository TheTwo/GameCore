local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local StateMachine = require("StateMachine")
local DBEntityType = require("DBEntityType")

---@alias SETeamSubStateLogicIdleStatus {interactId:number, isInteract:boolean, startTime:number, endTime:number, uniqueName:string, config:MineConfigCell}

---@class SETeamSubStateLogicIdle
---@field new fun(seTeam:SETeam, seUnit:SEUnit):SETeamSubStateLogicIdle
local SETeamSubStateLogicIdle = class('SETeamSubStateLogicIdle')

---@param seTeam SETeam
---@param seUnit SEUnit
function SETeamSubStateLogicIdle:ctor(seTeam, seUnit)
    local entity = seUnit:GetEntity()
    self._team = seTeam
    self._seUnit = seUnit
    self._entityId = entity.ID
    local uniqueName = string.Empty
    local interactConfig = nil
    if entity.MapStates.InteractId ~= 0 then
        ---@type wds.SeInteractor
        local interactEntity = g_Game.DatabaseManager:GetEntity(entity.MapStates.InteractId, DBEntityType.SeInteractor)
        if interactEntity then
            uniqueName = seTeam:GetEnvironment():GetInteractorUniqueNameByEntity(interactEntity)
            interactConfig = ConfigRefer.Mine:Find(interactEntity.Interactor.ConfigID)
        end
    end

    ---@type SETeamSubStateLogicIdleStatus
    self._currentStatus = {
        interactId = entity.MapStates.InteractId,
        isInteract = entity.MapStates.IsInteract,
        startTime = entity.Interacter.StartTime,
        endTime = entity.Interacter.EndTime,
        uniqueName = uniqueName,
        config = interactConfig
    }
    self.stateMachine = StateMachine.new()
    self.stateMachine.allowReEnter = false
    self.stateMachine:AddState("SETeamSubStateRoute", require("SETeamSubStateRoute").new(seTeam, seUnit, self))
    self.stateMachine:AddState("SETeamSubStateIdle", require("SETeamSubStateIdle").new(seTeam, seUnit, self))
    self.stateMachine:AddState("SETeamSubStateMove", require("SETeamSubStateMove").new(seTeam, seUnit, self))
    self.stateMachine:AddState("SETeamSubStateCollect", require("SETeamSubStateCollect").new(seTeam, seUnit, self))
    end

function SETeamSubStateLogicIdle:OnCreate()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SePet.Interacter.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.Interacter.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SePet.MapStates.InteractId.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SePet.MapStates.IsInteract.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.MapStates.InteractId.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.MapStates.IsInteract.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    self.stateMachine:ChangeState("SETeamSubStateRoute")
end

function SETeamSubStateLogicIdle:OnDestroy()
    self.stateMachine:ChangeState("SETeamSubStateIdle")
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SePet.Interacter.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.Interacter.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SePet.MapStates.InteractId.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SePet.MapStates.IsInteract.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.MapStates.InteractId.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.MapStates.IsInteract.MsgPath, Delegate.GetOrCreate(self, self.OnEntityInteracterStatusChanged))
    self._entityId = nil
    self._seUnit = nil
    self._currentStatus = nil
end

---@param entity wds.Hero|wds.SePet
function SETeamSubStateLogicIdle:OnEntityInteracterStatusChanged(entity, changed)
    if self._entityId ~= entity.ID then return end
    local statusChange = false
    local dataMayDirty = false
    if self._currentStatus.interactId ~= entity.MapStates.InteractId then
        self._currentStatus.interactId = entity.MapStates.InteractId
        self._currentStatus.config = nil
        self._currentStatus.uniqueName = string.Empty
        ---@type wds.SeInteractor
        local interactEntity = g_Game.DatabaseManager:GetEntity(self._currentStatus.interactId, DBEntityType.SeInteractor)
        if interactEntity then
            self._currentStatus.uniqueName = self._team:GetEnvironment():GetInteractorUniqueNameByEntity(interactEntity)
            self._currentStatus.config = ConfigRefer.Mine:Find(interactEntity.Interactor.ConfigID)
        end
        statusChange = true
    end
    if self._currentStatus.isInteract ~= entity.MapStates.IsInteract then
        self._currentStatus.isInteract = entity.MapStates.IsInteract
        statusChange = true
    end
    if self._currentStatus.startTime ~= entity.Interacter.StartTime then
        self._currentStatus.startTime = entity.Interacter.StartTime
        dataMayDirty = true
    end
    if self._currentStatus.endTime ~= entity.Interacter.EndTime then
        self._currentStatus.endTime = entity.Interacter.EndTime
        dataMayDirty = true
    end
    if statusChange then
        self.stateMachine:ChangeState("SETeamSubStateRoute")
    elseif dataMayDirty then
        ---@type SETeamSubUnitState
        local state = self.stateMachine:GetCurrentState()
        if state and state.Refresh then
            state:Refresh()
        end
    end
end

function SETeamSubStateLogicIdle:Tick(dt, nowTime)
    if not self._seUnit:GetActor():IsValid() or not self._seUnit:GetActor():IsFbxObjectValid() then return end
    self.stateMachine:Tick(dt)
end

return SETeamSubStateLogicIdle