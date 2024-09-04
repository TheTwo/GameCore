local UIHelper = require("UIHelper")
local Delegate = require("Delegate")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMainNotifyPopupComponent:BaseUIComponent
---@field new fun():AllianceMainNotifyPopupComponent
---@field super BaseUIComponent
local AllianceMainNotifyPopupComponent = class('AllianceMainNotifyPopupComponent', BaseUIComponent)

function AllianceMainNotifyPopupComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type AllianceMainNotifyPopupCellData[]
    self._cellsData = {}
    ---@type AllianceMainNotifyPopupCell[]
    self._cells = {}
    self._helpNumber = 0
    self._playerId = 0
    self._allianceId = nil
end

function AllianceMainNotifyPopupComponent:OnCreate(param)
    local selfTrans = self:Transform("")
    self._p_btn_popup_template = self:LuaBaseComponent("p_btn_popup_template")
    self._p_btn_popup_template:SetVisible(false)
    self._cellsData[1] = {
        icon = "sp_league_icon_notice_01",
        text = I18N.Get("league_hud_request"),
        count = nil,
        onclick = Delegate.GetOrCreate(self, self.OnClickHelpRequest),
    }
    self._cells[1] = UIHelper.DuplicateUIComponent(self._p_btn_popup_template, selfTrans).Lua
    self._cells[1]:SetVisible(true)
    self._cellsData[2] = {
        icon = "sp_league_icon_notice_03",
        text = I18N.Get("league_hud_mark"),
        count = nil,
        onclick = Delegate.GetOrCreate(self, self.OnClickMark),
    }
    self._cells[2] = UIHelper.DuplicateUIComponent(self._p_btn_popup_template, selfTrans).Lua
    self._cells[2]:SetVisible(false)
    self._cellsData[3]= {
        icon = "sp_league_icon_notice_02",
        text = I18N.Get("league_hud_notice"),
        count = nil,
        onclick = Delegate.GetOrCreate(self, self.OnClickNotice),
    }
    self._cells[3] = UIHelper.DuplicateUIComponent(self._p_btn_popup_template, selfTrans).Lua
    self._cells[3]:SetVisible(false)
end

function AllianceMainNotifyPopupComponent:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.NumHelps.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceHelpNumberChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceNoticeChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CACHED_MARK_UNREAD_CHANGE, Delegate.GetOrCreate(self, self.OnAllianceMarkChanged))
end

function AllianceMainNotifyPopupComponent:OnOpened(param)
    self._playerId = ModuleRefer.PlayerModule:GetPlayerId()
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    for i = 1, #self._cells do
        self._cells[i]:FeedData(self._cellsData[i])
    end
    self:OnAllianceHelpNumberChanged(ModuleRefer.PlayerModule:GetPlayer(), nil, true)
    self:OnAllianceNoticeChanged(self._allianceId, true)
    self:OnAllianceMarkChanged(ModuleRefer.AllianceModule:GetMyAllianceData(), true)
end

function AllianceMainNotifyPopupComponent:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_NOTICE_COUNT_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceNoticeChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.NumHelps.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceHelpNumberChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CACHED_MARK_UNREAD_CHANGE, Delegate.GetOrCreate(self, self.OnAllianceMarkChanged))
end

function AllianceMainNotifyPopupComponent:OnClickHelpRequest()
    g_Game.UIManager:Open(UIMediatorNames.AllianceHelpMediator)
end

function AllianceMainNotifyPopupComponent:OnClickMark()
    g_Game.UIManager:Open(UIMediatorNames.AllianceMarkMainMediator)
end

function AllianceMainNotifyPopupComponent:OnClickNotice()
    g_Game.UIManager:Open(UIMediatorNames.AllianceNoticePopupMediator)
end

---@param entity wds.Player
function AllianceMainNotifyPopupComponent:OnAllianceHelpNumberChanged(entity, _, skipUpdateEnd)
    if not self._playerId or not entity or self._playerId ~= entity.ID then
        return
    end
    local number = entity.PlayerAlliance.NumHelps
    if number == self._helpNumber then
        return
    end
    self._helpNumber = number
    self._cells[1]:UpdateNumber(number, number > 0)
    if skipUpdateEnd then
        return
    end
end

---@param allianceId number
function AllianceMainNotifyPopupComponent:OnAllianceNoticeChanged(allianceId, skipUpdateEnd)
    if not self._allianceId or self._allianceId ~= allianceId then
        return
    end
    local notificationModule = ModuleRefer.NotificationModule
    local noticeNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.Notice, NotificationType.ALLIANCE_MAIN_NOTICE)
    local isR4Above = ModuleRefer.AllianceModule:IsAllianceR4Above()
    local nodeCount = noticeNode.Children.Count
    if noticeNode and nodeCount > 0 then
        self._cells[3]:SetVisible(true)
        if noticeNode.NotificationCount > 0 then
            self._cells[3]:UpdateContent(I18N.Get("alliance_notice_title1"))
            self._cells[3]:UpdateNumber(noticeNode.NotificationCount, true)
        else
            self._cells[3]:UpdateContent(I18N.Get("alliance_notice_title3"))
            self._cells[3]:UpdateNumber(nodeCount, false)
            --if isR4Above then
            --    self._cells[3]:UpdateContent(I18N.Get("alliance_notice_title1"))
            --    self._cells[3]:UpdateNumber(nodeCount, false)
            --else
            --    self._cells[3]:UpdateContent(I18N.Get("alliance_notice_title3"))
            --    self._cells[3]:UpdateNumber(nodeCount, false)
            --end
        end
    else
        if isR4Above then
            self._cells[3]:SetVisible(true)
            self._cells[3]:UpdateContent(I18N.Get("alliance_notice_release"))
            self._cells[3]:UpdateNumber(nil, false)
        else
            self._cells[3]:SetVisible(false)
        end
    end
    if skipUpdateEnd then
        return
    end
end

---@param entity wds.Alliance
function AllianceMainNotifyPopupComponent:OnAllianceMarkChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local num = table.nums(entity.AllianceMessage.MapLabels)
    self._cells[2]:SetVisible(num > 0)
    if num > 0 then
        local node = ModuleRefer.NotificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.LabelEntry, NotificationType.ALLIANCE_LABEL_ENTRY)
        self._cells[2]:UpdateNumber(num, node and node.NotificationCount > 0)
    end
end

return AllianceMainNotifyPopupComponent