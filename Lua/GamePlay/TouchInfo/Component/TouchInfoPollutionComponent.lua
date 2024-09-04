local BaseUIComponent = require ('BaseUIComponent')

---@class TouchInfoPollutionComponent:BaseUIComponent
local TouchInfoPollutionComponent = class('TouchInfoPollutionComponent', BaseUIComponent)

---@class TouchInfoPollutionCompData
---@field title string
---@field name string

function TouchInfoPollutionComponent:OnCreate()
    self._p_text_pollution = self:Text("p_text_pollution")
    self._p_text_pollution_name = self:Text("p_text_pollution_name")
end

---@param data TouchInfoPollutionCompData
function TouchInfoPollutionComponent:OnFeedData(data)
    self._p_text_pollution.text = data.title
    self._p_text_pollution_name.text = data.name
end

return TouchInfoPollutionComponent