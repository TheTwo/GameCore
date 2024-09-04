local BaseTableViewProCell = require ('BaseTableViewProCell')
local NumberFormatter = require('NumberFormatter')

---@class CityLegoScoreCell:BaseTableViewProCell
local CityLegoScoreCell = class('CityLegoScoreCell', BaseTableViewProCell)

function CityLegoScoreCell:OnCreate()
    self._p_text_property_name = self:Text("p_text_property_name", "fur_score")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
    self._p_text_property_value_new = self:Text("p_text_property_value_new")

    self._arrow = self:GameObject("arrow")
    self._icon_score_1 = self:GameObject("icon_score_1")
end

---@param data {from:number, to:number}
function CityLegoScoreCell:OnFeedData(data)
    self._p_text_property_value_old.text = NumberFormatter.NumberAbbr(data.from)

    if data.to then
        self._arrow:SetActive(true)
        self._icon_score_1:SetActive(true)
        self._p_text_property_value_new:SetVisible(true)
        self._p_text_property_value_new.text = NumberFormatter.NumberAbbr(data.to)
    else
        self._arrow:SetActive(false)
        self._icon_score_1:SetActive(false)
        self._p_text_property_value_new:SetVisible(false)
    end
end

return CityLegoScoreCell