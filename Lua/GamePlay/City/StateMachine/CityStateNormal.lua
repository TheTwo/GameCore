local EventConst = require("EventConst")
local CityConst = require("CityConst")
local CityStateDefault = require("CityStateDefault")
local CityCellTile = require("CityCellTile")
local CityFurnitureTile = require("CityFurnitureTile")
local CityZoneStatus = require("CityZoneStatus")
---@class CityStateNormal:CityStateDefault
---@field new fun():CityStateNormal
local CityStateNormal = class("CityStateNormal", CityStateDefault)
local UIMediatorNames = require("UIMediatorNames")
local CityUtils = require("CityUtils")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityPressStatus = require("CityPressStatus")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")
local CityStateHelper = require("CityStateHelper")
local DBEntityPath = require("DBEntityPath")

function CityStateNormal:Enter()
    CityStateDefault.Enter(self)
    self._waitOnLightRestartEndCheckViewFinished = false
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_NODE_SHOW_MENU,
                                    Delegate.GetOrCreate(self,
                                                         self.OnCreepNodeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SELECT,
                                    Delegate.GetOrCreate(self,
                                                         self.OnSelectToExplorerTeamState))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_TEAM_OPERATE_MENU, Delegate.GetOrCreate(self, self.OnOpenCityTeamOperateMenu))
    ModuleRefer.SlgModule:EnableTouch(true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_HIDE_NAME, self.city)
    self.city:RefreshBorderParams()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)

    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_VIEW_LOADED, Delegate.GetOrCreate(self, self.OnViewLoadFinish))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpedtionCreate))
    self.city.cityExplorerManager:SetAllowShowLine(true)
    local inheritedFromExplore = self.stateMachine:ReadBlackboard("inheritedFromExplore", true)
    self._waitExpedtionId = nil
    --- this may jump state to CityStateSeBattle or CityStateSeExplorerFocus
    local reason = self.stateMachine:ReadBlackboard("ENTER_NORMAL_REASON")
    if reason == "OnLightRestartBegin" then
        self._waitOnLightRestartEndCheckViewFinished = true
        return
    end
    self.alpha = 1
    self:RecoverHudRootAlphaFromCache(false)
    local ret,id = CityStateHelper.CheckAndJumpToSeExplorerState(self)
    if ret == CityConst.TransToSeStateResult.WaitExpeditionEntity then
        self._waitExpedtionId = id
        return
    end
    if ret ~= CityConst.TransToSeStateResult.NoNeed then
        return
    end
    if inheritedFromExplore then
        ---@type CityExitExploreTipMediatorParameter
        local param = {}
        param.tipText = I18N.Get("city_area_task18")
        param.delayClose = 1
        g_Game.UIManager:Open(UIMediatorNames.CityExitExploreTipMediator, param)

        local hasGuideFingerSlideShown = g_Game.PlayerPrefsEx:GetIntByUid("HAS_GUIDE_FINGER_SLIDE_SHOWN", 0)
        if hasGuideFingerSlideShown == 0 then
            g_Game.PlayerPrefsEx:SetIntByUid("HAS_GUIDE_FINGER_SLIDE_SHOWN", 1)
            local UIAsyncDataProvider = require("UIAsyncDataProvider")
            local provider = UIAsyncDataProvider.new()
            provider:Init(UIMediatorNames.GuideFingerSlideMediator,
            nil, UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator,
            UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable, false)
            provider:SetOtherMediatorCheckType(0)
            provider:AddOtherMediatorBlackList(UIMediatorNames.CityExitExploreTipMediator)
            g_Game.UIAsyncManager:AddAsyncMediator(provider, false)
        end
    end
end

function CityStateNormal:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_NODE_SHOW_MENU,
                                       Delegate.GetOrCreate(self,
                                                            self.OnCreepNodeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SELECT,
                                       Delegate.GetOrCreate(self,
                                                            self.OnSelectToExplorerTeamState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_TEAM_OPERATE_MENU, Delegate.GetOrCreate(self, self.OnOpenCityTeamOperateMenu))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_SERVER_PUSH_RECOVERED, Delegate.GetOrCreate(self, self.OnStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_VIEW_LOADED, Delegate.GetOrCreate(self, self.OnViewLoadFinish))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpedtionCreate))
    self.startPress = CityPressStatus.NONE
    self.pressTile = nil
    self.gestureTime = 0
    self._waitExpedtionId = nil
    ModuleRefer.SlgModule:EnableTouch(false)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
    self.alpha = 1
    self:RecoverHudRootAlphaFromCache(false)
    CityStateDefault.Exit(self)
end

function CityStateNormal:OnCameraSizeChanged(oldValue, newValue)
    local state = self.city:GetSuitableIdleState(newValue)
    if state ~= CityConst.STATE_NORMAL then
        self.stateMachine:ChangeState(state)
    end
end

function CityStateNormal:OnSelectToExplorerTeamState(cityUid, focusOnTeam)
    if cityUid and self.city and self.city.uid == cityUid and
        not self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("FOCUS_ON_TEAM", focusOnTeam, true)
        self.stateMachine:ChangeState(CityConst.STATE_EXPLORER_TEAM_SELECT)
    end
end

---@param team CityExplorerTeam
function CityStateNormal:OnOpenCityTeamOperateMenu(cityUid, team)
    if cityUid ~= self.city.uid or self.city:IsEditMode() then return end
    self.stateMachine:WriteBlackboard("team", team, true)
    self.stateMachine:ChangeState(CityConst.STATE_EXPLORER_TEAM_OPERATE_MENU)
end

function CityStateNormal:OnCreepNodeSelected(uid, creepElementId)
    if self.city.uid ~= uid then return end

    local elementCfg = ConfigRefer.CityElementData:Find(creepElementId)
    local cellTile = self.city.gridView:GetCellTile(elementCfg:Pos():X(),
                                                    elementCfg:Pos():Y())
    if cellTile then
        local cell = cellTile:GetCell()
        if cell and cell:IsCreepNode() then
            self.stateMachine:WriteBlackboard("cellTile", cellTile)
            self.stateMachine:ChangeState(CityConst.STATE_CREEP_NODE_SELECT)
        end
    end
end

function CityStateNormal:InvokeAction(delegates, trans, pos)
    pos = pos or CS.UnityEngine.Vector3.zero    
    for _, v in ipairs(delegates) do
        local state, result = pcall(v, trans, pos)
        if not state then
            g_Logger.Error(result)
        end        
        if result then
            return result
        end
    end
    return false
end

function CityStateNormal:OnClick(gesture) 
    if self.onClick then
        if self:InvokeAction(self.onClick,nil,gesture.position,true) then
            return
        end
    end
    CityStateDefault.OnClick(self, gesture) 
end

function CityStateNormal:AddOnClick(callback)
    if not self.onClick then
        self.onClick = {}
    end
    if not table.ContainsValue(self.onClick,callback) then
        table.insert(self.onClick,callback)
    end
end

function CityStateNormal:RemoveOnClick(callback)
    if not self.onClick then return end
    table.removebyvalue(self.onClick,callback)
end

---@param city City
function CityStateNormal:OnStatusChanged(city, zoneId, elementIds)
    if not city:IsMyCity() then return end
    if zoneId == 1 then
        self.stateMachine:ReadBlackboard("needDismissTeam")
    end
    self.stateMachine:WriteBlackboard("zoneId", zoneId, true)
    self.stateMachine:WriteBlackboard("elementIds", elementIds, true)
    self.stateMachine:WriteBlackboard("duration", CityConst.ZoneRecoverTime, true)
    self.stateMachine:WriteBlackboard("delay", CityConst.ZoneRecoverUnPollutedTimeDelay, true)
    self.stateMachine:ChangeState(CityConst.STATE_CITY_ZONE_RECOVER_EFFECT)
end

function CityStateNormal:OnExpedtionCreate(typeId, entity)
    if not self._waitExpedtionId or self._waitExpedtionId ~= entity.ID then return end
    self._waitExpedtionId = nil
    CityStateHelper.CheckAndJumpToSeExplorerState(self)
end

---@param entity wds.ScenePlayer
function CityStateNormal:OnScenePlayerPresetChanged(entity, _)
    local ret,id = CityStateHelper.OnScenePlayerPresetChanged(self, entity, _)
    if ret == CityConst.TransToSeStateResult.WaitExpeditionEntity then
        self._waitExpedtionId = id
    end
end

function CityStateNormal:OnViewLoadFinish(city)
    if self.city ~= city then return end
    if not self._waitOnLightRestartEndCheckViewFinished then return end
    self._waitOnLightRestartEndCheckViewFinished = false
    local ret,id = CityStateHelper.CheckAndJumpToSeExplorerState(self)
    if ret == CityConst.TransToSeStateResult.WaitExpeditionEntity then
        self._waitExpedtionId = id
    end
end

function CityStateNormal:OnLightRestartEnd()
    if not self._waitOnLightRestartEndCheckViewFinished then return end
    if not self.city:ViewFinished() then return end
    self._waitOnLightRestartEndCheckViewFinished = false
    local ret,id = CityStateHelper.CheckAndJumpToSeExplorerState(self)
    if ret == CityConst.TransToSeStateResult.WaitExpeditionEntity then
        self._waitExpedtionId = id
    end
end

return CityStateNormal
