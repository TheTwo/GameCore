local CityStoreroomUIGridItem = require("CityStoreroomUIGridItem")
---@class CityStoreroomUIGridFoodItem:CityStoreroomUIGridItem
local CityStoreroomUIGridFoodItem = class('CityStoreroomUIGridFoodItem', CityStoreroomUIGridItem)

function CityStoreroomUIGridFoodItem:OnCreate()
    CityStoreroomUIGridItem.OnCreate(self)
    self._p_sum_blood = self:GameObject("p_sum_blood")
    self._p_text_sum = self:Text("p_text_sum")
end

---@param data CityStoreroomUIGridItemData
function CityStoreroomUIGridFoodItem:OnFeedData(data)
    CityStoreroomUIGridItem.OnFeedData(self, data)
    self._p_sum_blood:SetActive(data:ShowBlood())
    if data:ShowBlood() then
        self._p_text_sum.text = data:GetBloodValue()
    end
end

return CityStoreroomUIGridFoodItem