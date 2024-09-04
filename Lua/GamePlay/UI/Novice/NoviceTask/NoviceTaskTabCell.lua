local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local NoviceConst = require('NoviceConst')
local NotificationType = require('NotificationType')
local I18N = require('I18N')
---@class NoviceTaskTabCell : BaseTableViewProCell
local NoviceTaskTabCell = class('NoviceTaskTabCell', BaseTableViewProCell)

---@class NoviceTaskTabCellData
---@field day number
---@field thisDay number
---@field isLocked boolean
---@field textI18N string

local STATUS = {
    selected = 1,
    unselected = 2,
    locked = 3,
    length = 3
}

local TabBaseImgs = {
    [1] = {
        [STATUS.selected] = "sp_common_btn_tab_arrow_01",
        [STATUS.unselected] = "sp_common_btn_tab_arrow_02",
        [STATUS.locked] = "sp_common_btn_tab_arrow_02",
    },
    [0] = {
        [STATUS.selected] = "sp_common_btn_tab_arrow_03",
        [STATUS.unselected] = "sp_common_btn_tab_arrow_04",
        [STATUS.locked] = "sp_common_btn_tab_arrow_04",
    },
    [NoviceConst.MAX_DAY] = {
        [STATUS.selected] = "sp_common_btn_tab_arrow_05",
        [STATUS.unselected] = "sp_common_btn_tab_arrow_06",
        [STATUS.locked] = "sp_common_btn_tab_arrow_06",
    }
}

function NoviceTaskTabCell:OnCreate()
    self.goStatus = {
        self:GameObject('p_base_a'),
        self:GameObject('p_base_b'),
        self:GameObject('p_base_c'),
    }
    self.texts = {
        self:Text('p_text_a'),
        self:Text('p_text_b'),
        self:Text('p_text_c'),
    }
    self.imgBase = {
        self:Image('p_base_1'),
        self:Image('p_base_2'),
        self:Image('p_base_3'),
    }
    self.btnSelf = self:Button('child_tab_bottom_btn', Delegate.GetOrCreate(self, self.OnBtnSelfClicked))
    self.notificationNode = self:LuaObject('child_reddot_default')
end

---@param param NoviceTaskTabCellData
function NoviceTaskTabCell:OnFeedData(param)
    if not param then
        return
    end
    for _, text in ipairs(self.texts) do
        text.text = I18N.GetWithParams(param.textI18N, param.day)
    end
    self.day = param.day
    self.thisDay = param.thisDay
    self.isLocked = param.isLocked
    if self.isLocked then
        self:SetStatus(STATUS.locked)
    elseif self.day == self.thisDay then
        self:SelectSelf()
    end
    self:SetImageBase(self.day)
    local notificationNode = ModuleRefer.NotificationModule:GetDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NoviceDayTab .. self.day, NotificationType.NOVICE_DAY_TAB)
    ModuleRefer.NotificationModule:AttachToGameObject(notificationNode, self.notificationNode.go, self.notificationNode.redDot)
end

function NoviceTaskTabCell:SetStatus(status)
    for i = 1, STATUS.length do
        self.goStatus[i]:SetActive(i == status)
    end
end

function NoviceTaskTabCell:SetImageBase(day)
    if day > 1 and day < NoviceConst.MAX_DAY then
        day = 0
    end
    for i = 1, STATUS.length do
        g_Game.SpriteManager:LoadSprite(TabBaseImgs[day][i], self.imgBase[i])
    end
end

function NoviceTaskTabCell:Select(param)
    self:SetStatus(STATUS.selected)
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_NOVICE_TASK_TAB, self.day)
end

function NoviceTaskTabCell:UnSelect(param)
    if self.isLocked then
        return
    end
    self:SetStatus(STATUS.unselected)
end

function NoviceTaskTabCell:OnBtnSelfClicked(args)
    if self.isLocked then
        local count = ModuleRefer.NoviceModule:GetUnlockLeftDayCount(self.day)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(NoviceConst.I18NKeys.TAB_LOCK_TIP, count))
        return
    end
    self:SelectSelf()
end

return NoviceTaskTabCell