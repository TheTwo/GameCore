local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Utils = require('Utils')
---@class PopUpTabCell : BaseTableViewProCell
local PopUpTabCell = class('PopUpTabCell',BaseTableViewProCell)

---@class PopUpTabCellParam
---@field popId number
---@field childName string
---@field isShop boolean
---@field forceUpdate boolean

function PopUpTabCell:OnCreate()
    self.btnTab = self:Button('p_btn_tab', Delegate.GetOrCreate(self, self.OnBtnTabClicked))
    self.textName = self:Text('p_text_tab')
    self.textTime = self:Text('p_text_tab_time')
    self.goSelect = self:GameObject('p_img_select')
    self.goTips = self:GameObject('tips_fade')
    self.textTips = self:Text('p_text_fade')
end

function PopUpTabCell:OnFeedData(param)
    self.popId = param.popId
    self.forceUpdate = param.forceUpdate
    local popCfg = ConfigRefer.PopUpWindow:Find(self.popId)
    local pGroupId = popCfg:PayGroup()
    local group = ConfigRefer.PayGoodsGroup:Find(pGroupId)
    self.textName.text = I18N.Get(group:Name())
end

function PopUpTabCell:OnBtnTabClicked(args)
    if Utils.IsNull(self.CSComponent) then return end
    self:SelectSelf()
end

function PopUpTabCell:Select()
    if Utils.IsNull(self.CSComponent) then return end
    self.goSelect:SetActive(true)
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_POPUP_TAB, self.popId, self.forceUpdate)
end

function PopUpTabCell:UnSelect()
    if Utils.IsNull(self.CSComponent) then return end
    self.goSelect:SetActive(false)
end

return PopUpTabCell