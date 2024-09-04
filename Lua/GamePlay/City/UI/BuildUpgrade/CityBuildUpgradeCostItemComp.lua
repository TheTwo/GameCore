local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
---@class CityBuildUpgradeCostItemComp:BaseUIComponent
local CityBuildUpgradeCostItemComp = class('CityBuildUpgradeCostItemComp', BaseUIComponent)

function CityBuildUpgradeCostItemComp:OnCreate()
    self.imgIcon = self:Image('p_btn_icon')
    self.text01 = self:Text('p_text_01')
    self.text02 = self:Text('p_text_02')
    self.text03 = self:Text('p_text_03')
    self.goIconFinish = self:GameObject('icon_finish')
    self.btnAdd = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnBtnAddClicked))
    self:PointerDown("p_btn_icon", Delegate.GetOrCreate(self, self.OnPointerDown))
    self:PointerUp("p_btn_icon", Delegate.GetOrCreate(self, self.OnPointerUp))
end

---@param data CityCitizenData
function CityBuildUpgradeCostItemComp:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIcon)
    self.num2 = data.num2
    self:RefreshState(data.num1, self.num2)
    self.lackList = data.lackList
    self.itemId = data.id
    self.addListenter = data.addListenter
    if self.addListenter and self.itemId then
        ModuleRefer.InventoryModule:AddCountChangeListener(self.itemId, Delegate.GetOrCreate(self, self.RefreshNum1))
    end
end

function CityBuildUpgradeCostItemComp:OnClose()
    if self.addListenter and self.itemId then
        ModuleRefer.InventoryModule:RemoveCountChangeListener(self.itemId, Delegate.GetOrCreate(self, self.RefreshNum1))
    end
end

function CityBuildUpgradeCostItemComp:RefreshNum1()
    local num = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemId)
    self:RefreshState(num, self.num2)
end

function CityBuildUpgradeCostItemComp:RefreshState(num1, num2)
    local isEnough = num1 >= num2
    self.text01.gameObject:SetActive(isEnough)
    self.text02.gameObject:SetActive(not isEnough)
    if isEnough then
        self.text01.text = num1
    else
        self.text02.text = num1
    end
    self.text03.text = "/" .. num2
    self.goIconFinish:SetActive(isEnough)
    self.btnAdd.gameObject:SetActive(not isEnough)
end

function CityBuildUpgradeCostItemComp:OnPointerDown(args)
    if self.itemId then
        local param = {
            itemId = self.itemId,
            itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
            clickTransform = self.imgIcon.transform
        }
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    end
end

function CityBuildUpgradeCostItemComp:OnPointerUp()
    if self.itemId then
        g_Game.UIManager:CloseByName(UIMediatorNames.PopupItemDetailsUIMediator)
    end
end

function CityBuildUpgradeCostItemComp:OnBtnAddClicked(args)
    if self.lackList then
        ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
    end
end

return CityBuildUpgradeCostItemComp