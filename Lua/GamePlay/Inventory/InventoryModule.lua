local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Quality = require('Quality')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityType = require('DBEntityType')
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ColorConsts = require('ColorConsts')
local ItemType = require('ItemType')
local ItemGroupType = require("ItemGroupType")
local FunctionClass = require('FunctionClass')

---@class InventoryModule:BaseModule
---@field itemCountCache table<number, {permanent:number, temporary:number}>
local InventoryModule = class('InventoryModule', BaseModule)

local ITEM_QUALITY_COLOR = {
    ColorConsts.quality_white,
    ColorConsts.quality_green,
    ColorConsts.quality_blue,
    ColorConsts.quality_purple,
    ColorConsts.quality_orange,
}

function InventoryModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnKItemsChanged), 1)
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
    self.countChangeListener = {}
    self.countChangeByTypeListener = {}
    self.cacheInited = false
    self.uid2Config = {}
end

function InventoryModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnKItemsChanged))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
    self.countChangeListener = nil
    self.countChangeByTypeListener = nil
    self.uid2Config = {}
end

function InventoryModule:ForceInitCache()
    -- self.cacheInited = false
    self:InitCacheOnce()
end

function InventoryModule:InitCacheOnce()
    if self.cacheInited then return end

    self.itemCountCache = {}
    self.countChangeMap = {}
    self.countChangeByTypeMap = {}
    local itemSlotMaps = self:GetCastleItems()
    if itemSlotMaps == nil then
        g_Logger.Error("暂无玩家背包数据")
        return
    end

    self.cacheInited = true

    for slotId, item in pairs(itemSlotMaps) do
        local cache = self.itemCountCache[item.ConfigId]
        if not cache then
            cache = {permanent = 0, temporary = 0}
            self.itemCountCache[item.ConfigId] = cache
        end
        cache.permanent = cache.permanent +( (item.ExpireTime == 0) and item.Count or 0 )
        cache.temporary = cache.temporary +( (item.ExpireTime ~= 0) and item.Count or 0 )
        self.countChangeMap[item.ConfigId] = true
        local cfg = ConfigRefer.Item:Find(item.ConfigId)
        if cfg then
            self.countChangeByTypeMap[cfg:Type()] = true
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ITEM_COUNT_ALL_CHANGED)

    self.initTimestamp = CS.UnityEngine.Time.frameCount
end

---@param entity wds.CastleBrief
---@param changeTable {Add:table<number, wds.Item>|nil, Remove:table<number, wds.Item>|nil}
function InventoryModule:OnKItemsChanged(entity, changeTable)
    if not self.cacheInited then return end
    if self.initTimestamp == CS.UnityEngine.Time.frameCount then return end

    local dataError = false
    table.clear(self.countChangeMap)
    table.clear(self.countChangeByTypeMap)
    
    local notRealAdd = {}
    if changeTable.Add then
        for uid, item in pairs(changeTable.Add) do
            if entity.Bag.KItems[uid] == nil then
                notRealAdd[uid] = true
                goto continue
            end

            local cache = self.itemCountCache[item.ConfigId]
            if not cache then
                cache = {permanent = 0, temporary = 0}
                self.itemCountCache[item.ConfigId] = cache
            end
            cache.permanent = cache.permanent + (item.ExpireTime == 0 and item.Count or 0)
            cache.temporary = cache.temporary + (item.ExpireTime ~= 0 and item.Count or 0)
            self.countChangeMap[item.ConfigId] = true
            local cfg = ConfigRefer.Item:Find(item.ConfigId)
            if cfg then
                if not self.countChangeByTypeMap[cfg:Type()] then
                    self.countChangeByTypeMap[cfg:Type()] = 0
                end
                self.countChangeByTypeMap[cfg:Type()] = self.countChangeByTypeMap[cfg:Type()] + item.Count
            end

            if cfg:FunctionClass() == FunctionClass.AllianceExpedition then
                ModuleRefer.WorldEventModule:UpdateWorldEventRedDots()
            end
            ::continue::
        end
    end

    if changeTable.Remove then
        for uid, item in pairs(changeTable.Remove) do
            if notRealAdd[uid] then
                if entity.Bag.KItems[uid] == nil then
                    goto continue
                end
            end

            local cache = self.itemCountCache[item.ConfigId]
            if not cache then
                dataError = true
                break
            end
            cache.permanent = cache.permanent - (item.ExpireTime == 0 and item.Count or 0)
            cache.temporary = cache.temporary - (item.ExpireTime ~= 0 and item.Count or 0)

            if cache.permanent < 0 or cache.temporary < 0 then
                dataError = true
                break
            end
            self.countChangeMap[item.ConfigId] = true
            local cfg = ConfigRefer.Item:Find(item.ConfigId)
            if cfg then
                if not self.countChangeByTypeMap[cfg:Type()] then
                    self.countChangeByTypeMap[cfg:Type()] = 0
                end
                self.countChangeByTypeMap[cfg:Type()] = self.countChangeByTypeMap[cfg:Type()] - item.Count
            end
            ::continue::
        end
    end

    if dataError then
        self.cacheInited = false
        self:InitCacheOnce()
    end
    for id, _ in pairs(self.countChangeMap) do
        self:DispatchCountChangeEvent(id)
    end
    for typ, changeNumber in pairs(self.countChangeByTypeMap) do
        if changeNumber ~= 0 then
            self:DispatchCountChangeByTypeEvent(typ)
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ITEM_COUNT_ALL_CHANGED)
end

function InventoryModule:AddCountChangeListener(id, delegate)
    if not self.countChangeListener then return end
    if not self.countChangeListener[id] then
        self.countChangeListener[id] = {}
    end
    self.countChangeListener[id][delegate] = true
    return function()
        self:RemoveCountChangeListener(id, delegate)
    end
end

function InventoryModule:RemoveCountChangeListener(id, delegate)
    if not self.countChangeListener then return end
    if not self.countChangeListener[id] then return end
    self.countChangeListener[id][delegate] = nil
end

function InventoryModule:AddCountChangeByTypeListener(typ, delegate)
    if not self.countChangeByTypeListener then return end
    if not self.countChangeByTypeListener[typ] then
        self.countChangeByTypeListener[typ] = {}
    end
    self.countChangeByTypeListener[typ][delegate] = true
    return function()
        self:RemoveCountChangeByTypeListener(typ, delegate)
    end
end

function InventoryModule:RemoveCountChangeByTypeListener(typ, delegate)
    if not self.countChangeByTypeListener then return end
    if not self.countChangeByTypeListener[typ] then return end
    self.countChangeByTypeListener[typ][delegate] = nil
end

function InventoryModule:DispatchCountChangeEvent(id)
    if not self.countChangeListener then return end
    local listeners = self.countChangeListener[id]
    if not listeners then return end
    for delegate, flag in pairs(listeners) do
        try_catch_traceback(delegate)
    end
end

function InventoryModule:DispatchCountChangeByTypeEvent(typ)
    if not self.countChangeByTypeListener then return end
    local listeners = self.countChangeByTypeListener[typ]
    if not listeners then return end
    for delegate, flag in pairs(listeners) do
        try_catch_traceback(delegate)
    end
end

---主城背包数据
---@return table<number, wds.Item>
function InventoryModule:GetCastleItems()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return {}
    end
    local castleBrief = g_Game.DatabaseManager:GetEntity(player.SceneInfo.CastleBriefId, DBEntityType.CastleBrief)
    return castleBrief.Bag.KItems
end

---@param types table<number,boolean>
---@param qualities table<number,boolean>
---@return table<number, wds.Item>
function InventoryModule:FindItemsByTypeAndQuality(types,qualities)
    ---@type table<number, wds.Item>
    local retItems = {}
    local infoCache = {}
    local items = self:GetCastleItems()
    for uid, item in pairs(items) do
        local info = infoCache[item.ConfigId]
        if not info then
            local config = ConfigRefer.Item:Find(item.ConfigId)
            info = {type = config:Type(), quality = config:Quality()}
            infoCache[item.ConfigId] = info
        end
        if info and types[info.type]
         and (qualities == nil or (qualities ~= nil and qualities[info.quality]))
        then
            retItems[uid] = item
        end
    end
    return retItems
end

---@param configId itemConfigId
---@return ItemConfigCell|nil
function InventoryModule:GetConfigByConfigId(configId)
    return ConfigRefer.Item:Find(configId)
end

---@param configId itemConfigId
---@return uidList[]
function InventoryModule:GetUidsByConfigId(configId)
    local items = self:GetCastleItems()
    local uidList = {}
    for uid, item in pairs(items) do
        if item.ConfigId == configId then
            uidList[#uidList+1] = uid
        end
    end
    return uidList
end

---@param configId itemConfigId
---@return uid|nil
function InventoryModule:GetUidByConfigId(configId)
    local items = self:GetCastleItems()
    for _, item in pairs(items) do
        if item.ConfigId == configId then
           return item.ID
        end
    end
    return nil
end

---@param configId itemConfigId
---@return itemCount
function InventoryModule:GetAmountByConfigId(configId)
    local itemConfig = ConfigRefer.Item:Find(configId)
    if itemConfig and itemConfig:Type() == ItemType.Currency then
        local player = ModuleRefer.PlayerModule:GetPlayer()
        local values = player.PlayerWrapper2.Currency.Values or {}
        local count = 0
        for i = 1, itemConfig:TagLength() do
            local currencyId = tonumber(itemConfig:Tag(i))
            if values[currencyId] then
                count = count + values[currencyId]
            end
        end
        return count
    else
        self:InitCacheOnce()
        local cache = self.itemCountCache[configId]
        return cache == nil and 0 or cache.permanent + cache.temporary
    end
end

function InventoryModule:GetAmountByFunctionClass(functionClass)
    local count = 0
    self:InitCacheOnce()
    for id, cache in pairs(self.itemCountCache) do
        local config = ConfigRefer.Item:Find(id)
        if config and config:FunctionClass() == functionClass then
            count = count + cache.permanent + cache.temporary
        end
    end
    return count
end

---@param type number @ItemType
---@param quality number @Quality
function InventoryModule:GetAmountByItemTypeAndQuality(type,quality)
    local types = {}
    types[type] = true
    local qualities = nil
    if quality then
        qualities = {}
        qualities[quality] = true
    end
    local items = self:FindItemsByTypeAndQuality(types,qualities)
    local itemCount = 0
    for _, value in pairs(items) do
        itemCount = itemCount + value.Count
    end
    return itemCount
end

---@param configId itemConfigId
---@param demand count
---@return bool
function InventoryModule:IsEnoughByConfigId(configId, demand)
    return self:GetAmountByConfigId(configId) >= demand
end

---@param uid itemUid
---@return ItemConfigCell|nil
function InventoryModule:GetConfigByUid(uid)
    if self.uid2Config[uid] then
        return self.uid2Config[uid]
    end
    local configId = self:GetConfigIdByUID(uid)
    self.uid2Config[uid] = self:GetConfigByConfigId(configId)
    return self.uid2Config[uid]
end

---@param uid itemUid
---@return itemConfigId|nil
function InventoryModule:GetConfigIdByUID(uid)
    local items = self:GetCastleItems()
    local item = items[uid]
    if item then
        return item.ConfigId
    end
    return nil
end

---@param uid itemUid
---@return number
function InventoryModule:GetAmountByUid(uid)
    local items = self:GetCastleItems()
    local item = items[uid]
    if item then
        return item.Count
    end
    return 0
end

---@param uid itemConfigId
---@param demand count
---@return bool
function InventoryModule:IsEnoughByUid(uid, demand)
    return self:GetAmountByUid(uid) >= demand
end

---@return wds.Item
function InventoryModule:GetItemInfoByUid(uid)
    local items = self:GetCastleItems()
    local item = items[uid]
    return item
end

---@return ItemIconData[]
function InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    if not itemGroupId or itemGroupId <= 0 then
        return nil
    end
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(itemGroupId)
    local itemArrays = {}
    for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
        local info = itemGroupConfig:ItemGroupInfoList(i)
        local itemId = info:Items()
        if itemId > 0 then
            local itemConfig = ConfigRefer.Item:Find(itemId)
            itemArrays[#itemArrays + 1] = {configCell = itemConfig, count = info:Nums(), showTips = true}
        end
    end
    return itemArrays
end

---@return {id:number, count:number}[]
function InventoryModule:ItemGroupId2ItemIds(itemGroupId)
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(itemGroupId)
    local itemIds = {}
    if itemGroupConfig == nil then return itemIds end
    for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
        local info = itemGroupConfig:ItemGroupInfoList(i)
        itemIds[#itemIds + 1] = {id = info:Items(), count = info:Nums()}
    end
    return itemIds
end

function InventoryModule:GetAllEquips()
    local items = self:GetCastleItems()
    local equips = {}
    for uid, item in pairs(items) do
        if item.EquipInfo and item.EquipInfo.ConfigId and item.EquipInfo.ConfigId > 0 then
            equips[#equips + 1] = {uid = uid, item = item}
        end
    end
    return equips
end

function InventoryModule:GetLowLevelRes()
    local resIds = {}
    for _, v in ConfigRefer.CityResourceType:ipairs() do
        for i = 1, v:ItemsLength() do
            local itemId = v:Items(i)
            local itemCfg = ConfigRefer.Item:Find(itemId)
            if itemCfg:Quality() == Quality.White then
                resIds[#resIds + 1] = itemId
            end
        end
    end
    return resIds
end

function InventoryModule:GetResCount()
    local castleBrief = ModuleRefer.PlayerModule:GetCastle()
    local castle = castleBrief.Castle
    return castle.GlobalAttr.ResCount or {}
end

function InventoryModule:GetResItemCapacity(resType)
    local castleBrief = ModuleRefer.PlayerModule:GetCastle()
    local castle = castleBrief.Castle
    return (castle.GlobalAttr.ResCapacity or {})[resType] or 0
end

function InventoryModule:GetResItemCapacityByItemId(itemId)
    local resType = self:GetResTypeByItemId(itemId)
    return self:GetResItemCapacity(resType)
end

function InventoryModule:GetResItemCount(itemId)
    return self:GetResCount()[itemId] or 0
end

function InventoryModule:CheckResItemIsOverflow(itemId, expendCount)
    local totalCount = self:GetResTypeCountByItemId(itemId)
    if not totalCount then
        return false
    end
    local resType = self:GetResTypeByItemId(itemId)
    local resCapacity = self:GetResItemCapacity(resType)
    if expendCount then
        return resCapacity > 0 and resCapacity < (totalCount + expendCount)
    else
        return resCapacity > 0 and resCapacity < totalCount
    end
end

function InventoryModule:GetResTypeByItemId(itemId)
    self.itemId2ResTypeMap = self.itemId2ResTypeMap or {}
    if self.itemId2ResTypeMap[itemId] then
        return self.itemId2ResTypeMap[itemId]
    end
    local resType = nil
    for _, v in ConfigRefer.CityResourceType:ipairs() do
        if not resType then
            for i = 1, v:ItemsLength() do
                local id = v:Items(i)
                if id == itemId then
                    resType = v:Id()
                end
            end
        end
    end
    self.itemId2ResTypeMap[itemId] = resType
    return resType
end

function InventoryModule:GetResTypeCount(resType)
    local ret = 0
    local cfg = ConfigRefer.CityResourceType:Find(resType)
    if cfg then
        for i = 1,cfg:ItemsLength() do
            local id = cfg:Items(i)
            ret = ret + self:GetResItemCount(id)
        end
    end
    return ret
end

function InventoryModule:GetResTypeCountByItemId(itemId)
    local resType = self:GetResTypeByItemId(itemId)
    if not resType then
        return nil
    end
    return self:GetResTypeCount(resType)
end

---@param itemInfos {id:number, num:number}[]
function InventoryModule:OpenExchangePanel(itemInfos)
    local isCanDirectExchange = true
    for _, single in ipairs(itemInfos) do
        local itemCfg = ConfigRefer.Item:Find(single.id)
        local getMoreId = itemCfg:GetMoreConfig()
        if getMoreId > 0 then
            local getMoreCfg = ConfigRefer.GetMore:Find(getMoreId)
            if getMoreCfg:GotoLength() > 0 then
                isCanDirectExchange = false
            end
            if not (single.num and single.num > 0) then
                isCanDirectExchange = false
            end
            local exchangeItem = getMoreCfg:Exchange():Currency()
            if exchangeItem <= 0 then
                isCanDirectExchange = false
            end
        end
    end
    if isCanDirectExchange then
        g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceDirectMediator, itemInfos)
    else
        g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceMediator, itemInfos)
    end
end

---@param itemGroup ItemGroupConfigCell
function InventoryModule:OpenExchangePanelByItemGroup(itemGroup)
    if itemGroup:Type() == ItemGroupType.OneByOne then
        local itemInfos = {}
        for i = 1, math.min(itemGroup:ItemNum(), itemGroup:ItemGroupInfoListLength()) do
            local groupInfo = itemGroup:ItemGroupInfoList(i)
            local id = groupInfo:Items()
            local need = groupInfo:Nums()
            local own = self:GetAmountByConfigId(id)
            if own < need then
                table.insert(itemInfos, {id = id, num = need - own})
            end
        end
        self:OpenExchangePanel(itemInfos)
    else
        g_Logger.ErrorChannel("InventoryModule", "随机权重的GetMore无法计算, 另请高明吧")
    end
end

function InventoryModule:GetItemQualityColor(quality)
    return ITEM_QUALITY_COLOR[quality]
end

function InventoryModule:CheckIsCanUseBox(boxId)
    if not boxId or boxId < 0 then
        return true
    end

    local boxCfg = ConfigRefer.RandomBox:Find(boxId)
    if boxCfg == nil then
        return true
    end
    
    local isCanUse = true
    for i = 1, boxCfg:GroupInfoLength() do
        local groupId = boxCfg:GroupInfo(i):Groups()
        local groupCfg = ConfigRefer.ItemGroup:Find(groupId)
        for j = 1, groupCfg:ItemGroupInfoListLength() do
            local info = groupCfg:ItemGroupInfoList(j)
            local itemId = info:Items()
            if itemId > 0 then
                if self:CheckResItemIsOverflow(itemId, info:Nums()) then
                    isCanUse = false
                    break
                end
            end
        end
    end
    return isCanUse
end


---@return ItemGroupInfo[]
function InventoryModule:GetDropItems(dropShowID)
    local rewardGroup = ConfigRefer.ItemGroup:Find(dropShowID)
    if (not rewardGroup) then
        return nil
    end

    local infoLength = rewardGroup:ItemGroupInfoListLength()
    local additionRewardLength = rewardGroup:AdditionRuleLength()

    if (infoLength <= 0 and additionRewardLength<= 0) then
        return nil
    end

    local itemInfos = {}

    --活动开始后一定获得的物品
    if additionRewardLength > 0 then
        for k = 1 , additionRewardLength do
            local additionReward = rewardGroup:AdditionRule(k)
            local additionRewardCfg = ConfigRefer.ItemGroupAdditionReward:Find(additionReward)
            for i = 1, additionRewardCfg:RewardsLength() do
                local rewardInfo = additionRewardCfg:Rewards(i)
                local activityId = rewardInfo:RelatedActivity()
                local fixedReward = rewardInfo:FixedReward()
                local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(activityId)
                if isOpen and fixedReward and fixedReward > 0 then
                    local itemGroup = ConfigRefer.ItemGroup:Find(fixedReward)
                    for j = 1, itemGroup:ItemGroupInfoListLength() do
                        local itemInfo = itemGroup:ItemGroupInfoList(j)
                        local itemCfg = ConfigRefer.Item:Find(itemInfo:Items())
                        if itemCfg then
                            table.insert(itemInfos, itemInfo)
                        end
                    end
                end
            end
        end
    end

    --一定获得的物品
    for i = 1, infoLength do
        local itemInfo = rewardGroup:ItemGroupInfoList(i)
        local rewardCfg = ConfigRefer.Item:Find(itemInfo:Items())
        if rewardCfg then
            table.insert(itemInfos, itemInfo)
        end
    end
    return itemInfos
end

function InventoryModule:OnReloginSuccess()
    self.cacheInited = false
    self:InitCacheOnce()
end

return InventoryModule