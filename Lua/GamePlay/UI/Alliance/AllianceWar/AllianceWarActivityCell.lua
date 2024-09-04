local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityCellDataWrapper
---@field cellData AllianceActivityCellData

---@class AllianceWarActivityCell:BaseTableViewProCell
---@field super AllianceWarActivityCell
---@field new fun():AllianceWarActivityCell
local AllianceWarActivityCell = class("AllianceWarActivityCell", BaseTableViewProCell)

function AllianceWarActivityCell:ctor()
    AllianceWarActivityCell.super.ctor(self)
    self._cellEventAdd = false
end

function AllianceWarActivityCell:OnCreate()
    self._p_icon_event = self:Image("p_icon_event")
    self._p_base_icon_1 = self:GameObject("p_base_icon_1")
    self._p_icon_event_type = self:Image("p_icon_event_type")
    self._p_text_event_name = self:Text("p_text_event_name")
    self._p_icon_position = self:GameObject("p_icon_position")
    self._p_text_position_player = self:Text("p_text_position_player")
    self._p_btn_position = self:Button("p_btn_position", Delegate.GetOrCreate(self, self.OnClickBtnPosition))
    self._p_text_event_desc = self:Text("p_text_event_desc")
    self._p_text_event_status_desc_1 = self:Text("p_text_event_status_desc_1")
    self._p_progress_event = self:Slider("p_progress_event")
    self._p_text_event_progress = self:Text("p_text_event_progress")
    self._p_text_event_status_desc_2 = self:Text("p_text_event_status_desc_2")
    self._p_my = self:GameObject("p_my")
    self._p_text_my_status = self:Text("p_text_my_status")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGoto))
end

function AllianceWarActivityCell:ResetCell()
    self._p_icon_event:SetVisible(true)
    self._p_base_icon_1:SetVisible(true)
    self._p_text_event_name:SetVisible(true)
    self._p_text_event_desc:SetVisible(true)
    self._p_icon_position:SetVisible(false)
    self._p_progress_event:SetVisible(false)
    self._p_text_event_status_desc_1:SetVisible(false)
    self._p_text_event_status_desc_2:SetVisible(false)
    self._p_my:SetVisible(false)
    self._p_btn_goto:SetVisible(false)
end

---@param data AllianceActivityCellDataWrapper
function AllianceWarActivityCell:OnFeedData(data)
    self._data = data
    data.cellData:OnCellEnter(self)
    self:SetupEvent(true)
end

function AllianceWarActivityCell:OnRecycle()
    if self._data then
        self:SetupEvent(false)
        self._data.cellData:OnCellExit(self)
    end
    self._data = nil
end

function AllianceWarActivityCell:OnClose()
    if self._data then
        self:SetupEvent(false)
        self._data.cellData:OnCellExit(self)
    end
    self._data = nil
end

function AllianceWarActivityCell:SetupEvent(add)
    if add and not self._cellEventAdd then
        self._cellEventAdd = true
        if self._data then
            self._data.cellData:SetupEvent(true)
        end
    elseif not add and self._cellEventAdd then
        self._cellEventAdd = false
        if self._data then
            self._data.cellData:SetupEvent(false)
        end
    end
end

function AllianceWarActivityCell:OnClickBtnPosition()
    if self._data then
        self._data.cellData:OnClickBtnPosition()
    end
end

function AllianceWarActivityCell:OnClickBtnGoto()
    if self._data then
        self._data.cellData:OnClickBtnGoto()
    end
end

return AllianceWarActivityCell