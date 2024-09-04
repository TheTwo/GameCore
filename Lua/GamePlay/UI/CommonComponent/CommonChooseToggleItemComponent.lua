local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')

---@class CommonChooseToggleItemComponent : BaseUIComponent
local CommonChooseToggleItemComponent = class('CommonChooseToggleItemComponent', BaseUIComponent)

---@class CommonChooseToggleItemParam
---@field filterType number
---@field chooseType number
---@field subFilterData SubFilterParam

function CommonChooseToggleItemComponent:OnCreate()

    self.goToggleDot = self:GameObject('child_toggle_dot')
    self.btnToggleDot = self:Button('child_toggle_dot', Delegate.GetOrCreate(self, self.OnToggleDotClick))
    self.compToggleDot = self:BindComponent('child_toggle_dot', typeof(CS.StatusRecordParent))

    self.goToggleSet = self:GameObject('child_toggle_set')
    self.btnToggleSet = self:Button('child_toggle_set', Delegate.GetOrCreate(self, self.OnToggleSetClick))
    self.compToggleSet = self:BindComponent('child_toggle_set', typeof(CS.StatusRecordParent))

    self.textStatus = self:Text('p_text_status')
    self.goIcon = self:GameObject('p_icon')
    self.imgIcon = self:Image('p_icon_status')
end

---@param param CommonChooseToggleItemParam
function CommonChooseToggleItemComponent:OnFeedData(param)
    if not param then
        return
    end
    self.isSelect = false
    self.filterType = param.filterType
    self.subFilterData = param.subFilterData
    self.chooseType = param.chooseType
    if self.subFilterData.color then
        self.textStatus.text = UIHelper.GetColoredText(I18N.Get(self.subFilterData.name), self.subFilterData.color)
    else
        self.textStatus.text = I18N.Get(self.subFilterData.name)
    end
    self:InitToggleStyle()
    self:SetSelectState(self.subFilterData.isSelect and self.subFilterData.isSelect or false)
    self:SetIcon()
end

function CommonChooseToggleItemComponent:OnToggleDotClick()
    if self.isSelect then
        return
    end
    self:SetSelectState(not self.isSelect)
    g_Game.EventManager:TriggerEvent(EventConst.CHOOSE_TOGGLE_DOT_CLICK, self.filterType, self.subFilterData.subTypeIndex)
end

function CommonChooseToggleItemComponent:OnToggleSetClick()
    self:SetSelectState(not self.isSelect)
end

function CommonChooseToggleItemComponent:SetSelectState(isSelect)
    self.isSelect = isSelect
    if self.chooseType == CommonChoosePopupDefine.ChooseType.Single then
        self.compToggleDot:SetState(isSelect and 1 or 0)
    elseif self.chooseType == CommonChoosePopupDefine.ChooseType.Multiple then
        self.compToggleSet:SetState(isSelect and 1 or 0)
    end
end

function CommonChooseToggleItemComponent:InitToggleStyle()
    if self.subFilterData.chooseStyle == CommonChoosePopupDefine.ChooseStyle.Dot then
        self.goToggleDot:SetActive(true)
        self.goToggleSet:SetActive(false)
    elseif self.subFilterData.chooseStyle == CommonChoosePopupDefine.ChooseStyle.Tick then
        self.goToggleDot:SetActive(false)
        self.goToggleSet:SetActive(true)
    end
end

function CommonChooseToggleItemComponent:GetFilterType()
    return self.filterType
end

function CommonChooseToggleItemComponent:GetSubFilterType()
    return self.subFilterData.subTypeIndex
end

function CommonChooseToggleItemComponent:Reset()
    self:SetSelectState(self.subFilterData.isSelect)
end

function CommonChooseToggleItemComponent:IsSelected()
    return self.isSelect
end

function CommonChooseToggleItemComponent:SetIcon()
    if self.subFilterData.icon and not string.IsNullOrEmpty(self.subFilterData.icon) then
        self.goIcon:SetActive(true)
        g_Game.SpriteManager:LoadSprite(self.subFilterData.icon, self.imgIcon)
    else
        self.goIcon:SetActive(false)
    end
end

return CommonChooseToggleItemComponent