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

---@class CityFurnitureUnlockPetCell : BaseTableViewProCell
local CityFurnitureUnlockPetCell = class('CityFurnitureUnlockPetCell', BaseTableViewProCell)

function CityFurnitureUnlockPetCell:OnCreate()
    ---@type CommonPetIconBase
    self.child_card_pet_s = self:LuaObject("child_card_pet_s")
end

function CityFurnitureUnlockPetCell:OnShow()
end

function CityFurnitureUnlockPetCell:OnHide()

end

function CityFurnitureUnlockPetCell:OnFeedData(param)
    local petCfgId = ConfigRefer.PetType:Find(param.petTypeId):SamplePetCfg()
    ---@type CommonPetIconBaseData
    local petData = {cfgId = petCfgId}
    self.child_card_pet_s:FeedData(petData)
end

function CityFurnitureUnlockPetCell:OnBtnGotoClick()
end

return CityFurnitureUnlockPetCell
