local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkType = require("CityWorkType")
local CityFurnitureUpgradeSpeedUpHolder = require("CityFurnitureUpgradeSpeedUpHolder")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkI18N = require("CityWorkI18N")
local TimeFormatter = require("TimeFormatter")

local I18N = require("I18N")

---@class CityWorkFurnitureUpgradePopupUICell:BaseUIComponent
local CityWorkFurnitureUpgradePopupUICell = class('CityWorkFurnitureUpgradePopupUICell', BaseUIComponent)

function CityWorkFurnitureUpgradePopupUICell:OnCreate()
    ---升级中
    self._p_item_ugrade = self:GameObject("p_item_ugrade")
    self._p_img_furniture = self:Image("p_img_furniture")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
    self._p_progress = self:Slider("p_progress")
    self._p_text_time = self:Text("p_text_time")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_lv_1 = self:Text("p_text_lv_1")
    self._p_text_lv_2 = self:Text("p_text_lv_2")

    ---空闲
    self._p_item_free = self:Button("p_item_free", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_text_free = self:Text("p_text_free", CityWorkI18N.UI_FurnitureLevelUpPopup_FreeHint)

    ---可购买礼包
    self._p_item_package = self:GameObject("p_item_package")
    self._p_text_name_lock = self:Text("p_text_name_lock")
    self._child_comp_btn_e_s = self:Button("child_comp_btn_e_s", Delegate.GetOrCreate(self, self.OnClickPurchase))
    ---礼包价格
    self._p_text_e = self:Text("p_text_e")

    ---尚未购买的礼包
    self._p_item_lock = self:GameObject("p_item_lock")
end

---@param data {city:City, furnitureId:number, isUnlock:boolean, goodId:number, goodGroupId:number, canPurchase:boolean}
function CityWorkFurnitureUpgradePopupUICell:OnFeedData(data)
    self.city = data.city
    self.furnitureId = data.furnitureId
    self.isUnlock = data.isUnlock
    self.goodId = data.goodId
    self.goodGroupId = data.goodGroupId
    self.canPurchase = data.canPurchase

    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateUpgrading))
    if self.furnitureId then
        self._p_item_ugrade:SetActive(true)
        self._p_item_free:SetVisible(false)
        self._p_item_package:SetActive(false)
        self._p_item_lock:SetActive(false)

        self:UpdateUpgrading()
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateUpgrading))
    elseif self.isUnlock then
        self._p_item_ugrade:SetActive(false)
        self._p_item_free:SetVisible(true)
        self._p_item_package:SetActive(false)
        self._p_item_lock:SetActive(false)
    elseif self.canPurchase then
        self._p_item_ugrade:SetActive(false)
        self._p_item_free:SetVisible(false)
        self._p_item_package:SetActive(true)
        self._p_item_lock:SetActive(false)

        local goodCfg = ConfigRefer.PayGoods:Find(self.goodId)
        if goodCfg then
            self._p_text_name_lock.text = I18N.Get(goodCfg:Name())
        end
        local price, currency = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.goodId)
        self._p_text_e.text = string.format('%s %.2f', currency, price)
    else
        self._p_item_ugrade:SetActive(false)
        self._p_item_free:SetVisible(false)
        self._p_item_package:SetActive(false)
        self._p_item_lock:SetActive(true)
    end
end

function CityWorkFurnitureUpgradePopupUICell:OnClose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateUpgrading))
end

function CityWorkFurnitureUpgradePopupUICell:UpdateUpgrading()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
    if typCfg == nil then return end
    self._p_text_lv_1.text = furniture.furnitureCell:Level()
    self._p_text_lv_2.text = furniture.furnitureCell:Level() + 1
    g_Game.SpriteManager:LoadSprite(typCfg:Image(), self._p_img_furniture)
    self._p_text_name.text = I18N.Get(typCfg:Name())

    self.buttonData = {}
    self.buttonData.onClick = Delegate.GetOrCreate(self, self.OnClick)
    self.buttonData.buttonText = I18N.Get("Pay_FurUpTime")
    self._child_comp_btn_b:FeedData(self.buttonData)

    local progress, remainTime = self:GetProgressAndRemainTime()
    self._p_progress.value = progress
    self._p_text_time.text = TimeFormatter.SimpleFormatTime(remainTime)
end

function CityWorkFurnitureUpgradePopupUICell:TickForUpgrading()
    local progress, remainTime = self:GetProgressAndRemainTime()
    self._p_progress.value = progress
    self._p_text_time.text = TimeFormatter.SimpleFormatTime(remainTime)
end

function CityWorkFurnitureUpgradePopupUICell:OnClick()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
    local holder = CityFurnitureUpgradeSpeedUpHolder.new(furniture)
    local provider = require("CitySpeedUpGetMoreProvider").new()
    provider:SetHolder(holder)
    provider:SetItemList(itemList)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function CityWorkFurnitureUpgradePopupUICell:GetProgressAndRemainTime()
    local levelUpInfo = self.city.furnitureManager:GetFurnitureById(self.furnitureId):GetCastleFurniture().LevelUpInfo
    if levelUpInfo.TargetProgress == 0 then return 1, 0 end
    if not levelUpInfo.Working then return 1, 0 end

    local gap = self.city:GetWorkTimeSyncGap()
    local done = levelUpInfo.CurProgress + gap
    local target = levelUpInfo.TargetProgress
    return math.clamp01(done / target), math.max(0, (target - done))
end

function CityWorkFurnitureUpgradePopupUICell:OnClickPurchase()
    if not self.canPurchase then return end
    if self.goodId == 0 then return end

    ModuleRefer.ActivityShopModule:PurchaseGoods(self.goodId, nil, true)
end

function CityWorkFurnitureUpgradePopupUICell:OnClickClose()
    local uiMediator = self:GetParentBaseUIMediator()
    if uiMediator then
        uiMediator:CloseSelf()
    end
end

return CityWorkFurnitureUpgradePopupUICell