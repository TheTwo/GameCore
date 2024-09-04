local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TMCellRewardCellImage:BaseTableViewProCell
local TMCellRewardCellImage = class('TMCellRewardCellImage', BaseTableViewProCell)

function TMCellRewardCellImage:OnCreate()
    self._p_img = self:Image("p_img")
end

---@param data string
function TMCellRewardCellImage:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data, self._p_img)
end

return TMCellRewardCellImage