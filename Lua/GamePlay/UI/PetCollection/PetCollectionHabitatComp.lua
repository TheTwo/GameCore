local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local GuideUtils = require('GuideUtils')
local PetCollectionHabitatComp = class('PetCollectionHabitatComp', BaseTableViewProCell)
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local ConfigRefer = require("ConfigRefer")

function PetCollectionHabitatComp:OnCreate()
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnClickToast))
    self.p_icon_habitat = self:Image('p_icon_habitat')
end

function PetCollectionHabitatComp:OnShow()

end

function PetCollectionHabitatComp:OnHide()
end

function PetCollectionHabitatComp:OnFeedData(param)
    self.Land = param.land
    self.param = param
    g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon_habitat)
end

function PetCollectionHabitatComp:OnClickToast()
    ---@type CatchPetLandformTipParameter
    local param = {}
    param.landCfgId = self.Land
    param.needGoto = true

    -- 特殊处理 VIP宠物栖息地按钮
    if self.param.index == 8 then
        param.content = I18N.Get("pet_handbook_special_des")
        param.title = I18N.Get('pet_handbook_area_7_name')
        param.needGoto = false
        param.hideAll = true
    end
    g_Game.UIManager:Open(UIMediatorNames.CatchPetLandformTip, param)
end
return PetCollectionHabitatComp
