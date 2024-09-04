local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")
local CityConst = require("CityConst")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CityStateHelper = require("CityStateHelper")
local CityGridLayerMask = require("CityGridLayerMask")
local I18N = require("I18N")
local CitySeExplorerPetsLogicDefine = require("CitySeExplorerPetsLogicDefine")
local CityZoneStatus = require("CityZoneStatus")
local GuideConst = require("GuideConst")
local ConfigTimeUtility = require("ConfigTimeUtility")
local LOOK_AT_MODE = {
    LOOK_AT_HERO_UNIT = 1,
    LOOK_AT_TEAM_CENTER = 2,
}

local CityState = require("CityState")

local ControlHudPart = (HUDMediatorPartDefine.everyThing & ~HUDMediatorPartDefine.bossInfo)

---@class CityStateSeExplorerFocus:CityState
---@field new fun(city:City):CityStateSeExplorerFocus
---@field super CityState
local CityStateSeExplorerFocus = class("CityStateSeExplorerFocus", CityState)

---@param city City
function CityStateSeExplorerFocus:ctor(city)
    CityStateSeExplorerFocus.super.ctor(self, city)
    self._scenePlayerId = nil
    self._presetIndex = nil
    self._currentCameraV = CS.UnityEngine.Vector3.zero
    self._lastTickDt = nil
    self._willExit = false
    self._inEnterCameraTween = false
    self._seBattleHUDRuntimeId = nil
    self._hudRuntimeId = nil
    ---@type {x:number,y:number}|nil
    self._extiToIdleFocusOnGridV2 = nil
    self._isExiting = false
    self._sendExitFocusFlag = false
    self._waitTeamReadyThenTriggerGuide = false
    self._waitTickGetZoneId = false
    self._zoomCameraStartSize = nil
    self._zoomCameraSizeTime = nil
    self._zoomCameraSizeTimeTotal = nil
    self._currentUsingCameraSize = nil
    self._zoomCameraV = 0
    self._lookAtMode = LOOK_AT_MODE.LOOK_AT_TEAM_CENTER
    self.PostProcessStateChange = nil
end

function CityStateSeExplorerFocus:Enter()
    self._waitTickGetZoneId = true
    self._waitTeamReadyThenTriggerGuide = false
    self._sendExitFocusFlag = false
    self._isExiting = false
    self._scenePlayerId = self.stateMachine:ReadBlackboard("ScenePlayerId")
    self._presetIndex = self.stateMachine:ReadBlackboard("PresetIndex")
    local needEnterCameraZoom = self.stateMachine:ReadBlackboard("needEnterCameraZoom")
    local hudHidePart = self.stateMachine:ReadBlackboard("hudHidePart")
    self.stateMachine:ReadBlackboard("fromExplore", true)
    self._inEnterCameraTween = false
    self._zoomCameraV = 0
    if self:InternalLateTick(0) then
        self._waitTickGetZoneId = false
        g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
        local entity = g_Game.DatabaseManager:GetEntity(self._scenePlayerId, DBEntityType.ScenePlayer)
        self:OnScenePlayerPresetChanged(entity)
        return
    end
    self._zoomCameraStartSize = nil
    self._zoomCameraSizeTime = nil
    self._zoomCameraSizeTimeTotal = ConfigRefer.CityConfig:CityCameraZoomSeExplorerFocusDuration()
    self._waitTeamReadyThenTriggerGuide = true
    self:TakeOverCamera(needEnterCameraZoom)
    self:HideCityHud(hudHidePart)
    local seEnv = self.city.citySeManger._seEnvironment
    seEnv:SetCurrentFocusPresetIndex(self._presetIndex)
    self:OpenBattleUI()
    self:ShowExplorerHud()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.InternalLateTick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_MEDIATOR_RESTARTEND_SHOW, Delegate.GetOrCreate(self, self.HideCityHud))
    self.city.cityExplorerManager:SetTeamSelected(nil)
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(false)
    self.city.cityExplorerManager:SetAllowShowLine(false)
    self.PostProcessStateChange = nil
end

function CityStateSeExplorerFocus:Exit()
    self._waitTickGetZoneId = false
    self._waitTeamReadyThenTriggerGuide = false
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.InternalLateTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_MEDIATOR_RESTARTEND_SHOW, Delegate.GetOrCreate(self, self.HideCityHud))
    self.city.cityExplorerManager:SetTeamSelected(nil)
    self.city.cityExplorerManager:SetAllowTeamTroopTriggerOn(true)
    self.city.cityExplorerManager:SetAllowShowLine(true)
    local seEnv = self.city.citySeManger._seEnvironment
    if seEnv then
        seEnv:ProcessBattleEnd()
    end
    self:HideExplorerHud()
    self:CloseBattleUI()
    if seEnv then
        seEnv:SetCurrentFocusPresetIndex(nil)
    end
    local willTransTo = self.stateMachine.willTransToStateName
    if (willTransTo ~= CityConst.STATE_CITY_SE_EXPLORER_FOCUS 
        and willTransTo ~= CityConst.STATE_CITY_SE_BATTLE_FOCUS
        and willTransTo ~= CityConst.STATE_CITY_ZONE_RECOVER_EFFECT
    ) 
    then
        self:RestoreCityHud()
        self:GiveupCamera()
        self.PostProcessStateChange = Delegate.GetOrCreate(self, self.OnPostProcessStateChange)
    else
        if self.city.camera then
            self.city.camera.ignorePinchTouchPos = false
            self.city.camera.enableDragging = true
        end
        self.PostProcessStateChange = nil
    end
end

function CityStateSeExplorerFocus:OnPostProcessStateChange()
    if not self.city or not self.city.citySeManger then return end
    local currentState = self.stateMachine:GetCurrentState()
    local currentStateName = currentState:GetName()
    if currentStateName == "CityStateSeExplorerFocus" then return end
    if currentStateName == "CityStateSeBattle" then return end
    if currentStateName == "CityStatePlayZoneRecoverEffect" then return end
    self.city.citySeManger:ExitExplorerFocus()
end

---@param city City
function CityStateSeExplorerFocus:OnStatusChanged(city, zoneId, elementIds)
    if not city:IsMyCity() then return end
    if zoneId == 1 then
        self.stateMachine:ReadBlackboard("needDismissTeam")
    else
        self.stateMachine:WriteBlackboard("needDismissTeam", self._presetIndex)
    end
    self.stateMachine:WriteBlackboard("zoneId", zoneId, true)
    self.stateMachine:WriteBlackboard("elementIds", elementIds, true)
    self.stateMachine:WriteBlackboard("duration", CityConst.ZoneRecoverTime, true)
    self.stateMachine:WriteBlackboard("delay", CityConst.ZoneRecoverUnPollutedTimeDelay, true)
    self.stateMachine:WriteBlackboard("hudHidePart", self._lastChangedHud, true)
    self.stateMachine:WriteBlackboard("fromExplore", true, true)
    self._lastChangedHud = nil
    self.stateMachine:ChangeState(CityConst.STATE_CITY_ZONE_RECOVER_EFFECT)
end

function CityStateSeExplorerFocus:ReEnter()
    self:Exit()
    self:OnPostProcessStateChange()
    self:Enter()
end

function CityStateSeExplorerFocus:HideCityHud(hudHidePart)
    if hudHidePart then
        self._lastChangedHud = hudHidePart
    else
        self._lastChangedHud = nil
        ---@type HUDMediator
        local hud = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
        if hud then
            self._lastChangedHud = hud:ShowHidePartChanged(ControlHudPart, false)
        else
            g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, false)
        end
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then return end
    ---@type KingdomSceneStateInCity
    local sceneState = scene.stateMachine:GetCurrentState()
    if not sceneState or not sceneState.HideMarkerHUD then return end
    sceneState:HideMarkerHUD()
end

function CityStateSeExplorerFocus:RestoreCityHud()
    local changed = self._lastChangedHud
    self._lastChangedHud = nil
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, ControlHudPart, true, changed)
    
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then return end
    ---@type KingdomSceneStateInCity
    local sceneState = scene.stateMachine:GetCurrentState()
    if not sceneState or not sceneState.ShowMarkerHUD then return end
    sceneState:ShowMarkerHUD()
end

function CityStateSeExplorerFocus:ShowExplorerHud()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.WorldEventDetailMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.WorldConquerFailTipMediator)
    if self._hudRuntimeId then
        g_Game.UIManager:Close(self._hudRuntimeId)
    end
    ---@type CitySeExplorerHudUIMediatorParameter
    local param = {}
    param.mgr = self.city.citySeManger
    param.presetIndex = self._presetIndex
    self._hudRuntimeId = g_Game.UIManager:Open(UIMediatorNames.CitySeExplorerHudUIMediator, param)

    if self._joystickRuntimeId then
        g_Game.UIManager:Close(self._joystickRuntimeId)
    end
    ---@type SEHudJoyStickMediatorParameter
    local uiParameter = {}
    uiParameter.seEnv = self.city.citySeManger._seEnvironment
    uiParameter.throwBallTimeLimit = ConfigTimeUtility.NsToSeconds(ConfigRefer.ConstMain:PetCatchSlowMaxDuration())
    self._joystickRuntimeId = g_Game.UIManager:Open(UIMediatorNames.SEHudJoyStickMediator, uiParameter)
end

function CityStateSeExplorerFocus:OpenBattleUI()
    g_Game.EventManager:AddListener(EventConst.SE_HUD_OPENED, Delegate.GetOrCreate(self, self.OnSEBattleHudReady))
    ---@type SEHudMediatorParameter
    local parameter = {}
    parameter.tid = self.city.citySeManger._seEnvironment._instanceId
    parameter.noCardMode = true
    parameter.hideExitBtn = true
    parameter.hideSkillShow = true
    parameter.noAutoMode = true
    self._seBattleHUDRuntimeId = g_Game.UIManager:Open(UIMediatorNames.SEHudMediator, parameter)
end

function CityStateSeExplorerFocus:CloseBattleUI()
    g_Game.EventManager:RemoveListener(EventConst.SE_HUD_OPENED, Delegate.GetOrCreate(self, self.OnSEBattleHudReady))
    if self._seBattleHUDRuntimeId then
        local id = self._seBattleHUDRuntimeId
        self._seBattleHUDRuntimeId = nil
        g_Game.UIManager:Close(id)
    end
end

function CityStateSeExplorerFocus:OnSEBattleHudReady()
    self._seBattleHudReady = true
    local env = self.city.citySeManger._seEnvironment
    if not env then return end
    env:ProcessBattleStart()
    env:GetSkillManager():OnPlayerCardChange()
    env:SetAllowClickMove(false)
end

function CityStateSeExplorerFocus:HideExplorerHud()
    if self._hudRuntimeId then
        local id = self._hudRuntimeId
        self._hudRuntimeId = nil
        g_Game.UIManager:Close(id)
    end
    
    if self._joystickRuntimeId then
        local id = self._joystickRuntimeId
        self._joystickRuntimeId = nil
        g_Game.UIManager:Close(id)
    end
end

function CityStateSeExplorerFocus:RefreshCameraSizeLimit()
     ---@type KingdomScene
     local kingdomScene = g_Game.SceneManager.current
     if kingdomScene then
         local state = kingdomScene.stateMachine:GetCurrentState()
         if state and state.SetCameraSize then
             state:SetCameraSize()
         end
     end
end

function CityStateSeExplorerFocus:TakeOverCamera(needEnterCameraZoom)
    self._willExit = false
    self._currentCameraV = CS.UnityEngine.Vector3.zero
    local camera = self.city:GetCamera()
    camera:ForceGiveUpTween()
    self:BlockCamera()
    camera.ignorePinchTouchPos = true
    self._inEnterCameraTween = true
    self._zoomCameraStartSize = camera:GetSize()
    if needEnterCameraZoom then
        self._zoomCameraSizeTime = self._zoomCameraSizeTimeTotal
    else
        self._zoomCameraSizeTime = nil
    end
    self:RefreshCameraSizeLimit()
    -- camera:ZoomTo(CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE, ConfigRefer.CityConfig:CityCameraZoomSeExplorerFocusDuration())
end

function CityStateSeExplorerFocus:GiveupCamera()
    self._inEnterCameraTween = false
    if not self.city or not self.city.camera then return end
    self.city.camera:ForceGiveUpTween()
    self.city.camera.ignorePinchTouchPos = false
    self:RecoverCamera()
    self._willExit = true
    self:RefreshCameraSizeLimit()
    self.city.camera:ZoomTo(CityConst.CITY_RECOMMEND_CAMERA_SIZE, 0.2)
end

---@param entity wds.ScenePlayer
function CityStateSeExplorerFocus:OnScenePlayerPresetChanged(entity, _)
    if self._isExiting then return end
    if not self._scenePlayerId or not entity or entity.ID ~= self._scenePlayerId then
        return
    end
    local scenePlayerPreset = entity.ScenePlayerPreset.PresetList
    for _, value in pairs(scenePlayerPreset) do
        if value.PresetIndex == self._presetIndex then
            if value.InExplore then
                return
            end
            -- if value.InBattle and value.InExplore then
            --     CityStateHelper.ExitToFocusOnBattle(self, value.BattleEntityId, self._presetIndex, true, self._lastChangedHud)
            --     self._lastChangedHud = nil
            -- end
            -- return
        end
    end
    self:ExitToIdleState()
end

function CityStateSeExplorerFocus:ExitToIdleState()
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    ---@type table<number, wds.ScenePlayer>
    local scenePlayer = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    if not scenePlayer then
        goto continue_base
    end
    for _, value in pairs(scenePlayer) do
        if value.Owner.PlayerID ~= myPlayerId then
            goto continue
        end
        local scenePreset = value.ScenePlayerPreset
        if not scenePreset.PresetList then
            goto continue
        end
        for _, preset in pairs(scenePreset.PresetList) do
            if not preset.InExplore then
                goto continue_in_list
            end
            CityStateHelper.ExitToFocusSeExplorer(self, value.ID, preset.PresetIndex, self._lastChangedHud)
            self._lastChangedHud = nil
            goto continue_exit
            ::continue_in_list::
        end
        ::continue::
    end
    ::continue_base::
    self._isExiting = true
    if self._extiToIdleFocusOnGridV2 then
        local grid = self._extiToIdleFocusOnGridV2
        self._extiToIdleFocusOnGridV2 = nil
        self._willExit = true
        self:RefreshCameraSizeLimit()
        local lookAtPos = self.city:GetWorldPositionFromCoord(grid.x, grid.y)
        self.city.camera:LookAt(lookAtPos, 0.2, function()
            CityStateSeExplorerFocus.super.ExitToIdleState(self)
        end)
        return
    end
    CityStateSeExplorerFocus.super.ExitToIdleState(self)
    ::continue_exit::
end

function CityStateSeExplorerFocus:OnClick(gesture)
if not gesture then return end
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    local _, x, y, hitPoint, _, cellTile, _ = self.city:RaycastAnyTileBase(gesture.position)
    if x and y and hitPoint and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            if not zone then
                return true
            end
            if self:OnClickZone(zone, hitPoint) then
                return true
            end
        end
    end
    -- 点击全区内的点认为是前往安全区
    if cellTile then
        return self:OnClickCellTile(cellTile)
    else
        if UNITY_RUNTIME_ON_GUI_ENABLED then
            local RuntimeDebugSettings = require("RuntimeDebugSettings")
            local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine")
            local has, v = RuntimeDebugSettings:GetInt(RuntimeDebugSettingsKeyDefine.DebugAllownClickGroundCitySeMode)
            if has and v == 1 then
                return self:OnClickEmpty(gesture)
            end
        end
        -- return self:OnClickEmpty(gesture)
        ---取消点地面移动
        return true
    end
end

---@param cellTile CityCellTile
function CityStateSeExplorerFocus:OnClickCellTile(cellTile)
    if cellTile then
        if self.city.safeAreaWallMgr:IsValidSafeArea(cellTile.x, cellTile.y) then
            self:OrderTeamGotoCoord(cellTile.x, cellTile.y)
            return true
        end
    end
    if cellTile and cellTile:IsPolluted() then
        local x1, y1 = self:GetClosestPollutedCoord(cellTile)
        if x1 > 0 and y1 > 0 then
            self:TryShowCreepToast(x1, y1)
        end
        return true
    end
    local gridCell = cellTile:GetCell()
    -- if gridCell:IsResource() then
    --     local accepted,firstBusyPetId = self.city.citySeManger:SetSeExplorerCollectResource(self._presetIndex, gridCell.tileId)
    --     if accepted == CitySeExplorerPetsLogicDefine.SetWorkResult.NoWorkTypeWorker then
    --         local element = self.city.elementManager:GetElementById(gridCell.tileId)
    --         if element and element.resourceConfigCell then
    --             local elementResource = element.resourceConfigCell
    --             local cityWork = ConfigRefer.CityWork:Find(elementResource:CollectWork())
    --             if cityWork then
    --                 ModuleRefer.ToastModule:AddJumpToast(I18N.GetWithParamList("hud_explore_no_pet_1", I18N.Get(cityWork:Name())))
    --             end
    --         end
    --     elseif accepted == CitySeExplorerPetsLogicDefine.SetWorkResult.NoFreeWorkTypeWorer then
    --         local petName = ModuleRefer.PetModule:GetPetName(firstBusyPetId)
    --         ModuleRefer.ToastModule:AddJumpToast(I18N.GetWithParamList("hud_explore_no_pet_2", petName))
    --     end
    --     return true
    -- end
    if gridCell:IsBuilding() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("repair_furniture_tips"))
        return true
    end
    if not gridCell:IsNpc() then
        return true
    end
    g_Logger.Log("Click Npc:%d", gridCell.tileId)
    local city = cellTile:GetCity()
    local cell = cellTile:GetCell()
    local elementCfg = ConfigRefer.CityElementData:Find(cell.tileId)
    local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
    if npcCfg:NoInteractable() then
        return false
    end
    if npcCfg:NoInteractableInSEExplore() then
        return true
    end
    if npcCfg:FinalNoInteractable() then
        local player = ModuleRefer.PlayerModule:GetPlayer()
        if player then
            local npc = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[cell.tileId]
            if npc and ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npc, true) then
                return false
            end
        end
    end
    local elePos = elementCfg:Pos()
    local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcCfg)

    ---@type ClickNpcEventContext
    local context = {}
    context.cityUid = city.uid
    context.elementConfigID = cell.tileId
    context.targetPos = pos
    context.selectedTroopPresetIdx = self._presetIndex + 1
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
    return true
end

function CityStateSeExplorerFocus:OnClickTrigger(trigger, position)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    --- 如果Trigger所属的地块本身阻止了Trigger的触发
    if trigger:IsTileBlockExecute() then
        return false
    end

    --- 判断Trigger自身归属坐标是否不在迷雾中
    local x, y = trigger:GetOwnerPos()
    if x and y and self.city.gridConfig:IsLocationValid(x, y) then
        if self.city.zoneManager then
            local zone = self.city.zoneManager:GetZone(x, y)
            --- 该坐标没有被划入任何zone则为非法对象
            if not zone then
                return true
            end
            local hitPoint = self.city:GetCenterPlanePositionFromCoord(x, y, 1, 1)
            if self:OnClickZone(zone, hitPoint) then
                return true
            end
        end
        --这个模式下下也就npc 能响应点击
        local mask = self.city.gridLayer:Get(x, y)
        if CityGridLayerMask.HasFurniture(mask) then
            return false
        end
        if CityGridLayerMask.IsPlacedCellTile(mask) then
            local mainCell = self.city.grid:GetCell(x, y)
            if not mainCell or (not mainCell:IsNpc() and not mainCell:IsResource()) then
                return false
            end
        else
            return false
        end
    end

    --- Trigger所属地块本身受污染
    if trigger:IsTilePolluted() then
        local x, y = self:GetClosestPollutedCoord(trigger:GetTile())
        if x > 0 and y > 0 then
            self:TryShowCreepToast(x, y)
            return false
        end
    end
    return trigger:ExecuteOnClick()
end

function CityStateSeExplorerFocus:OnClickZone(zone, hitPoint)

end

---@param gesture CS.DragonReborn.TapGesture|{position:CS.UnityEngine.Vector3}
function CityStateSeExplorerFocus:OnClickEmpty(gesture)
    if not gesture then return end
    local pathFinding = self.city.cityPathFinding
    local point = self.city:GetCamera():GetHitPoint(gesture.position)
    local gotoWorldPos = pathFinding:NearestWalkableOnGraph(point, pathFinding.AreaMask.CityGround)
    if not gotoWorldPos then return end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(self._presetIndex)
    if not self.city.citySeManger:SetSeCaptainClickMove(gotoWorldPos, self._presetIndex) then return end
    if team then
        team:GoToTarget(gotoWorldPos, 0, true)
    end
end

function CityStateSeExplorerFocus:OrderTeamGotoCoord(x, y)
    local worldPos = self.city:GetWorldPositionFromCoord(x, y)
    local pathFinding = self.city.cityPathFinding
    local gotoWorldPos = pathFinding:NearestWalkableOnGraph(worldPos, pathFinding.AreaMask.CityGround)
    if not gotoWorldPos then return end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(self._presetIndex)
    if not self.city.citySeManger:SetSeCaptainClickMove(gotoWorldPos, self._presetIndex) then return end
    if team then
        team:GoToTarget(gotoWorldPos, 0, true)
    end
end

function CityStateSeExplorerFocus:InternalLateTick(dt)
    if ModuleRefer.HeroRescueModule:GetManualShowItemBubble() then
        return false
    end
    if self._extiToIdleFocusOnGridV2 then return false end
    if not self.city.citySeManger._seEnvironment then return true end
    local pos, targetPos = nil
    if self._lookAtMode == LOOK_AT_MODE.LOOK_AT_HERO_UNIT then
        local unit = self.city.citySeManger:GetCurrentCameraFocusOnHero(self._presetIndex)
        if not unit then return false end
        pos = unit:GetActor():GetPosition()
        if not pos then return false end
        local coordXNoFloor,coordYNoFloor = self.city:GetCoordFromPosition(pos, true)
        if not coordXNoFloor or not coordYNoFloor then return false end
        targetPos = self.city:GetWorldPositionFromCoord(coordXNoFloor, coordYNoFloor)
    else
        local team = self.city.citySeManger._seEnvironment:GetTeamManager():GetOperatingTeam()
        if not team then return false end
        pos = team:GetFormationCenterPos()
        if not pos then return false end
        local coordXNoFloor,coordYNoFloor = self.city:GetCoordFromPosition(pos, true)
        if not coordXNoFloor or not coordYNoFloor then return false end
        targetPos = self.city:GetWorldPositionFromCoord(coordXNoFloor, coordYNoFloor)
    end
    local currentCameraPos = self.city:GetCamera():GetLookAtPlanePosition()
    if not currentCameraPos then return false end
    local cameraSizeEnter = false
    if self._zoomCameraSizeTime then
        cameraSizeEnter = true
        self._zoomCameraSizeTime = self._zoomCameraSizeTime - dt
        local leftTime = math.max(0, self._zoomCameraSizeTime)
        if self._zoomCameraSizeTime <= 0 then
            self._zoomCameraSizeTime = nil
        end
        local lerp = math.inverseLerp(self._zoomCameraSizeTimeTotal, 0, leftTime)
        self.city:GetCamera():SetSize(math.lerp(self._zoomCameraStartSize, CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE, lerp))
    end
    local cameraPos, v = CS.UnityEngine.Vector3.SmoothDamp(currentCameraPos, targetPos, self._currentCameraV, dt)
    self._currentCameraV = v
    self.city:GetCamera():LookAt(cameraPos)
    local coordX,coordY = self.city:GetCoordFromPosition(pos)
    if not coordX or not coordY then return false end
    local zone = self.city.zoneManager:GetZone(coordX, coordY)
    if zone then
        if self._waitTickGetZoneId then
            self._waitTickGetZoneId = false
            self.city.citySeManger:EnterExplorerFocus(zone.id)
        else
            self.city.citySeManger:UpdateCurrentExploreZone(zone.id)
        end
    end
    if self._sendExitFocusFlag then return true end
    if self.city.safeAreaWallMgr:IsValidSafeArea(coordX, coordY) then
        if self.city.citySeManger:ExitInExplorerMode() then
            if zone and zone.config and zone.config.ExitExploreModeJumpToCityConfigExplorSeExitToZone then
                if zone.config:ExitExploreModeJumpToCityConfigExplorSeExitToZone() then
                    local targetZone = self.city.zoneManager:GetZoneById(ConfigRefer.CityConfig:ExplorSeExitToZone())
                    if targetZone and targetZone.config then
                        local center = targetZone.config:CenterPos()
                        self:MarkExitToGridPos(center:X(), center:Y())
                    end
                end
            end
            self._zoomCameraSizeTime = nil
            self._sendExitFocusFlag = true
            return true
        end
    end
    if self._waitTeamReadyThenTriggerGuide then
        self._waitTeamReadyThenTriggerGuide = false
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.EnterCitySeExploreMode)
    end
    if cameraSizeEnter then return false end
    local cameraSize = self.city:GetCamera():GetSize()
    local needSize = math.clamp(cameraSize, CityConst.CITY_SE_FOCUS_EXPLORER_NEAR_CAMERA_SIZE, CityConst.CITY_SE_FOCUS_EXPLORER_FAR_CAMERA_SIZE)
    local change = needSize - cameraSize
    if math.abs(change) > 0.1 then
        local cameraSize, v = CS.UnityEngine.Mathf.SmoothDamp(cameraSize, needSize, self._zoomCameraV, dt, 3)
        self._zoomCameraV = v
        self.city:GetCamera():SetSize(cameraSize)
    else
        self._inEnterCameraTween = false
        self._zoomCameraV = 0
        self:RefreshCameraSizeLimit()
    end
    return false
end

function CityStateSeExplorerFocus:TryShowCreepToast(x, y)
    CityStateHelper.TryShowCreepToast(self, x, y)
end

---@param tile CityTileBase|CityStaticObjectTile
function CityStateSeExplorerFocus:GetClosestPollutedCoord(tile)
    return CityStateHelper.GetClosestPollutedCoord(self, tile)
end

function CityStateSeExplorerFocus:GetCurrentPresetIndex()
    return self._presetIndex
end

function CityStateSeExplorerFocus:GetCameraMaxSize()
    if self._willExit then return nil,nil end
    if self._inEnterCameraTween then
        return 0, CityConst.CITY_FAR_CAMERA_SIZE
    end
    return CityConst.CITY_SE_FOCUS_EXPLORER_NEAR_CAMERA_SIZE, CityConst.CITY_SE_FOCUS_EXPLORER_FAR_CAMERA_SIZE
end

function CityStateSeExplorerFocus:MarkExitToGridPos(x, y)
    if x and y then
        self._extiToIdleFocusOnGridV2 = {x = x, y = y}
    else
        self._extiToIdleFocusOnGridV2 = nil
    end
end

function CityStateSeExplorerFocus:OnLightRestartEnd()
    self:HideCityHud()
end

return CityStateSeExplorerFocus