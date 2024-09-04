local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local ConfigTimeUtility = require("ConfigTimeUtility")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local SESceneRoot = require("SESceneRoot")

---@class SEManualInteractorLogic
---@field new fun():SEManualInteractorLogic
local SEManualInteractorLogic = class('SEManualInteractorLogic')

function SEManualInteractorLogic:ctor()
    ---@type SEEnvironment
    self._seEnv = nil
    ---@type MineConfigCell
    self._config = nil
    ---@type SEInteractorHud
    self._hud = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._hudHandle = nil
    self._isInteracting = false
    ---@type CS.UnityEngine.Transform
    self._parent = nil
    ---@type CS.UnityEngine.Vector3
    self._birthPos = nil
    self._hpYOffset = 0
    self._hudVisible = false
    self._asBtn = false
    ---@type number
    self._startTime = nil
    ---@type number
    self._endTime = nil
    ---@type number
    self._operatorUnitId = nil
end

---@param env SEEnvironment
---@param entity wds.SeInteractor
function SEManualInteractorLogic:Setup(env, entity, birthPos, hpYOffset)
    self._id = entity.ID
    self._seEnv = env
    self._config = ConfigRefer.Mine:Find(entity.Interactor.ConfigID)
    self._parent = env:GetMapRoot()
    self._birthPos = birthPos
    self._hpYOffset = hpYOffset
end

function SEManualInteractorLogic:ShowHud(startTime, endTime, operatorUnitId, asBtn)
    self._hudVisible = true
    self._asBtn = asBtn
    self._startTime = startTime
    self._endTime = endTime
    self._operatorUnitId = operatorUnitId
    self:RefreshHud()
    if self._hudHandle then
        return
    end
    self._hudHandle = self._seEnv._pooledCreateHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_interactor), self._parent, Delegate.GetOrCreate(self, self.OnHudCreateCallBack))
end

function SEManualInteractorLogic:IsInteracting()
    return self._isInteracting
end

function SEManualInteractorLogic:HideHud()
    self._hudVisible = false
    self._isInteracting = false
    self._endTime = nil
    self._startTime = nil
    self._asBtn = false
    if self._hud then
        self._hud:SetVisible(false, false)
    end
end

---@param go CS.UnityEngine.GameObject
---@param userData any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function SEManualInteractorLogic:OnHudCreateCallBack(go, userData, handle)
    if Utils.IsNull(go) then
        return
    end
    local trans = go.transform
    trans.position = self._birthPos
    local localPos = trans.localPosition
    localPos.y = localPos.y + self._hpYOffset
    trans.localPosition = localPos
    local behaviour = go:GetLuaBehaviour("SEInteractorHud")
    if Utils.IsNull(behaviour) then
        return
    end
    self._hud = behaviour.Instance
    if not self._hud then return end
    self._hud:Reset()
    if self._seEnv:GetEnvMode() == SEEnvironmentModeType.CityScene then
        self._hud:SetupFacingCamera(self._seEnv:GetCamera(), (1 / SESceneRoot.GetClientScale()))
    else
        self._hud:SetupFacingCamera(self._seEnv:GetCamera(), 1)
    end
    self._hud:SetOnClick(Delegate.GetOrCreate(self, self.OnClickHudTrigger))
    self._hud:SetIcon(self._config:ShowIcon())
    self:RefreshHud()
end

function SEManualInteractorLogic:RefreshHud()
    if not self._hud then return end
    self._hud:SetVisible(self._hudVisible, self._asBtn)
    if self._startTime and self._endTime then
        self._hud:SetTickTime(self._startTime, self._endTime, false)
        self._hud:Tick(0, g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
    else
        self._hud:ClearTick()
    end
end

function SEManualInteractorLogic:OnClickHudTrigger()
    if not self._operatorUnitId or not self._config or not self._config:ManualInteract() then return true end
    if self._isInteracting then return true end
    self._isInteracting = true
    self._seEnv:SendTryInteractSe(self._operatorUnitId, self._id, Delegate.GetOrCreate(self, self.OnSendTryInteractSeResult))
    return true
end

function SEManualInteractorLogic:Tick(dt, nowTime)
    if not self._isInteracting then return end
    if self._hud then
        self._hud:Tick(dt, nowTime)
    end
end

function SEManualInteractorLogic:OnSendTryInteractSeResult(cmd, isSuccess, result)
    if not cmd or not cmd.msg or not cmd.msg.userdata or cmd.msg.userdata ~= self._id then return end
    if not isSuccess then return end
    if not self._isInteracting then return end
    self._startTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._endTime = self._startTime + ConfigTimeUtility.NsToSeconds(self._config:InteractTime())
    self:RefreshHud()
end

function SEManualInteractorLogic:Dispose()
    if self._hud then
        self._hud:Reset()
    end
    if self._hudHandle then
        self._hudHandle:Delete()
        self._hudHandle = nil
    end
    self._isInteracting = false
    self._hudVisible = false
    self._hud = nil
    self._config = nil
    self._seEnv = nil
    self._startTime = nil
    self._endTime = nil
    self._operatorUnitId = nil
    self._id = nil
end

return SEManualInteractorLogic