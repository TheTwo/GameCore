local BaseUIComponent = require ('BaseUIComponent')

---@class CityMobileUnitBonusWorkTypeSumNeedComp:BaseUIComponent
local CityMobileUnitBonusWorkTypeSumNeedComp = class('CityMobileUnitBonusWorkTypeSumNeedComp', BaseUIComponent)
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CityPetUtils = require("CityPetUtils")

function CityMobileUnitBonusWorkTypeSumNeedComp:OnCreate()
    self._p_icon_type = self:Image("p_icon_type")
    self._p_text_type_number = self:Text("p_text_type_number")
    self._p_img_check_type = self:GameObject("p_img_check_type")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data {param:CityMobileUnitUIParameter, condition:EfficiencyCondition}
function CityMobileUnitBonusWorkTypeSumNeedComp:OnFeedData(data)
    self.data = data
    local petWorkType = data.condition:EfficiencyConditionLeftValue()
    g_Game.SpriteManager:LoadSprite(data.param.city.petManager:GetFeatureIcon(petWorkType), self._p_icon_type)
    local leftValue = data.param:GetPetWorkTypeLevelSum(petWorkType)
    local rightValue = data.condition:EfficiencyConditionRightValue()
    self._p_text_type_number.text = string.format("%d/%d", leftValue, rightValue)
    self._p_img_check_type:SetActive(leftValue >= rightValue)
end

function CityMobileUnitBonusWorkTypeSumNeedComp:OnClick()
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = self._button.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.GetWithParams("hot_spring_condition03", CityPetUtils.GetFeatureName(self.data.condition:EfficiencyConditionLeftValue()), self.data.condition:EfficiencyConditionRightValue())
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

return CityMobileUnitBonusWorkTypeSumNeedComp