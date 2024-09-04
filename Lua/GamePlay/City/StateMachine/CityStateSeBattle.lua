local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local Delegate = require("Delegate")
local LeaveBattleInHomeSeParameter = require("LeaveBattleInHomeSeParameter")
local CityConst = require("CityConst")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityZoneStatus = require("CityZoneStatus")
local CityStateHelper = require("CityStateHelper")

local CityState = require("CityState")

---@class CityStateSeBattle:CityState
---@field new fun(city:City):CityStateSeBattle
---@field super CityState
local CityStateSeBattle = class("CityStateSeBattle", CityState)

local ControlHudPart = (HUDMediatorPartDefine.everyThing & ~HUDMediatorPartDefine.bossInfo)

function CityStateSeBattle:Enter()
    CityStateSeBattle.super.Enter(self)
    self._willExit = false
    self._currentUsingCameraSize = nil
    self._currentCameraV = CS.UnityEngine.Vector3.zero
    self._seBattleHudReady = false
    self._hideExitBtn = false
    self._zoomCameraStartSize = nil
    self._zoomCameraSizeTime = nil
    self._zoomCameraSizeTimeTotal = ConfigRefer.CityConfig:CityCameraZoomSeBattleFocusDuration()
    local hudeHidePart = self.stateMachine:ReadBlackboard("hudHidePart")
    ---@type number
    self.presetIndex = self.stateMachine:ReadBlackboard("presetIndex")
    ---@type number
    self.x = self.stateMachine:ReadBlackboard("x")
    ---@type number
    self.y = self.stateMachine:ReadBlackboard("y")
    ---@type CityElementSpawner
    self.spawner = self.stateMachine:ReadBlackboard("spawner")
    if not self.x or not self.y then
        if self.spawner then
            self.x, self.y = self.spawner.x, self.spawner.y
        else
            self.x, self.y = self:ReadCurrentCameraCoord()
        end
    end
    self._hideExitBtn = self.stateMachine:ReadBlackboard("hideExitBtn") or false
    self.stateMachine:ReadBlackboard("fromExplore", true)
    self.city.camera.enablePinch = false
    self.city.camera.enableDragging = false
    self.SEEnvironment = self.city.citySeManger._seEnvironment
    self.SEEnvironment:SetCurrentFocusPresetIndex(self.presetIndex)
    self.SEEnvironment:SetCurrentFocusSpawnerId(self.spawner and self.spawner.id)
    self:HideCityHud(hudeHidePart)
    self:FocusOnBattleArea()
    self:OpenBattleUI()
    g_Game.EventManager:AddListener(EventConst.SE_REQUEST_CITY_LEAVE_BATTLE, Delegate.GetOrCreate(self, self.OnCitySeBattleRequestLeave))
    g_Game.EventManager:TriggerEvent(EventConst.SE_REQUEST_CITY_ENTER_BATTLE)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnCurrentBattleEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    self.city.cityExplorerManager:SetTeamSelected(nil)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.InternalLateTick))
    self.city.cityExplorerManager:SetAllowShowLine(false)
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(false)
    g_Game.EventManager:AddListener(EventConst.HUD_MEDIATOR_RESTARTEND_SHOW, Delegate.GetOrCreate(self, self.HideCityHud))
end

function CityStateSeBattle:Exit()
    self._seBattleHudReady = false
    self.SEEnvironment:ProcessBattleEnd()
    g_Game.EventManager:RemoveListener(EventConst.SE_REQUEST_CITY_LEAVE_BATTLE, Delegate.GetOrCreate(self, self.OnCitySeBattleRequestLeave))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnCurrentBattleEnd))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.InternalLateTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_MEDIATOR_RESTARTEND_SHOW, Delegate.GetOrCreate(self, self.HideCityHud))
    self:CloseBattleUI()
    local exitToNormal = false
    local willTransTo = self.stateMachine.willTransToStateName
    if (willTransTo ~= CityConst.STATE_CITY_SE_EXPLORER_FOCUS 
        and willTransTo ~= CityConst.STATE_CITY_ZONE_RECOVER_EFFECT
        and willTransTo ~= CityConst.STATE_CITY_SE_BATTLE_FOCUS
    )
    then
        exitToNormal = true
    end
    self:RestoreCameraFocus(exitToNormal)
    self.SEEnvironment:SetCurrentFocusPresetIndex(nil)
    self.SEEnvironment:SetCurrentFocusSpawnerId(nil)
    self.SEEnvironment = nil
    if self.city.camera then
        self.city.camera.enablePinch = true
        self.city.camera.enableDragging = true
    end
    CityStateSeBattle.super.Exit(self)
    
    if exitToNormal then
        self:RestoreCityHud()
    end
    self.city.cityExplorerManager:SetAllowShowLine(true)
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(true)
end

function CityStateSeBattle:ReEnter()
    self:Exit()
    self:Enter()
end

---@return number, number
function CityStateSeBattle:ReadCurrentCameraCoord()
    local pos = self.city.camera:GetLookAtPosition()
    return self.city:GetCoordFromPosition(pos, true)
end

function CityStateSeBattle:OpenBattleUI()
    g_Game.EventManager:AddListener(EventConst.SE_HUD_OPENED, Delegate.GetOrCreate(self, self.OnSEBattleHudReady))
    ---@type SEHudMediatorParameter
    local param = {}
    param.tid = self.SEEnvironment._instanceId
    param.hideExitBtn = self._hideExitBtn
    self.runtimeId = g_Game.UIManager:Open(UIMediatorNames.SEHudMediator, param)
end

function CityStateSeBattle:CloseBattleUI()
    if not self.runtimeId then return end
    g_Game.EventManager:RemoveListener(EventConst.SE_HUD_OPENED, Delegate.GetOrCreate(self, self.OnSEBattleHudReady))
    g_Game.UIManager:Close(self.runtimeId)
end

function CityStateSeBattle:OnSEBattleHudReady()
    self._seBattleHudReady = true
    self.SEEnvironment:ProcessBattleStart()
    self.SEEnvironment:GetSkillManager():OnPlayerCardChange()
    self.SEEnvironment:SetAllowClickMove(false)
end

function CityStateSeBattle:HideCityHud(hideHudFromLastState)
    if hideHudFromLastState then
        self._lastChangedHud = hideHudFromLastState
        return
    end
    self._lastChangedHud = nil
    ---@type HUDMediator
    local hud = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if hud then
        self._lastChangedHud = hud:ShowHidePartChanged(ControlHudPart, false)
    else
        g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, false)
    end
end

function CityStateSeBattle:RestoreCityHud()
    local changed = self._lastChangedHud
    self._lastChangedHud = nil
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, true, changed)
end

function CityStateSeBattle:FocusOnBattleArea()
    self._willExit = false
    self._currentUsingCameraSize = nil
    self.city.mediator:SetEnableGesture(false)
    self.city.seMediator:SetEnableGesture(true)
    local city = self.city
    local camera = city:GetCamera()
    camera:ForceGiveUpTween()
    -- local center = city:GetCenterWorldPositionFromCoord(self.x, self.y, 1, 1)
    local cameraSize = CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE
    if self.spawner then
        local config = ConfigRefer.CityElementData:Find(self.spawner.configId)
        local spawnerConfig = ConfigRefer.CityElementSpawner:Find(config:ElementId())
        if spawnerConfig.BattleCameraSize then
            local size = spawnerConfig:BattleCameraSize()
            if size > 0 then
                cameraSize = size
            end
        end
    end
    self._currentUsingCameraSize = cameraSize
    self:RefreshCameraSizeLimit()
    self._zoomCameraStartSize = camera:GetSize()
    self._zoomCameraSizeTime = self._zoomCameraSizeTimeTotal
    -- camera:ZoomToWithFocus(cameraSize, CS.UnityEngine.Vector3(0.5, 0.4), center, 0.2)
    -- camera:ZoomTo(cameraSize, ConfigRefer.CityConfig:CityCameraZoomSeBattleFocusDuration())
end

function CityStateSeBattle:RestoreCameraFocus(exitToNormal)
    local camera = self.city:GetCamera()
    if camera then
        camera:ForceGiveUpTween()
    end
    self.city.mediator:SetEnableGesture(true)
    self.city.seMediator:SetEnableGesture(false)
    self._willExit = true
    if exitToNormal then
        self:RefreshCameraSizeLimit()
    end
    self._willExit = false
end

---@param btnClickTrans CS.UnityEngine.RectTransform
function CityStateSeBattle:OnCitySeBattleRequestLeave(btnClickTrans)
    local sendCmd = LeaveBattleInHomeSeParameter.new()
    local presetIndex = self.SEEnvironment:GetCurrentFocusPresetIndex()
    sendCmd.args.PresetIndex = presetIndex
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    if team then
        self.city.cityExplorerManager:SendDismissTeam(team)
    end
    sendCmd:SendOnceCallback(btnClickTrans, nil, nil, Delegate.GetOrCreate(self, self.OnLeaveCallback))
end

function CityStateSeBattle:OnLeaveCallback(cmd, isSuccess, rsp)
    if not isSuccess then return end
    if self.stateMachine:GetCurrentState() ~= self then return end
    self:ExitToIdleState()
end

---@param entity wds.ScenePlayer
function CityStateSeBattle:OnCurrentBattleEnd(entity, _)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    local scenePreset = entity.ScenePlayerPreset
    if scenePreset then
        for _, value in pairs(scenePreset.PresetList) do
            if value.PresetIndex == self.presetIndex then
                if value.InBattle and value.Focus then
                    return
                elseif not value.InBattle and value.InExplore then
                    CityStateHelper.ExitToFocusSeExplorer(self, entity.ID, self.presetIndex, self._lastChangedHud, false)
                    self._lastChangedHud = nil
                    return
                end
                break
            end
        end
    end
    self:ExitToIdleState()
end

function CityStateSeBattle:InternalLateTick(dt)
    if ModuleRefer.HeroRescueModule:GetManualShowItemBubble() then
        return
    end
    if self._zoomCameraSizeTime then
        self._zoomCameraSizeTime = self._zoomCameraSizeTime - dt
        local p = math.inverseLerp(self._zoomCameraSizeTimeTotal, 0, self._zoomCameraSizeTime)
        p = CS.UnityEngine.Mathf.SmoothStep(self._zoomCameraStartSize, self._currentUsingCameraSize, p)
        self.city:GetCamera():SetSize(p)
        if self._zoomCameraSizeTime <= 0 then
            self._zoomCameraSizeTime = nil
        end
    end
    local unit = self.city.citySeManger:GetCurrentCameraFocusOnHero(self.presetIndex)
    if not unit then return end
    local pos  = unit:GetActor():GetPosition()
    if not pos then return end
    local coordXNoFloor,coordYNoFloor = self.city:GetCoordFromPosition(pos, true)
    if not coordXNoFloor or not coordYNoFloor then return false end
    local targetPos = self.city:GetWorldPositionFromCoord(coordXNoFloor, coordYNoFloor)
    local currentCameraPos = self.city:GetCamera():GetLookAtPlanePosition()
    if not currentCameraPos then return end
    local cameraPos, v = CS.UnityEngine.Vector3.SmoothDamp(currentCameraPos, targetPos, self._currentCameraV, dt, 10)
    self._currentCameraV = v
    self.city:GetCamera():LookAt(cameraPos)
end

function CityStateSeBattle:GetCameraMaxSize()
    if self._willExit then return nil,nil end
    return 0, 20
end

---@param city City
function CityStateSeBattle:OnStatusChanged(city, zoneId, elementIds)
    if not city:IsMyCity() then return end
    if zoneId == 1 then
        self.stateMachine:ReadBlackboard("needDismissTeam")
    else
        self.stateMachine:WriteBlackboard("needDismissTeam", self.presetIndex)
    end
    self.stateMachine:WriteBlackboard("zoneId", zoneId, true)
    self.stateMachine:WriteBlackboard("elementIds", elementIds, true)
    self.stateMachine:WriteBlackboard("duration", CityConst.ZoneRecoverTime, true)
    self.stateMachine:WriteBlackboard("delay", CityConst.ZoneRecoverUnPollutedTimeDelay, true)
    self.stateMachine:WriteBlackboard("hudHidePart", self._lastChangedHud, true)
    self.stateMachine:WriteBlackboard("fromExplore", true)
    self._lastChangedHud = nil
    self.stateMachine:ChangeState(CityConst.STATE_CITY_ZONE_RECOVER_EFFECT)
end

function CityStateSeBattle:OnLightRestartEnd()
    self:HideCityHud()
end

function CityStateSeBattle:RefreshCameraSizeLimit()
    ---@type KingdomScene
    local kingdomScene = g_Game.SceneManager.current
    if kingdomScene then
        ---@type KingdomSceneStateInCity
        local state = kingdomScene.stateMachine:GetCurrentState()
        if state and state.SetCameraSize then
            state:SetCameraSize()
        end
    end
end

return CityStateSeBattle