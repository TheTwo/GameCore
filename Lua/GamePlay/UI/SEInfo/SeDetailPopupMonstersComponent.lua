local BaseUIComponent = require("BaseUIComponent")

---@class SeDetailPopupMonstersComponent:BaseUIComponent
---@field new fun():SeDetailPopupMonstersComponent
---@field super BaseUIComponent
local SeDetailPopupMonstersComponent = class('SeDetailPopupMonstersComponent', BaseUIComponent)

function SeDetailPopupMonstersComponent:OnCreate(param)
    self._p_table_monster = self:TableViewPro("p_table_monster")
end

---@param data SeNpcConfigCell[]
function SeDetailPopupMonstersComponent:OnFeedData(data)
    self._p_table_monster:Clear()
    for _, npcConfig in ipairs(data) do
        self._p_table_monster:AppendData(npcConfig)
    end
end

return SeDetailPopupMonstersComponent