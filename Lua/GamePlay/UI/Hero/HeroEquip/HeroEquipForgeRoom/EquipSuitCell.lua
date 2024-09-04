local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local I18N = require('I18N')
local Delegate = require('Delegate')
local EquipSuitCell = class('EquipSuitCell',BaseTableViewProCell)

function EquipSuitCell:OnCreate(param)
    self.imgSuit = self:Image('icon_suit')
    self.btnSuit = self:Button('p_btn_suit', Delegate.GetOrCreate(self, self.OnBtnSuitClicked))
    self.img1 = self:Image('p_icon_1')
    self.btn1 = self:Button('p_btn_1', Delegate.GetOrCreate(self, self.OnBtn1Clicked))
    self.img2 = self:Image('p_icon_2')
    self.btn2 = self:Button('p_btn_2', Delegate.GetOrCreate(self, self.OnBtn2Clicked))
    self.img3 = self:Image('p_icon_3')
    self.btn3 = self:Button('p_btn_3', Delegate.GetOrCreate(self, self.OnBtn3Clicked))
    self.img4 = self:Image('p_icon_4')
    self.btn4 = self:Button('p_btn_4', Delegate.GetOrCreate(self, self.OnBtn4Clicked))
    self.img5 = self:Image('p_icon_5')
    self.btn5 = self:Button('p_btn_5', Delegate.GetOrCreate(self, self.OnBtn5Clicked))

    self.equipBtns = {self.btn1, self.btn2, self.btn3, self.btn4, self.btn5}
    self.equipImgs = {self.img1, self.img2, self.img3, self.img4, self.img5}
end

function EquipSuitCell:OnFeedData(data)
    if not data then
        return
    end
    self.suitId = data.suitId
    self.equipIds = data.equipIds
    self.typeRand = data.typeRand
    local suitCfg = ConfigRefer.Suit:Find(self.suitId)
    self:LoadSprite(suitCfg:Icon(), self.imgSuit)
    for index, equipId in ipairs(self.equipIds) do
        local equipCfg = ConfigRefer.HeroEquip:Find(equipId)
        local equipType = equipCfg:Type()
        local isShow = self.typeRand[equipType]
        self.equipBtns[equipType].gameObject:SetActive(isShow)
        if isShow then
            self:LoadSprite(equipCfg:Icon(), self.equipImgs[index])
        end
    end
end

function EquipSuitCell:OnBtnSuitClicked(args)
    local suitCfg = ConfigRefer.Suit:Find(self.suitId)
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnSuit.transform, content = I18N.Get(suitCfg:Desc())})
end
function EquipSuitCell:OnBtn1Clicked(args)
    self:ShowTips(self.equipIds[1], self.btn1.transform)
end
function EquipSuitCell:OnBtn2Clicked(args)
    self:ShowTips(self.equipIds[2], self.btn2.transform)
end
function EquipSuitCell:OnBtn3Clicked(args)
    self:ShowTips(self.equipIds[3], self.btn3.transform)
end
function EquipSuitCell:OnBtn4Clicked(args)
    self:ShowTips(self.equipIds[4], self.btn4.transform)
end
function EquipSuitCell:OnBtn5Clicked(args)
    self:ShowTips(self.equipIds[5], self.btn5.transform)
end

function EquipSuitCell:ShowTips(equipId, clickTransform)
    local param = {}
    param.clickTransform = clickTransform
    param.equipId = equipId
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
    g_Game.UIManager:Open('PopupItemDetailsUIMediator', param)
end

return EquipSuitCell
