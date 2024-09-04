local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local InventoryItemIconCell = class('InventoryItemIconCell',BaseTableViewProCell)

function InventoryItemIconCell:OnCreate(param)
    self.btnItemResourcesStock = self:Button('p_item_resources_stock', Delegate.GetOrCreate(self, self.OnBtnItemResourcesStockClicked))
    self.goGroupStockUnselected = self:GameObject('p_group_stock_unselected')
    self.textResourceStockUnselected = self:Text('p_text_resource_stock_unselected')
    self.imgImgResourceStockUnselected = self:Image('p_img_resource_stock_unselected')
    self.goGroupStockSelected = self:GameObject('p_group_stock_selected')
    self.textResourceStockSelected = self:Text('p_text_resource_stock_selected')
    self.imgImgResourceStockSelected = self:Image('p_img_resource_stock_selected')
end

function InventoryItemIconCell:OnFeedData(data)
    self.data = data
    local count = ModuleRefer.InventoryModule:GetAmountByConfigId(self.data.configCell:Id())
    self.textResourceStockUnselected.text = count
    self.textResourceStockSelected.text = count
    g_Game.SpriteManager:LoadSprite(self.data.configCell:Icon(), self.imgImgResourceStockUnselected)
    g_Game.SpriteManager:LoadSprite(self.data.configCell:Icon(), self.imgImgResourceStockSelected)
end

function InventoryItemIconCell:OnBtnItemResourcesStockClicked()
    if self.data.onClick then
        self.data.onClick(self.data.configCell, self.data.customData)
    end
    self:SelectSelf()
end

function InventoryItemIconCell:Select(param)
    self.goGroupStockUnselected:SetVisible(false)
    self.goGroupStockSelected:SetVisible(true)
end

function InventoryItemIconCell:UnSelect(param)
    self.goGroupStockUnselected:SetVisible(true)
    self.goGroupStockSelected:SetVisible(false)
end

return InventoryItemIconCell
