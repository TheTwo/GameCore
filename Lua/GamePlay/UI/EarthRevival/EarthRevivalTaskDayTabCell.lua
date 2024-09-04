local BaseTableViewProCell = require("BaseTableViewProCell")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local I18N = require("I18N")
---@class EarthRevivalTaskDayTabCell : BaseTableViewProCell
local EarthRevivalTaskDayTabCell = class("EarthRevivalTaskDayTabCell", BaseTableViewProCell)

---@class EarthRevivalTaskDayTabCellData
---@field day number
---@field isLock boolean
---@field isSelect boolean
---@field isNotify boolean

local TAB_STATUS = {
    SELECT = 0,
    UNSELECT = 1,
    LOCK = 2,
}

function EarthRevivalTaskDayTabCell:OnCreate()
    self.statusCtrler = self:StatusRecordParent('')
    self.textSelect = self:Text('p_text_a')
    self.textUnselect = self:Text('p_text_b')
    self.textLock = self:Text('p_text_c')
    self.notifyNode = self:LuaObject('child_reddot_default')
    self.btnSelf = self:Button('', Delegate.GetOrCreate(self, self.OnBtnSelfClick))
end

---@param param EarthRevivalTaskDayTabCellData
function EarthRevivalTaskDayTabCell:OnFeedData(param)
    self.day = param.day
    self.isLock = param.isLock
    self.isSelect = param.isSelect
    self.isNotify = param.isNotify
    self.textSelect.text = I18N.GetWithParams("worldstage_tianshu", self.day)
    self.textUnselect.text = I18N.GetWithParams("worldstage_tianshu", self.day)
    self.textLock.text = I18N.GetWithParams("worldstage_tianshu", self.day)
    if self.isLock then
        self.statusCtrler:ApplyStatusRecord(TAB_STATUS.LOCK)
    elseif self.isSelect then
        self.statusCtrler:ApplyStatusRecord(TAB_STATUS.SELECT)
    else
        self.statusCtrler:ApplyStatusRecord(TAB_STATUS.UNSELECT)
    end
    if self.isSelect then
        self:SelectSelf()
    end
    self.notifyNode:SetVisible(self.isNotify)
end

function EarthRevivalTaskDayTabCell:Select()
    if self.isLock then return end
    self.statusCtrler:ApplyStatusRecord(TAB_STATUS.SELECT)
    g_Game.EventManager:TriggerEvent(EventConst.ON_EARTH_REVIVAL_TASK_DAY_SELECT, self.day)
end

function EarthRevivalTaskDayTabCell:UnSelect()
    if self.isLock then return end
    self.statusCtrler:ApplyStatusRecord(TAB_STATUS.UNSELECT)
end

function EarthRevivalTaskDayTabCell:OnBtnSelfClick()
    if self.isLock then return end
    self:SelectSelf()
end

return EarthRevivalTaskDayTabCell