local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
---@class ActivityShopPermanentPack : BaseUIComponent
local ActivityShopPermanentPack = class('ActivityShopPermanentPack', BaseUIComponent)

function ActivityShopPermanentPack:OnCreate()
    self.tablePack = self:TableViewPro('p_table_pack')
end

function ActivityShopPermanentPack:OnFeedData(param)
    if not param then
        return
    end
    self.packGroups = param.openedPackGroups
    self:FillTable()
end

function ActivityShopPermanentPack:FillTable()
    table.sort(self.packGroups, ModuleRefer.ActivityShopModule.GoodsIsSoldOutComparator)
    self.tablePack:Clear()
    for i, id in ipairs(self.packGroups) do
        local param = {
            packGroupId = id,
            index = i,
        }
        self.tablePack:AppendData(param)
    end
end

return ActivityShopPermanentPack