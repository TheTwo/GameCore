local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceTaskOperationParameter = require('AllianceTaskOperationParameter')
local TimeFormatter = require('TimeFormatter')
local EventConst = require('EventConst')

---@class CityFurnitureUnlockLandCell : BaseTableViewProCell
local CityFurnitureUnlockLandCell = class('CityFurnitureUnlockLandCell', BaseTableViewProCell)

function CityFurnitureUnlockLandCell:OnCreate()
    self.p_img_landform = self:Image("p_img_landform")
end

function CityFurnitureUnlockLandCell:OnShow()
end

function CityFurnitureUnlockLandCell:OnHide()

end

function CityFurnitureUnlockLandCell:OnFeedData(param)
    g_Game.SpriteManager:LoadSprite(param.sprite, self.p_img_landform)
end

function CityFurnitureUnlockLandCell:OnBtnGotoClick()
end

return CityFurnitureUnlockLandCell
