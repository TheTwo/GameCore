local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local NumberFormatter = require('NumberFormatter')
local HudResourceItemCell = class('HudResourceItemCell',BaseTableViewProCell)

function HudResourceItemCell:OnCreate()
    self.animTrigger = self:AnimTrigger("")
    self.imgGroupResource1 = self:GameObject('p_group_resource_1')
    self.imgIconItem1 = self:Image('p_icon_item_1')
    self.imgGroupResource2 = self:GameObject('p_group_resource_2')
    self.imgIconItem2 = self:Image('p_icon_item_2')
    self.imgGroupResource3 = self:GameObject('p_group_resource_3')
    self.imgIconItem3 = self:Image('p_icon_item_3')
    self.textQuantity = self:Text('p_text_quantity')
    self.imgIcons = {self.imgIconItem1, self.imgIconItem2, self.imgIconItem3}
    self.resItemGos = {self.imgGroupResource1, self.imgGroupResource2, self.imgGroupResource3}
end

function HudResourceItemCell:OnClose()
end

function HudResourceItemCell:OnFeedData(param)
    local resId = param.id
    if param.isPlayAnim then
        self.animTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    local currentNum = ModuleRefer.InventoryModule:GetResTypeCount(resId)
    local capacity = ModuleRefer.InventoryModule:GetResItemCapacity(resId)
    self.textQuantity.text = NumberFormatter.NumberAbbr(currentNum) --.. "/" .. NumberFormatter.NumberAbbr(capacity)

    local cfg = ConfigRefer.CityResourceType:Find(resId)
    local resTable = {}
    for i = 1, cfg:ItemsLength() do
        local itemId = cfg:Items(i)
        local itemCfg = ConfigRefer.Item:Find(itemId)
        resTable[#resTable + 1] = {id = itemId, quality = itemCfg:Quality()}
    end
    local sortFunc = function(a, b)
        if a.quality == b.quality then
            return a.id < b.id
        else
            return a.quality < b.quality
        end
    end
    table.sort(resTable, sortFunc)
    for i, img in ipairs(self.imgIcons) do
        local res = resTable[i]
        self.resItemGos[i]:SetActive(res ~= nil)
        if res then
            local itemCfg = ConfigRefer.Item:Find(res.id)
            g_Game.SpriteManager:LoadSprite(itemCfg:SubIcon(), img)
        end
    end
end

return HudResourceItemCell
