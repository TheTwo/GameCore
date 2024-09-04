local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local NumberFormatter = require('NumberFormatter')
local I18N = require("I18N")
local HudResourceDetailsItemCell = class('HudResourceDetailsItemCell',BaseTableViewProCell)

local QUALITY_COLOR = {
    CS.UnityEngine.Color(174/255, 180/255, 182/255, 255/255),
    CS.UnityEngine.Color(135/255, 167/255, 99/255, 255/255),
    CS.UnityEngine.Color(109/255, 145/255, 188/255, 255/255),
    CS.UnityEngine.Color(170/255, 119/255, 200/255, 255/255),
    CS.UnityEngine.Color(219/255, 131/255, 88/255, 255/255),
}

-- local RES_WIDTH = {
--     210,
--     272,
--     408
-- }

function HudResourceDetailsItemCell:OnCreate()
    self.cellSize = self:BindComponent("", typeof(CS.CellSizeComponent))
    self.goGroupNum = self:GameObject('p_group_num')
    self.goGroupResource = self:GameObject('p_group_resource')
    self.goGroup1 = self:GameObject('p_group_1')
    self.imgGroupResource1 = self:Image('p_group_resource_1')
    self.imgIconResource1 = self:Image('p_icon_resource_1')
    self.textQuantity1 = self:Text('p_text_quantity_1')
    self.goGroup2 = self:GameObject('p_group_2')
    self.imgGroupResource2 = self:Image('p_group_resource_2')
    self.imgIconResource2 = self:Image('p_icon_resource_2')
    self.textQuantity2 = self:Text('p_text_quantity_2')
    self.goGroup3 = self:GameObject('p_group_3')
    self.imgGroupResource3 = self:Image('p_group_resource_3')
    self.imgIconResource3 = self:Image('p_icon_resource_3')
    self.textQuantity3 = self:Text('p_text_quantity_3')
    self.textAmount = self:Text('p_text_amount')

    self.resGroups = {self.goGroup1, self.goGroup2, self.goGroup3}
    self.resItemGos = {self.imgGroupResource1, self.imgGroupResource2, self.imgGroupResource3}
    self.resItemIcons = {self.imgIconResource1, self.imgIconResource2, self.imgIconResource3}
    self.retItemNums = {self.textQuantity1, self.textQuantity2, self.textQuantity3}
end

function HudResourceDetailsItemCell:OnClose()
end

function HudResourceDetailsItemCell:OnFeedData(resId)
    --local resTypeName = ConfigRefer.CityResourceType:Find(resId):Name()
    local capacity = ModuleRefer.InventoryModule:GetResItemCapacity(resId)
    self.textAmount.text = I18N.Get("Maximum") .. capacity
    local cfg = ConfigRefer.CityResourceType:Find(resId)
    --local itemTypeNum = cfg:ItemsLength()
    --local widthNum = RES_WIDTH[itemTypeNum]
    --self.goGroupResource.transform.sizeDelta = CS.UnityEngine.Vector2(widthNum, self.goGroupResource.transform.sizeDelta.y)
    --self.goGroupNum.transform.sizeDelta = CS.UnityEngine.Vector2(widthNum, self.goGroupNum.transform.sizeDelta.y)

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
    for i, itemGo in ipairs(self.resItemGos) do
        local res = resTable[i]
        itemGo.gameObject:SetActive(res ~= nil)
        self.resGroups[i]:SetActive(res ~= nil)
        if res then
            local itemCfg = ConfigRefer.Item:Find(res.id)
            g_Game.SpriteManager:LoadSprite(itemCfg:SubIcon(), self.resItemIcons[i])
            local itemCount = ModuleRefer.InventoryModule:GetResItemCount(res.id)
            self.retItemNums[i].text = itemCount
            local itemPercent = 0
            if capacity > 0 then
                itemPercent = itemCount / capacity
            end
            itemPercent = math.clamp01(itemPercent)
            itemGo.transform.sizeDelta = CS.UnityEngine.Vector2(167 * itemPercent, itemGo.transform.sizeDelta.y)
            itemGo.color = QUALITY_COLOR[itemCfg:Quality()]
        end
    end
end

-- function HudResourceDetailsItemCell:SetDynamicCellRectSize(size)
--     self.cellSize.Width = size.x
--     self.cellSize.transform.sizeDelta = size
-- end

return HudResourceDetailsItemCell
