local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local BattlePassConst = require('BattlePassConst')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require('NotificationType')
---@class BattlePassTaskTab : BaseUIComponent
local BattlePassTaskTab = class('BattlePassTaskTab', BaseUIComponent)

---@class BattlePassTaskTabParam
---@field tabType number
---@field onClick fun(tabType:number)

function BattlePassTaskTab:OnCreate()
    self.goOff = self:GameObject('p_off')
    self.textOff = self:Text('p_text_off')
    self.goOn = self:GameObject('p_on')
    self.textOn = self:Text('p_text_on')
    self.btn = self:Button('p_btn_off', Delegate.GetOrCreate(self, self.OnBtnClicked))
    self.reddot = self:LuaObject('child_reddot_default')
end

---@param param BattlePassTaskTabParam
function BattlePassTaskTab:OnFeedData(param)
    self.tabType = param.tabType
    self.onClick = param.onClick
    self.textOff.text = I18N.Get(BattlePassConst.TASK_TAB_NAME_I18NKEY[self.tabType])
    self.textOn.text = I18N.Get(BattlePassConst.TASK_TAB_NAME_I18NKEY[self.tabType])
    local reddotNode = ModuleRefer.NotificationModule:GetDynamicNode(BattlePassConst.NOTIFY_NAMES.TASK .. self.tabType, NotificationType.BATTLEPASS_TASK_SUB)
    ModuleRefer.NotificationModule:AttachToGameObject(reddotNode, self.reddot.go, self.reddot.redDot)
end

function BattlePassTaskTab:SetToggleActive(shouldShow)
    self.goOff:SetActive(not shouldShow)
    self.goOn:SetActive(shouldShow)
end

function BattlePassTaskTab:OnBtnClicked()
    if self.onClick then
        self.onClick(self.tabType)
    end
end

return BattlePassTaskTab