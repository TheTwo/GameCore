local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ColorConsts = require('ColorConsts')

---@class CatchPetLandformMiniIconCellData
---@field landCfgCell LandConfigCell
---@field selectLandCfgId number
---@field onClick fun()

---@class CatchPetLandformMiniIconCell:BaseTableViewProCell
---@field new fun():CatchPetLandformMiniIconCell
---@field super BaseTableViewProCell
local CatchPetLandformMiniIconCell = class('CatchPetLandformMiniIconCell', BaseTableViewProCell)

function CatchPetLandformMiniIconCell:OnCreate()
    self.imgLandform = self:Image('p_icon_landform')
    self.goSelect = self:GameObject('p_select')
    self.btnClick = self:Button('', Delegate.GetOrCreate(self, self.OnClick))
end

---@param data CatchPetLandformMiniIconCellData
function CatchPetLandformMiniIconCell:OnFeedData(data)
    self.data = data

    g_Game.SpriteManager:LoadSprite(self.data.landCfgCell:IconAutoPet(), self.imgLandform)
    self.goSelect:SetVisible(data.landCfgCell:Id() == self.data.selectLandCfgId)
end

function CatchPetLandformMiniIconCell:OnClick()
    if self.data.landCfgCell:Id() == self.data.selectLandCfgId then
        return
    end

    if self.data.onClick then
        self.data.onClick(self.data.landCfgCell)
    end
end

return CatchPetLandformMiniIconCell