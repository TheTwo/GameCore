local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require("Delegate")
local GuideUtils = require("GuideUtils")

---@class CityBuildUpgradeConditionComp:BaseUIComponent
local CityBuildUpgradeConditionComp = class('CityBuildUpgradeConditionComp', BaseUIComponent)

function CityBuildUpgradeConditionComp:OnCreate()
    -- self.goIconN = self:GameObject('p_icon_n')
    self.goIconFinish = self:GameObject('p_icon_finish')
    self.textConditions = self:Text('p_text_conditions')
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
end

---@param data {desc:string, isFinish:boolean, gotoId:number}
function CityBuildUpgradeConditionComp:OnFeedData(data)
    self.textConditions.text = data.desc
    local isFinish = data.isFinish
    -- self.goIconN:SetActive(not isFinish)
    self.goIconFinish:SetActive(isFinish)
    self.p_btn_goto:SetVisible(data.gotoId ~= 0 and not isFinish)
    self.gotoId = data.gotoId
end

function CityBuildUpgradeConditionComp:OnClickGoto()
    if self.gotoId and self.gotoId > 0 then
        GuideUtils.GotoByGuide(self.gotoId)
    end
end

return CityBuildUpgradeConditionComp