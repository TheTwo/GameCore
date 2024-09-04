local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SEBattleBuffIconCellData
---@field iconPath string

---@class SEBattleBuffIconCell:BaseTableViewProCell
---@field new fun():SEBattleBuffIconCell
---@field super BaseTableViewProCell
local SEBattleBuffIconCell = class('ReplicaPVPChallengeCell', BaseTableViewProCell)

function SEBattleBuffIconCell:OnCreate()
    self.buffIcon = self:Image('p_icon_buff')
end

---@param data SEBattleBuffIconCellData
function SEBattleBuffIconCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.iconPath, self.buffIcon)
end

return SEBattleBuffIconCell