--- scene:scene_league_war

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceWarTabBuildUp = require("AllianceWarTabBuildUp")
local AllianceWarTabBuilding = require("AllianceWarTabBuilding")
local AllianceWarTabActivity = require("AllianceWarTabActivity")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local AllianceExpeditionCreateType = require('AllianceExpeditionCreateType')
local BaseUIMediator = require("BaseUIMediator")

---@class AllianceWarNewMediatorParameter
---@field enterTabIndex number
---@field backNoAni boolean

---@class AllianceWarNewMediator:BaseUIMediator
---@field new fun():AllianceWarNewMediator
---@field super BaseUIMediator
local AllianceWarNewMediator = class('AllianceWarNewMediator', BaseUIMediator)

function AllianceWarNewMediator:ctor()
    BaseUIMediator.ctor(self)
    self._selectedTab = nil
    ---@type AllianceWarTabBuildUp|AllianceWarTabBuilding|AllianceWarTabActivity
    self._selectedTabLogic = nil
    self._backNoAni = false
end

function AllianceWarNewMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_0 = self:LuaObject("child_tab_left_btn_0")
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_1 = self:LuaObject("child_tab_left_btn_1")
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_2 = self:LuaObject("child_tab_left_btn_2")

    self._p_group_none = self:GameObject("p_group_none")
    self._p_text_none = self:Text("p_text_none", "alliance_war_toast1")
    
    self._p_tabBuildUp = AllianceWarTabBuildUp.new(self, "p_group_war")
    self._p_tabBuilding = AllianceWarTabBuilding.new(self, "p_group_building")
    self._p_tabActivity = AllianceWarTabActivity.new(self, "p_group_event")
    self._p_tabBuildUp._p_root:SetVisible(false)
    self._p_tabBuilding._p_root:SetVisible(false)
    if self._p_tabActivity then
        self._p_tabActivity._p_root:SetVisible(false)
    end
end

---@param param AllianceWarNewMediatorParameter|nil
function AllianceWarNewMediator:OnOpened(param)

    self._backNoAni = param and param.backNoAni or false
    
    ---@type CommonBackButtonData
    local btnParameter = {}
    btnParameter.title = ""
    btnParameter.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_common_btn_back:FeedData(btnParameter)
    
    local clickFunc = Delegate.GetOrCreate(self, self.OnClickTabIndex)
    ---@type CommonChildTabLeftBtnParameter
    local tabData = {}
    tabData.index = 1
    tabData.btnName = I18N.Get("alliance_war_title1")
    tabData.isLocked = false
    tabData.onClick = clickFunc
    self._child_tab_left_btn_0:FeedData(tabData)
    tabData = {}
    tabData.index = 2
    tabData.btnName = I18N.Get("alliance_war_title2")
    tabData.isLocked = false
    tabData.onClick = clickFunc
    self._child_tab_left_btn_1:FeedData(tabData)
    tabData = {}
    tabData.index = 3
    tabData.btnName = I18N.Get("alliance_science_activity")
    tabData.isLocked = false
    tabData.onClick = clickFunc
    self._child_tab_left_btn_2:FeedData(tabData)
    self:OnClickTabIndex(param and param.enterTabIndex and math.clamp(math.floor(param.enterTabIndex), 1, 3) or 1)
end

function AllianceWarNewMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    if self._selectedTabLogic then
        self._selectedTabLogic:OnEnter()
    end
    self:SetupTrackNotify(true)
end

function AllianceWarNewMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    self:SetupTrackNotify(false)
    if self._selectedTabLogic then
        self._selectedTabLogic:OnExit()
        self._selectedTabLogic = nil
    end
end

function AllianceWarNewMediator:OnClickTabIndex(index)
    if self._selectedTab == index then
        return
    end

    local keyMap = FPXSDKBIDefine.ExtraKey.alliance_battle_mediator
    local extraData = {}
    extraData[keyMap.alliance_id] = ModuleRefer.AllianceModule:GetAllianceId()
    if index == 1 then
        extraData[keyMap.type] = 0
    elseif index == 2 then
        extraData[keyMap.type] = 1
    elseif index == 3 then
        extraData[keyMap.type] = 2
    end
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.alliance_battle_mediator, extraData)

    if self._selectedTabLogic then
        self._selectedTabLogic:OnExit()
        self._selectedTabLogic = nil
    end
    self._selectedTab = index
    self._child_tab_left_btn_0:SetStatus(index == 1 and 0 or 1)
    self._child_tab_left_btn_1:SetStatus(index == 2 and 0 or 1)
    self._child_tab_left_btn_2:SetStatus(index == 3 and 0 or 1)
    if index == 1 then
        self._selectedTabLogic = self._p_tabBuildUp
        self._child_common_btn_back:UpdateTitle(I18N.Get("alliance_war_title1"))
    elseif index == 2 then
        self._selectedTabLogic = self._p_tabBuilding
        self._child_common_btn_back:UpdateTitle(I18N.Get("alliance_war_title2"))
    elseif index == 3 then
        self._selectedTabLogic = self._p_tabActivity
        self._child_common_btn_back:UpdateTitle(I18N.Get("alliance_science_activity"))
    else
        self._child_common_btn_back:UpdateTitle('')
    end
    if self._selectedTabLogic then
        self._selectedTabLogic:OnEnter()
    end
end

function AllianceWarNewMediator:SetTabHasData(hasData)
    self._p_group_none:SetVisible(not hasData)
end

function AllianceWarNewMediator:SetupTrackNotify(add)
    if self._isTracked == add then
        return
    end
    self._isTracked = add
    local notificationModule = ModuleRefer.NotificationModule
    
    local rallyNode = self._child_tab_left_btn_0:GetNotificationNode()
    local siegeNode = self._child_tab_left_btn_1:GetNotificationNode()
    local activityNode = self._child_tab_left_btn_2:GetNotificationNode()

    if add then
        if rallyNode then
            rallyNode:SetVisible(true)
            local dyNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabRally, NotificationType.ALLIANCE_WAR_TAB_RALLY)
            notificationModule:AttachToGameObject(dyNode, rallyNode.go, rallyNode.redTextGo, rallyNode.redText)
        end
        if siegeNode then
            siegeNode:SetVisible(true)
            local dyNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabSiege, NotificationType.ALLIANCE_WAR_TAB_SIEGE)
            notificationModule:AttachToGameObject(dyNode, siegeNode.go, siegeNode.redTextGo, siegeNode.redText)
        end
        if activityNode then
            activityNode:SetVisible(true)
            local dyNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.WarTabWar, NotificationType.ALLIANCE_WAR_TAB_WAR)
            notificationModule:AttachToGameObject(dyNode, activityNode.go, activityNode.redTextGo, activityNode.redText)
            -- local res = ModuleRefer.WorldEventModule:GetAllianceExpeditions()
            -- local count = 0
            -- for k,v in pairs(res)do
            --     if v.CreateType ~= AllianceExpeditionCreateType.ItemActivator then
            --         count = count + 1
            --     end
            -- end
            -- notificationModule:SetDynamicNodeNotificationCount(dyNode, count)
        end
    else
        if rallyNode then
            notificationModule:RemoveFromGameObject(rallyNode.go, false)
        end
        if siegeNode then
            notificationModule:RemoveFromGameObject(siegeNode.go, false)
        end
        if activityNode then
            notificationModule:RemoveFromGameObject(activityNode.go, false)
        end
    end
end

function AllianceWarNewMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceWarNewMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return AllianceWarNewMediator