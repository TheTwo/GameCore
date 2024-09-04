local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local EquipSingleCell = class('EquipSingleCell',BaseTableViewProCell)

function EquipSingleCell:OnCreate(param)
    self.imgSuitEquip = self:Image('p_btn_suit_equip')
    self.btnSuitEquip = self:Button('p_btn_suit_equip', Delegate.GetOrCreate(self, self.OnBtnSuitEquipClicked))
    self.imgEquip = self:Image('p_btn_equip')
    self.btnEquip = self:Button('p_btn_equip', Delegate.GetOrCreate(self, self.OnBtnEquipClicked))
end

function EquipSingleCell:OnFeedData(data)
    if not data then
        return
    end
    self.suitId = data.suitId
    self.equipId = data.equipId
    local suitCfg = ConfigRefer.Suit:Find(self.suitId)
    self:LoadSprite(suitCfg:Icon(), self.imgSuitEquip)
    local equipCfg = ConfigRefer.HeroEquip:Find(self.equipId)
    self:LoadSprite(equipCfg:Icon(), self.imgEquip)
end

function EquipSingleCell:OnBtnSuitEquipClicked(args)
    local suitCfg = ConfigRefer.Suit:Find(self.suitId)
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnSuitEquip.transform, content = I18N.Get(suitCfg:Desc())})
end
function EquipSingleCell:OnBtnEquipClicked(args)
    local param = {}
    param.clickTransform = self.btnEquip.transform
    param.equipId = self.equipId
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
    g_Game.UIManager:Open('PopupItemDetailsUIMediator', param)
end

return EquipSingleCell
