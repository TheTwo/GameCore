local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ProgressType = require('ProgressType')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityPath = require('DBEntityPath')

---@class WorldEventRecordMediator : BaseUIMediator
local WorldEventRecordMediator = class('WorldEventRecordMediator', BaseUIMediator)


function WorldEventRecordMediator:OnCreate()
    self.textWorldEventTitle = self:Text('p_text_title', I18N.Get("Worldexpedition_joined"))
    self.tableviewproTableContent = self:TableViewPro('p_table')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnClickClose))

    self.btnNearbyEventsTab = self:Button('p_btn_events_nearby', Delegate.GetOrCreate(self, self.OnClickNearbyTab))
    self.goNearbyNormal = self:GameObject('p_status_nearby_n')
    self.textNearbyNormal = self:Text('p_text_nearby_n', I18N.Get("WorldExpedition_info_nearby"))
    self.goNearbySelect = self:GameObject('p_status_nearby_select')
    self.textNearbySelect = self:Text('p_text_nearby_select', I18N.Get("WorldExpedition_info_nearby"))

    self.btnAttenedEventsTab = self:Button('p_btn_events_attended', Delegate.GetOrCreate(self, self.OnClickAttenedTab))
    self.goAttenedNormal = self:GameObject('p_status_attended_n')
    self.textAttenedNormal = self:Text('p_text_attended_n', I18N.Get("WorldExpedition_info_attended"))
    self.goAttenedSelect = self:GameObject('p_status_attended_select')
    self.textAttenedSelect = self:Text('p_text_attended_select', I18N.Get("WorldExpedition_info_attended"))
    self.myLod = 0
end


function WorldEventRecordMediator:OnShow()
    KingdomMapUtils.GetKingdomScene():AddLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_CHANGEED, Delegate.GetOrCreate(self, self.RefreshRecord))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.OverExpeditions.MsgPath, Delegate.GetOrCreate(self, self.RefreshRecord))
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_RECORD_UI_STATE_CHANGEED, false)
    g_Game.EventManager:TriggerEvent(EventConst.CHANG_TOAST_SHOW_TYPE, 2)
    self:SelectTab(2)
end

function WorldEventRecordMediator:OnHide()
    KingdomMapUtils.GetKingdomScene():RemoveLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_CHANGEED, Delegate.GetOrCreate(self, self.RefreshRecord))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.OverExpeditions.MsgPath, Delegate.GetOrCreate(self, self.RefreshRecord))
    if self.myLod < 4 then
        g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_RECORD_UI_STATE_CHANGEED, true)
    end
    g_Game.EventManager:TriggerEvent(EventConst.CHANG_TOAST_SHOW_TYPE, 1)
end

function WorldEventRecordMediator:RefreshRecord()
    self.tableviewproTableContent:Clear()
    if self.tabIndex == 1 then
        self:RefreshNearbyEvents()
    elseif self.tabIndex == 2 then
        self:RefreshAttendedEvents()
    end
end

function WorldEventRecordMediator:OnClickClose()
    self.tableviewproTableContent:Clear()
    self:CloseSelf()
end

function WorldEventRecordMediator:OnLodChanged(oldLod, newLod)
    self.myLod = newLod
    if newLod >= 4 then
        self:OnClickClose()
    end
end

function WorldEventRecordMediator:OnClickNearbyTab()
    self:SelectTab(1)
end

function WorldEventRecordMediator:OnClickAttenedTab()
    self:SelectTab(2)
end

function WorldEventRecordMediator:SelectTab(index)
    if not self.tabIndex then
        self.tabIndex = 0
    end
    if self.tabIndex == index then
        return
    end
    self.tabIndex = index
    if index == 1 then
        self.goNearbyNormal:SetActive(false)
        self.goNearbySelect:SetActive(true)
        self.goAttenedNormal:SetActive(true)
        self.goAttenedSelect:SetActive(false)
    elseif index == 2 then
        self.goNearbyNormal:SetActive(true)
        self.goNearbySelect:SetActive(false)
        self.goAttenedNormal:SetActive(false)
        self.goAttenedSelect:SetActive(true)
    end
    self:RefreshRecord()
end

function WorldEventRecordMediator:RefreshNearbyEvents()

end

function WorldEventRecordMediator:RefreshAttendedEvents()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local playerExpeditions = player.PlayerWrapper2.PlayerExpeditions
    ---@type wds.PlayerExpeditionInfo[]
    local contents = {}
    local joinExpeditions = playerExpeditions.JoinExpeditions
    for k, v in pairs(joinExpeditions) do
        table.insert(contents, v)
    end
    local overExpeditions = playerExpeditions.OverExpeditions
    --未结束事件 剩余时间少的排前面
    table.sort(contents, function(l, r)
        local l_cfg = ConfigRefer.WorldExpeditionTemplate:Find(l.ExpeditionInstanceTid)
        local r_cfg = ConfigRefer.WorldExpeditionTemplate:Find(r.ExpeditionInstanceTid)
        local l_typ = l_cfg:ProgressType()
        local r_typ = r_cfg:ProgressType()

        local l_progress = l_typ == ProgressType.Personal and l.PersonalProgress or l.Progress
        local r_progress = r_typ == ProgressType.Personal and r.PersonalProgress or r.Progress
        local l_percent = math.clamp(l_progress / l_cfg:MaxProgress(), 0, 1)
        local r_percent = math.clamp(r_progress / r_cfg:MaxProgress(), 0, 1)
        local l_isFinish, r_isfinish = l_percent >= 1, r_percent >= 1
        if l_isFinish ~= r_isfinish then
            return r_isfinish
        end
        return l.EndTime.timeSeconds < r.EndTime.timeSeconds
    end)

    --已结束事件 完成时间早的排前面
    local contentsOver = {}
    for k, v in ipairs(overExpeditions) do
        table.insert(contentsOver, v)
    end
    local tmpOver = {}  
    for i = 1, #contentsOver do
        tmpOver[i] = table.remove(contentsOver)  
    end 
    for _, info in ipairs(contents) do
        self.tableviewproTableContent:AppendData({expeditionInfo = info, isOverEvent = false})
    end
    for i = 1, #tmpOver do
        self.tableviewproTableContent:AppendData({expeditionInfo = tmpOver[i], isOverEvent = true})
    end
end

return WorldEventRecordMediator