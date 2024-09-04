local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local AllianceCurrencyType = require("AllianceCurrencyType")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class HudAllianceCurrencyCell:BaseTableViewProCell
---@field new fun():HudAllianceCurrencyCell
---@field super BaseTableViewProCell
local HudAllianceCurrencyCell = class('HudAllianceCurrencyCell', BaseTableViewProCell)

function HudAllianceCurrencyCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._currencyId = nil
    self._eventsAdd = false
end

function HudAllianceCurrencyCell:OnCreate(param)
    self.animTrigger = self:AnimTrigger("")
    self.imgGroupResource1 = self:GameObject('p_group_resource_1')
    self.imgIconItem1 = self:Image('p_icon_item_1')
    self.imgGroupResource2 = self:GameObject('p_group_resource_2')
    self.imgGroupResource3 = self:GameObject('p_group_resource_3')
    
    self.textQuantity = self:Text('p_text_quantity')
    self.goEffect = self:GameObject('vx_effect_1')
    self.goEffect:SetActive(false)

    self.imgGroupResource1:SetVisible(true)
    self.imgGroupResource2:SetVisible(false)
    self.imgGroupResource3:SetVisible(false)
end

function HudAllianceCurrencyCell:OnFeedData(param)
    self._currencyId = param.id
    self:RefreshCount()
    local cfg = ConfigRefer.AllianceCurrency:Find(self._currencyId)
    g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgIconItem1)
    self:SetupEvents(true)
end

function HudAllianceCurrencyCell:OnRecycle(param)
    self:SetupEvents(false)
end

function HudAllianceCurrencyCell:OnClose(param)
    self:SetupEvents(false)
end

function HudAllianceCurrencyCell:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnCurrencyUpdate))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnCurrencyUpdate))
    end
end

function HudAllianceCurrencyCell:OnCurrencyUpdate(idMap)
    if not self._currencyId or not idMap[self._currencyId] then
        return
    end
    self:RefreshCount()
end

function HudAllianceCurrencyCell:RefreshCount()
    local currentNum = ModuleRefer.AllianceModule:GetAllianceCurrencyById(self._currencyId)
    local type = ModuleRefer.AllianceModule:GetAllianceCurrencyTypeById(self._currencyId)
    if type == AllianceCurrencyType.Fund then
        self.textQuantity.text = NumberFormatter.NumberAbbr(currentNum)
        return
    end
    local maxCount = ModuleRefer.AllianceModule:GetAllianceCurrencyMaxCountById(self._currencyId)
    self.textQuantity.text = NumberFormatter.NumberAbbr(math.floor(currentNum)) .. '/' .. NumberFormatter.NumberAbbr(math.floor(maxCount))
end

return HudAllianceCurrencyCell