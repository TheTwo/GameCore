local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SEClimbTowerSectionMonsterCellData
---@field iconId number

---@class SEClimbTowerSectionMonsterCell:BaseTableViewProCell
---@field new fun():SEClimbTowerSectionMonsterCell
---@field super BaseTableViewProCell
local SEClimbTowerSectionMonsterCell = class('SEClimbTowerSectionMonsterCell', BaseTableViewProCell)

function SEClimbTowerSectionMonsterCell:OnCreate()
    self.imgMonster = self:Image('p_img_monster')
end

---@param data SEClimbTowerSectionMonsterCellData
function SEClimbTowerSectionMonsterCell:OnFeedData(data)
    self:LoadSprite(data.iconId, self.imgMonster)
end

return SEClimbTowerSectionMonsterCell