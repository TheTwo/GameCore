---@class CityStoreroomUITitleData
---@field new fun():CityStoreroomUITitleData
local CityStoreroomUITitleData = class("CityStoreroomUITitleData")
local NumberFormatter = require("NumberFormatter")

---@param title string
---@param blood number
function CityStoreroomUITitleData:ctor(title, blood)
    self._title = title
    self._blood = blood;
end

function CityStoreroomUITitleData:NeedShowBlood()
    return self._blood ~= nil
end

function CityStoreroomUITitleData:GetTitle()
    return self._title
end

function CityStoreroomUITitleData:GetBloodStr()
    return NumberFormatter.NumberAbbr(self._blood, true)
end

return CityStoreroomUITitleData