local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIHeroLocalData = require('UIHeroLocalData')
local EventConst = require("EventConst")
local HeroEquipCompareUIMediator = class('HeroEquipCompareUIMediator', BaseUIMediator)

function HeroEquipCompareUIMediator:ctor()

end

function HeroEquipCompareUIMediator:OnCreate()
    self.compChildSuitDetailEditorLeft = self:LuaBaseComponent('child_suit_detail_editor_left')
    self.compChildSuitDetailEditorRight = self:LuaBaseComponent('child_suit_detail_editor_right')
    self.btnContrast = self:Button('p_btn_contrast', Delegate.GetOrCreate(self, self.OnBtnExitClicked))
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshByInfo))
end

function HeroEquipCompareUIMediator:OnShow(param)
    self.param = param
    self:RefreshByInfo()
end

function HeroEquipCompareUIMediator:RefreshByInfo()
    local prewHeroCfgId = self.param.prewHeroCfgId
    local leftEquip = self.param.leftEquip
    local rightEquip = self.param.rightEquip

    local leftEquipAttr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(leftEquip.ID, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
    local rightEquipAttr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(rightEquip.ID, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
    local leftData = {}
    leftData.itemComponentId = leftEquip.ID
    leftData.isShowUp = leftEquipAttr.value > rightEquipAttr.value
    leftData.prewHeroCfgId = prewHeroCfgId
    self.compChildSuitDetailEditorLeft:FeedData(leftData)

    local rightData = {}
    rightData.itemComponentId = rightEquip.ID
    rightData.isShowUp = rightEquipAttr.value > leftEquipAttr.value
    rightData.prewHeroCfgId = prewHeroCfgId
    self.compChildSuitDetailEditorRight:FeedData(rightData)
end

function HeroEquipCompareUIMediator:OnBtnExitClicked()
    g_Game.UIManager:CloseByName(require('UIMediatorNames').HeroEquipCompareUIMediator)
end

function HeroEquipCompareUIMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshByInfo))
end

return HeroEquipCompareUIMediator