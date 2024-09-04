local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local NoviceConst = require('NoviceConst')
---@class NoviceTaskSubTabCell : BaseTableViewProCell
local NoviceTaskSubTabCell = class('NoviceTaskSubTabCell', BaseTableViewProCell)

---@class NoviceTaskSubTabCellData
---@field index number
---@field selected boolean
---@field day number

local Status = {
    selected = 0,
    normal = 1,
    locked = 2,
}

local TextKeys = {
    "day1_1_tab_name",
    "day1_2_tab_name",
    "day1_3_tab_name",
    "day2_1_tab_name",
    "day2_2_tab_name",
    "day2_3_tab_name",
    "day3_1_tab_name",
    "day3_2_tab_name",
    "day3_3_tab_name",
    "day4_1_tab_name",
    "day4_2_tab_name",
    "day4_3_tab_name",
    "day5_1_tab_name",
    "day5_2_tab_name",
    "day5_3_tab_name",
}

function NoviceTaskSubTabCell:ctor()
end

function NoviceTaskSubTabCell:OnCreate()
    self.statusCtrler = self:StatusRecordParent("p_child_tab_2")
    self.btnRoot = self:Button("p_child_tab_2", Delegate.GetOrCreate(self, self.OnClickBtnRoot))
    self.texts = {
        [Status.selected] = self:Text("p_text_a_2"),
        [Status.normal] = self:Text("p_text_b_2"),
        [Status.locked] = self:Text("p_text_c_2"),
    }
    self.luaNotifyNode = self:LuaObject("child_reddot_default")
end

function NoviceTaskSubTabCell:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_NOVICE_REDDOT_UPDATE, Delegate.GetOrCreate(self, self.OnRedDotUpdate))
end

function NoviceTaskSubTabCell:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_NOVICE_REDDOT_UPDATE, Delegate.GetOrCreate(self, self.OnRedDotUpdate))
end

---@param param NoviceTaskSubTabCellData
function NoviceTaskSubTabCell:OnFeedData(param)
    self.index = param.index
    self.day = param.day
    for _, v in pairs(self.texts) do
        local i = (self.day - 1) * NoviceConst.MaxSubTabCount + self.index
        v.text = I18N.Get(TextKeys[i])
    end
    if param.selected then
        self:SelectSelf()
    end
    self.luaNotifyNode:SetVisible(ModuleRefer.NoviceModule:IsTaskCanClaimByDayAndType(self.day, self.index))
end

function NoviceTaskSubTabCell:Select()
    self.statusCtrler:ApplyStatusRecord(Status.selected)
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_NOVICE_TASK_SUB_TAB, nil, self.index)
end

function NoviceTaskSubTabCell:UnSelect()
    self.statusCtrler:ApplyStatusRecord(Status.normal)
end

function NoviceTaskSubTabCell:OnClickBtnRoot()
    self:SelectSelf()
end

function NoviceTaskSubTabCell:OnRedDotUpdate()
    self.luaNotifyNode:SetVisible(ModuleRefer.NoviceModule:IsTaskCanClaimByDayAndType(self.day, self.index))
end

return NoviceTaskSubTabCell