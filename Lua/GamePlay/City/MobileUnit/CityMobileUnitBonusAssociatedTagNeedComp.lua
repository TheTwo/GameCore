local BaseUIComponent = require ('BaseUIComponent')

---@class CityMobileUnitBonusAssociatedTagNeedComp:BaseUIComponent
local CityMobileUnitBonusAssociatedTagNeedComp = class('CityMobileUnitBonusAssociatedTagNeedComp', BaseUIComponent)
local Delegate = require("Delegate")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")

function CityMobileUnitBonusAssociatedTagNeedComp:OnCreate()
    ---@type UIHeroAssociateIconComponent
    self._child_icon_style = self:LuaObject("child_icon_style")
    self._p_text_style_number = self:Text("p_text_style_number")
    self._p_img_check_style = self:GameObject("p_img_check_style")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data {param:CityMobileUnitUIParameter, condition:EfficiencyCondition}
function CityMobileUnitBonusAssociatedTagNeedComp:OnFeedData(data)
    self.data = data
    local tagId = data.condition:EfficiencyConditionLeftValue()
    self._child_icon_style:FeedData({tagId = tagId})
    local leftValue = data.param:GetAssociatedTagInfoPetCount(tagId)
    local rightValue = data.condition:EfficiencyConditionRightValue()
    self._p_text_style_number.text = string.format("%d/%d", leftValue, rightValue)
    self._p_img_check_style:SetActive(leftValue >= rightValue)
end

function CityMobileUnitBonusAssociatedTagNeedComp:OnClick()
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = self._button.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local associatedTagCfg = ConfigRefer.AssociatedTag:Find(self.data.condition:EfficiencyConditionLeftValue())
    tipParameter.text = I18N.GetWithParams("hot_spring_condition02", I18N.Get(associatedTagCfg:Name()), self.data.condition:EfficiencyConditionRightValue())
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

return CityMobileUnitBonusAssociatedTagNeedComp