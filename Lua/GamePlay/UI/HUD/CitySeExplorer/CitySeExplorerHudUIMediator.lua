--- scene:scene_hud_explore
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local CityConst = require("CityConst")
local CityZoneStatus = require("CityZoneStatus")
local TimelineGameEventDefine = require("TimelineGameEventDefine")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local Utils = require("Utils")
local UIHelper = require("UIHelper")
local ProtocolId = require("ProtocolId")

local BaseUIMediator = require("BaseUIMediator")

---@class CitySeExplorerHudUIMediatorParameter
---@field mgr CitySeManager
---@field presetIndex number

---@class CitySeExplorerHudUIMediator:BaseUIMediator
---@field new fun():CitySeExplorerHudUIMediator
---@field super BaseUIMediator
local CitySeExplorerHudUIMediator = class('CitySeExplorerHudUIMediator', BaseUIMediator)

function CitySeExplorerHudUIMediator:ctor()
    CitySeExplorerHudUIMediator.super.ctor(self)
    ---@type CitySeManager
    self._mgr = nil
    self._presetIndex = nil
    ---@type wds.ScenePlayerPresetBasisInfo
    self._currentTrackedBag = nil
    ---@type fun()
    self._currentTrackedBagRemoveFunc = nil
    self._currentRecoverBtnShow = false
    self._onCloseCloseConfirmPopId = nil
    ---@type table<number, CS.UnityEngine.CanvasGroup>
    self.partDic = {}

    ---@type CS.UnityEngine.GameObject[]
    self._manualChildGoList = {}
    ---@type CS.DragonReborn.UI.UIHelper.CallbackHolder[]
    self._manualChildHolderList = {}
    ---@see CurrencyComponent
    self._child_hud_resources = nil
end

function CitySeExplorerHudUIMediator:OnCreate(param)
    self._p_btn_backcity = self:Button("p_btn_backcity", Delegate.GetOrCreate(self, self.OnClickBackToCity))
    self._p_text_backcity = self:Text("p_text_backcity", "hud_explore_exit")
    ---@type CitySeExplorerHudTeamHeadList
    self._p_upgrade = self:LuaObject("p_upgrade")
    self._p_btn_recover = self:Button("p_btn_recover", Delegate.GetOrCreate(self, self.OnClickRecover))
    self._p_text_recover = self:Text("p_text_recover", "hud_explore_recover")
    self._p_btn_recover:SetVisible(false)
    ---@type UnitMarkerHudUIComponent
    self._child_hud_hint = self:LuaObject("child_hud_hint")
    ---@type HUDUTCClock
    self._p_btn_time = self:LuaObject("p_btn_time")
    ---@type CitySeExplorerHudCatchPetTip
    self._p_tips_pet_obtain = self:LuaObject("p_tips_pet_obtain")
    self._p_tips_pet_obtain:SetVisible(false)
    
    local canvasGroupType = typeof(CS.UnityEngine.CanvasGroup)
    self.partDic[HUDMediatorPartDefine.base_top] = self:BindComponent("base_top", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.left] = self:BindComponent("left", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.topLeft] = self:BindComponent("topleft", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.bottomLeft] = self:BindComponent("bottomleft", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.bottomRight] = self:BindComponent("bottomright", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.topRight] = self:BindComponent("topright", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.right] = self:BindComponent("right", canvasGroupType)
    local holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_hud_player_info", "topleft", Delegate.GetOrCreate(self, self.OnManualChildCreated), true)
    table.insert(self._manualChildHolderList, holder)
    holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_hud_resources", "topright", Delegate.GetOrCreate(self, self.OnManualChildCreated), true)
    table.insert(self._manualChildHolderList, holder)
    ---@type CS.UnityEngine.CanvasGroup
    self._canvasGroup = self:BindComponent("", typeof(CS.UnityEngine.CanvasGroup))
end

---@param param CitySeExplorerHudUIMediatorParameter
function CitySeExplorerHudUIMediator:SetupHud(param)
    self._param = param
    self._currentRecoverBtnShow = false
    self._mgr = param.mgr
    self._presetIndex = param.presetIndex
    ---@type CitySeExplorerHudTeamHeadListData
    local upgradeListData = {}
    upgradeListData.presetIndex = param.presetIndex
    upgradeListData.castleBriefId = self._mgr.city.uid
    self._p_upgrade:FeedData(upgradeListData)
    self._p_btn_recover:SetVisible(false)
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    ---@type table<number, wds.ScenePlayer>
    local scenePlayer = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    for _, value in pairs(scenePlayer) do
        if value.Owner.PlayerID == myPlayerId then
            self:OnTroopPresetChanged(value)
        end
    end
    self:RefreshExitBtnLock()
    local marker = self._mgr:GetExploreModeMarker()
    if marker then
        self._child_hud_hint:SetVisible(true)
        self._child_hud_hint:FeedData(marker)
    else
        self._child_hud_hint:SetVisible(false)
    end
    ---@type HUDUTCClockParameter
    local timeFormat = {}
    timeFormat.overrideTimeFormat = "HH:mm"
    self._p_btn_time:FeedData(timeFormat)
end

---@param param CitySeExplorerHudUIMediatorParameter
function CitySeExplorerHudUIMediator:OnShow(param)
    if param then
        self:SetupHud(param)
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.RefreshExitBtnLock))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.RefreshExitBtnLock))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, Delegate.GetOrCreate(self, self.OnStoryHideCityBubbleRefresh))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncCatchSePetSuccess, Delegate.GetOrCreate(self, self.OnCatchPetPush))
    if ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying() then
        self:OnStoryHideCityBubbleRefresh(true)
    end
end

function CitySeExplorerHudUIMediator:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.RefreshExitBtnLock))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.RefreshExitBtnLock))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, Delegate.GetOrCreate(self, self.OnStoryHideCityBubbleRefresh))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncCatchSePetSuccess, Delegate.GetOrCreate(self, self.OnCatchPetPush))
    if self._onCloseCloseConfirmPopId then
        g_Game.UIManager:Close(self._onCloseCloseConfirmPopId)
    end
    self._onCloseCloseConfirmPopId = nil
end

function CitySeExplorerHudUIMediator:OnClose()
    if self._onCloseCloseConfirmPopId then
        g_Game.UIManager:Close(self._onCloseCloseConfirmPopId)
    end
    self._onCloseCloseConfirmPopId = nil
    self._param = nil
    self._child_hud_resources = nil
    for _, value in ipairs(self._manualChildHolderList) do
        value:AbortAndCleanup()
    end
    table.clear(self._manualChildHolderList)
    local ct = typeof(CS.DragonReborn.UI.BaseComponent)
    for _, go in ipairs(self._manualChildGoList) do
        if Utils.IsNotNull(go) then
            local comp = go:GetComponent(ct)
            if Utils.IsNotNull(comp) then
                UIHelper.DeleteUIComponent(comp)
            else
                UIHelper.DeleteUIGameObject(go)
            end
        end
    end
    table.clear(self._manualChildGoList)
end

function CitySeExplorerHudUIMediator:OnTypeVisible()
    if Utils.IsNull(self._canvasGroup) then return end
    self._canvasGroup.alpha = 1
    self._canvasGroup.interactable = true
end

function CitySeExplorerHudUIMediator:OnTypeInvisible()
    if Utils.IsNull(self._canvasGroup) then return end
    self._canvasGroup.alpha = 0
    self._canvasGroup.interactable = false
end

function CitySeExplorerHudUIMediator:OnClickRecover()
    if not self._mgr then return end
    self._mgr:HomeSeTroopRecoverHp(self._presetIndex, self._p_btn_recover.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)))
end

function CitySeExplorerHudUIMediator:OnClickBackToCity()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
    ---@type CommonConfirmPopupMediatorParameter
    local data = {}
    data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    data.title = string.Empty
    data.content = I18N.Get("hud_explore_exit_pop_content")
    data.confirmLabel = I18N.Get("confirm")
    data.cancelLabel = I18N.Get("cancle")
    data.onConfirm = function(context)
        ---@type CityStateSeExplorerFocus
        local state = self._mgr.city.stateMachine:GetCurrentState()
        local teamBornSafeAreaId = nil
        if state and self._mgr.city:IsInSingleSeExplorerMode() then
            local safeAreaId,x,y = self._mgr.city.safeAreaWallMgr:GetBiggestIdSafeAreaIdCenter()
            if safeAreaId then
                teamBornSafeAreaId = safeAreaId
                state:MarkExitToGridPos(x, y)
            else
                local zoneId = ConfigRefer.CityConfig.ExplorSeExitToZone and ConfigRefer.CityConfig:ExplorSeExitToZone()
                if zoneId then
                    local zone = self._mgr.city.zoneManager:GetZoneById(zoneId)
                    if zone then
                        local grid = zone.config:CenterPos()
                        state:MarkExitToGridPos(grid:X(), grid:Y())
                    end
                end
            end
        end
        self._mgr:ExitInExplorerMode(self._p_btn_backcity.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)), teamBornSafeAreaId)
        return true
    end
    self._onCloseCloseConfirmPopId = g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

---@param entity wds.ScenePlayer
function CitySeExplorerHudUIMediator:OnTroopPresetChanged(entity, _)
    if not self._param then return end
    if not entity or not self._presetIndex or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self._currentTrackedBag = entity.ScenePlayerPreset.PresetList[self._presetIndex]
    self:CheckShowRecoverBtn()
end

function CitySeExplorerHudUIMediator:CheckShowRecoverBtn()
    local needShow = false
    ---@type table<number, SEHero>
    local heroes
    local playerId
    if not self._mgr or not self._presetIndex or not self._currentTrackedBag or self._currentTrackedBag.CurHp <= 0 then
        goto setup_button_visible
    end
    playerId = ModuleRefer.PlayerModule:GetPlayerId()
    heroes = self._mgr._seEnvironment:GetUnitManager():GetHeroList()
    for _, hero in pairs(heroes) do
        local entity = hero:GetEntity()
        if entity.Owner.PlayerID == playerId and entity.BasicInfo.PresetIndex == self._presetIndex then
            if entity.MapStates.StateWrapper.Battle then
                needShow = false
                break
            end
            if hero:GetHPServer() < hero:GetHPMaxServer() then
                needShow = true
                break
            end
        end
    end
    ::setup_button_visible::
    if needShow == self._currentRecoverBtnShow then return end
    self._currentRecoverBtnShow  = needShow
    self._p_btn_recover:SetVisible(self._currentRecoverBtnShow)
end

function CitySeExplorerHudUIMediator:Tick(dt)
    if not self._param then return end
    self:CheckShowRecoverBtn()
end

function CitySeExplorerHudUIMediator:RefreshExitBtnLock()
    if not self._param then return end
    local systemEntryId = ConfigRefer.CityConfig:CitySeExplorModeExitLock()
    if systemEntryId == 0 then
        local zone = ModuleRefer.CityModule.myCity and ModuleRefer.CityModule.myCity.zoneManager:GetZoneById(2)
        if zone then
            self._p_btn_backcity:SetVisible(zone:Recovered())
        else
            self._p_btn_backcity:SetVisible(true)
        end
        return
    end
    if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId) then
        self._p_btn_backcity:SetVisible(true)
    else
        self._p_btn_backcity:SetVisible(false)
    end
end

function CitySeExplorerHudUIMediator:OnStoryHideCityBubbleRefresh(nowPlaying)
    if nowPlaying then
        self:OnTimelineControlEventStart({ TimelineGameEventDefine.HUD_HIDE_PART, "everyThing"})
    else
        self:OnTimelineControlEventEnd({ TimelineGameEventDefine.HUD_HIDE_PART, "everyThing"})
    end
end

function CitySeExplorerHudUIMediator:OnTimelineControlEventStart(args)
    if args[1] == TimelineGameEventDefine.HUD_HIDE_PART then
        local flag = args[2]
        if not flag then
            return
        end
        local part = HUDMediatorPartDefine[flag]
        if not part then
            return
        end
        self._timeLineOperatePart = self:ShowHidePartChanged(part, false)
    end
end

function CitySeExplorerHudUIMediator:OnTimelineControlEventEnd(args)
    if args[1] == TimelineGameEventDefine.HUD_HIDE_PART then
        local flag = args[2]
        if not flag then
            return
        end
        local part = HUDMediatorPartDefine[flag]
        if not part then
            return
        end
        local hidePart = self._timeLineOperatePart 
        self._timeLineOperatePart = nil
        self:ShowHidePartChanged(part, true, hidePart)
    end
end

function CitySeExplorerHudUIMediator:ShowHidePartChanged(partFlags, isShow, lastChanged)
    local changed = {}
    local alphaValue
    if isShow then
        alphaValue = 1
    else
        alphaValue = 0
    end
    for part, canvasGroup in pairs(self.partDic) do
        if Utils.IsNotNull(canvasGroup) then
            if (part & partFlags) ~= 0 and (not lastChanged or lastChanged[canvasGroup]) then
                canvasGroup.alpha = alphaValue
                canvasGroup.interactable = alphaValue > 0
                canvasGroup.blocksRaycasts = alphaValue > 0
                changed[canvasGroup] = true
            end
        end
    end
    return changed
end

---@param go CS.UnityEngine.GameObject
function CitySeExplorerHudUIMediator:OnResourceChildCreated(go, _)
    self:OnManualChildCreated(go, _)
    if Utils.IsNull(go) then return end
    self._child_hud_resources = go:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
    ---@type CurrencyComponentData
    local data = {}
    data.inSeExplorerMode = true
    self._child_hud_resources:FeedData(data)
end

---@param go CS.UnityEngine.GameObject
function CitySeExplorerHudUIMediator:OnManualChildCreated(go, _)
    if Utils.IsNull(go) then return end
    table.insert(self._manualChildGoList, go)
    go.transform:SetAsLastSibling()
end

---@param pushData wrpc.SyncCatchSePetSuccessRequest
function CitySeExplorerHudUIMediator:OnCatchPetPush(isSuccess, pushData)
    if not isSuccess then return end
    self._p_tips_pet_obtain:SetVisible(true)
    ---@type CitySeExplorerHudCatchPetTipData
    local data = {}
    data.petTid = pushData.PetTid
    data.starSkillLevel = pushData.StarSkillLevel
    data.delayFadeOut = 3
    self._p_tips_pet_obtain:FeedData(data)
end

return CitySeExplorerHudUIMediator