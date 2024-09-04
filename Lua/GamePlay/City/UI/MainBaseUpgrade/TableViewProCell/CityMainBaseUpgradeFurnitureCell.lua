local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityMainBaseUpgradeFurnitureCell:BaseTableViewProCell
local CityMainBaseUpgradeFurnitureCell = class('CityMainBaseUpgradeFurnitureCell', BaseTableViewProCell)

function CityMainBaseUpgradeFurnitureCell:OnCreate()
    self._p_table = self:TableViewPro("")
    self._trigger = self:AnimTrigger("")
end

---@param data {lvCfg:NewBaseUpgradeUIDataConfigCell}
function CityMainBaseUpgradeFurnitureCell:OnFeedData(data)
    local lvCfg = data.lvCfg
    self._p_table:Clear()
    for i = 1, lvCfg:FurnitureLevelMapLength() do
        local data = lvCfg:FurnitureLevelMap(i)
        self._p_table:AppendData(data)
    end
end

return CityMainBaseUpgradeFurnitureCell