--- scene:scene_league_member

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceMemberMediatorParameter
---@field backNoAni boolean

---@class AllianceMemberMediator:BaseUIMediator
---@field new fun():AllianceMemberMediator
---@field super BaseUIMediator
local AllianceMemberMediator = class('AllianceMemberMediator', BaseUIMediator)

function AllianceMemberMediator:ctor()
    BaseUIMediator.ctor(self)
    self._backNoAni = false
end

function AllianceMemberMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_member = self:LuaObject("child_tab_left_btn_member")
    
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_applies = self:LuaObject("child_tab_left_btn_applies")
    
    ---@type CommonChildTabLeftBtn
    self._child_tab_left_btn_recruit = self:LuaObject("child_tab_left_btn_recruit")

    ---@type AllianceMemberListComponent
    self._p_group_member = self:LuaObject("p_group_member")
    self._p_group_member:SetVisible(false)

    ---@type AllianceMemberAppliesComponent
    self._p_group_application = self:LuaObject("p_group_application")
    self._p_group_application:SetVisible(false)

    ---@type AllianceMemberRecruit
    self._p_group_recruit = self:LuaObject("p_group_recruit")
    self._p_group_recruit:SetVisible(false)
end

function AllianceMemberMediator:OnShow(param)
    self._allowVerityApply = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.VerityApply)
    self:SetupTabBtn()
    self:OnSelectMember()
    self:SetupEvents(true)
end

---@param param AllianceMemberMediatorParameter
function AllianceMemberMediator:OnOpened(param)
    self._backNoAni = param and param.backNoAni or false
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("member_list"),
    }
    btnData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_common_btn_back:FeedData(btnData)
end

function AllianceMemberMediator:OnHide(param)
    self:SetupEvents(false)
end

function AllianceMemberMediator:SetupEvents(isAdd)
    local notificationModule = ModuleRefer.NotificationModule
    local applySelection = self._child_tab_left_btn_applies._child_reddot_default
    local applyNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.MemberApplies, NotificationType.ALLIANCE_MEMBER_APPLIES_SELECTION)
    if isAdd and not self._eventsAdd then
        self._eventsAdd = true
        applySelection:SetVisible(true)
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
        notificationModule:AttachToGameObject(applyNode, applySelection.go, applySelection.redTextGo, applySelection.redText)
    elseif not isAdd and self._eventsAdd then
        notificationModule:RemoveFromGameObject(applySelection.go, false)
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
    end
end

function AllianceMemberMediator:OnSelectMember()
    self._child_tab_left_btn_member:SetStatus(0)
    if not self._allowVerityApply then
        self._child_tab_left_btn_applies:SetStatus(2)
        self._child_tab_left_btn_recruit:SetStatus(2)
    else
        self._child_tab_left_btn_applies:SetStatus(1)
        self._child_tab_left_btn_recruit:SetStatus(1)
    end
    self._p_group_member:SetVisible(true)
    self._p_group_application:SetVisible(false)
    self._p_group_recruit:SetVisible(false)
end

function AllianceMemberMediator:OnSelectApplies()
    if not self._allowVerityApply then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_no_permission_toast"))
        return
    end
    self._child_tab_left_btn_applies:SetStatus(0)
    self._child_tab_left_btn_member:SetStatus(1)
    self._child_tab_left_btn_recruit:SetStatus(1)
    self._p_group_member:SetVisible(false)
    self._p_group_application:SetVisible(true)
    self._p_group_recruit:SetVisible(false)
end

function AllianceMemberMediator:OnSelectRecruit()
    if not self._allowVerityApply then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_no_permission_toast"))
        return
    end
    self._child_tab_left_btn_applies:SetStatus(1)
    self._child_tab_left_btn_member:SetStatus(1)
    self._child_tab_left_btn_recruit:SetStatus(0)

    self._p_group_member:SetVisible(false)
    self._p_group_application:SetVisible(false)
    self._p_group_recruit:SetVisible(true)

end

function AllianceMemberMediator:SetupTabBtn()

    ---@type CommonChildTabLeftBtnParameter
    local tabData = {}
    tabData.index = 1
    tabData.btnName = I18N.Get("member_list")
    tabData.onClick = Delegate.GetOrCreate(self, self.OnSelectMember)
    self._child_tab_left_btn_member:FeedData(tabData)
    
    ---@type CommonChildTabLeftBtnParameter
    tabData = {}
    tabData.index = 2
    tabData.btnName = I18N.Get("apply_list")
    tabData.onClick = Delegate.GetOrCreate(self, self.OnSelectApplies)
    tabData.isLocked = not self._allowVerityApply
    self._child_tab_left_btn_applies:FeedData(tabData)

    ---@type CommonChildTabLeftBtnParameter
    tabData = {}
    tabData.index = 3
    tabData.btnName = I18N.Get("#招募列表")
    tabData.onClick = Delegate.GetOrCreate(self, self.OnSelectRecruit)
    self._child_tab_left_btn_recruit:FeedData(tabData)
end

function AllianceMemberMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return AllianceMemberMediator