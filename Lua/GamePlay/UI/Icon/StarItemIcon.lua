local BaseUIComponent = require ('BaseUIComponent')

---@class StarItemIcon:BaseUIComponent
local StarItemIcon = class('StarItemIcon', BaseUIComponent)

---@class StarItemIconData
---@field itemIconData ItemIconData
---@field starCount number

function StarItemIcon:OnCreate()
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    self._p_star = self:GameObject("p_star")
    self._img_star_1 = self:GameObject("img_star_1")
    self._img_star_2 = self:GameObject("img_star_2")
    self._img_star_3 = self:GameObject("img_star_3")
    self._img_star_4 = self:GameObject("img_star_4")
    self._img_star_5 = self:GameObject("img_star_5")
end

---@param data StarItemIconData
function StarItemIcon:OnFeedData(data)
    self._data = data
    self._child_item_standard_s:FeedData(data.itemIconData)

    self._p_star:SetActive(data.starCount > 0)
    if data.starCount > 0 then
        self._img_star_1:SetActive(data.starCount >= 1)
        self._img_star_2:SetActive(data.starCount >= 2)
        self._img_star_3:SetActive(data.starCount >= 3)
        self._img_star_4:SetActive(data.starCount >= 4)
        self._img_star_5:SetActive(data.starCount >= 5)
    end
end

return StarItemIcon