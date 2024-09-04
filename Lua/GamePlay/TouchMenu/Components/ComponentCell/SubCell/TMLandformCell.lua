local BaseTableViewProCell = require ('BaseTableViewProCell')
local UIMediatorNames = require('UIMediatorNames')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TMLandformCellData
---@field landCfgId number

---@class TMLandformCell:BaseTableViewProCell
---@field new TMLandformCell
---@field super BaseTableViewProCell
local TMLandformCell = class('TMLandformCell', BaseTableViewProCell)

function TMLandformCell:OnCreate()
    self.imgLandform = self:Image("p_icon_landform")
    self.btnClick = self:Button('', Delegate.GetOrCreate(self, self.OnClick))
end

---@param data TMLandformCellData
function TMLandformCell:OnFeedData(data)
    self.data = data
    self.landCfgCell = ConfigRefer.Land:Find(data.landCfgId)

    g_Game.SpriteManager:LoadSprite(self.landCfgCell:IconAutoPet(), self.imgLandform)
end

function TMLandformCell:OnClick()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end

return TMLandformCell