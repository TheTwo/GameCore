local BaseUIComponent = require ('BaseUIComponent')

---@class CityMobileUnitBonusQualityNeedComp:BaseUIComponent
local CityMobileUnitBonusQualityNeedComp = class('CityMobileUnitBonusQualityNeedComp', BaseUIComponent)
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CityPetUtils = require("CityPetUtils")

function CityMobileUnitBonusQualityNeedComp:OnCreate()
    self._p_icon_quality = self:Image("p_icon_quality")
    self._p_text_quality_number = self:Text("p_text_quality_number")
    self._p_img_check_quality = self:GameObject("p_img_check_quality")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data {param:CityMobileUnitUIParameter, condition:EfficiencyCondition}
function CityMobileUnitBonusQualityNeedComp:OnFeedData(data)
    self.data = data
    local quality = data.condition:EfficiencyConditionLeftValue()
    local spriteName = ("sp_troop_img_state_base_%d"):format(quality + 1)
    g_Game.SpriteManager:LoadSprite(spriteName, self._p_icon_quality)
    local leftValue = data.param:GetPetQualityCount(quality)
    local rightValue = data.condition:EfficiencyConditionRightValue()
    self._p_text_quality_number.text = string.format("%d/%d", leftValue, rightValue)
    self._p_img_check_quality:SetActive(leftValue >= rightValue)
end

function CityMobileUnitBonusQualityNeedComp:OnClick()
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = self._button.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.GetWithParams("hot_spring_condition01", CityPetUtils.GetQualityName(self.data.condition:EfficiencyConditionLeftValue()), self.data.condition:EfficiencyConditionRightValue())
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

return CityMobileUnitBonusQualityNeedComp