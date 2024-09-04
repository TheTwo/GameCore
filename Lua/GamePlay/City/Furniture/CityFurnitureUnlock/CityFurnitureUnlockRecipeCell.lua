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

---@class CityFurnitureUnlockRecipeCell : BaseTableViewProCell
local CityFurnitureUnlockRecipeCell = class('CityFurnitureUnlockRecipeCell', BaseTableViewProCell)

function CityFurnitureUnlockRecipeCell:OnCreate()
    self.p_img_recipe = self:Image("p_img_recipe")
end

function CityFurnitureUnlockRecipeCell:OnShow()
end

function CityFurnitureUnlockRecipeCell:OnHide()

end

function CityFurnitureUnlockRecipeCell:OnFeedData(param)
    g_Game.SpriteManager:LoadSprite(param.sprite, self.p_img_recipe)

end

function CityFurnitureUnlockRecipeCell:OnBtnGotoClick()
end

return CityFurnitureUnlockRecipeCell
