local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ColorUtil = require('ColorUtil')
local Delegate = require('Delegate')
local ColorConsts = require("ColorConsts")
local NumberFormatter = require("NumberFormatter")

---@class CityMaterialProcessRecipe:BaseTableViewProCell
local CityMaterialProcessRecipe = class('CityMaterialProcessRecipe', BaseTableViewProCell)

function CityMaterialProcessRecipe:OnCreate()
    self._p_img_select = self:GameObject("p_img_select")
    self._child_common_quantity_l = self:Button("child_common_quantity_l", Delegate.GetOrCreate(self, self.OnClick))
    self._child_toggle_dot = self:StatusRecordParent("child_toggle_dot")
    self._child_toggle_dot:SetVisible(true)

    self._p_base_farme = self:Image("p_base_farme")
    self._p_icon_item = self:Image("p_icon_item")

    self._p_text_01 = self:Text("p_text_01")
    self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickAdd))
end

---@param data CityMaterialProcessRecipeData
function CityMaterialProcessRecipe:OnFeedData(data)
    self.data = data
    self._p_img_select:SetActive(data:IsSelected())
    self._child_toggle_dot:ApplyStatusRecord(data:IsSelected() and 1 or 0)

    local icon, backIcon = data:GetItemIcon()
    g_Game.SpriteManager:LoadSprite(icon, self._p_icon_item)
    g_Game.SpriteManager:LoadSprite(backIcon, self._p_base_farme)

    local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(data.costMonitor.id)
    local needCount = data.costMonitor.minCount * data.times
    local colorText = ownCount >= needCount and ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green) or ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)
    self._p_text_01.text = string.format("<color=%s>%s</color>/%s", colorText, NumberFormatter.NumberAbbr(ownCount, true, false), NumberFormatter.NumberAbbr(needCount, true, false))
    self._p_btn_add:SetVisible(ownCount < needCount)
end

function CityMaterialProcessRecipe:OnClick()
    self.data.param:SelectRecipe(self.data.processCfg)
end

function CityMaterialProcessRecipe:OnClickAdd()
    local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.data.costMonitor.id)
    local needCount = self.data.costMonitor.minCount
    ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.data.costMonitor.id, num = needCount - ownCount}})
end

return CityMaterialProcessRecipe