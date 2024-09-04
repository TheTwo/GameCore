local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")

---@class CityCreepModule:BaseModule
---@field new fun():CityCreepModule
local CityCreepModule = class("CityCreepModule", BaseModule)
local ConfigRefer = require("ConfigRefer")
local SaveKey = "SelectedSweeperCfgId"

function CityCreepModule:OnRegister()
    self.fTypeIsSweeper = {}
    self.fLevelToSweeper = {}
    for _, v in ConfigRefer.CityCreepSweeper:pairs() do
        local fLevel = v:RelFurniture()
        local lvCell = ConfigRefer.CityFurnitureLevel:Find(fLevel)
        if lvCell then
            local fType = lvCell:Type()
            self.fLevelToSweeper[fLevel] = v
            self.fTypeIsSweeper[fType] = true
        end
    end
    self.bigAddChangeTable = {}
    local id = g_Game.PlayerPrefsEx:GetIntByUid(SaveKey, 0)
    if id == 0 then
        self.selectSweepCfgId = nil
    else
        self.selectSweepCfgId = id
    end
end

function CityCreepModule:OnRemove()
    self.fTypeIsSweeper = nil
    self.fLevelToSweeper = nil
    self.bigAddChangeTable = nil
end

---@return boolean 此家具类型是否为菌毯清理装置
function CityCreepModule:IsSweeperByFurnitureType(fType)
    return self.fTypeIsSweeper[fType] == true
end

---@return CityCreepSweeperConfigCell 根据家具LevelId查询菌毯清除配置
function CityCreepModule:GetSweeperConfigByFurnitureLevelId(lvId)
    return self.fLevelToSweeper[lvId]
end

---@return wds.Item
function CityCreepModule:GetAvailableSweeperItem()
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        local uids = ModuleRefer.InventoryModule:GetUidsByConfigId(itemID)
        for j = 1, table.nums(uids) do
            local uid = uids[j]
            local item = ModuleRefer.InventoryModule:GetItemInfoByUid(uid)
            if item.DurabilityInfo.CurDurability > 0 then
                return item
            end 
        end
    end
end

---@param item wds.Item
---@return string
function CityCreepModule:GetSweeperItemDurabilityText(item)
    if item then
        -- local itemConfig = ConfigRefer.Item:Find(item.ConfigId)
        return ("%.0f"):format(item.DurabilityInfo.CurDurability)
        -- return math.round(item.DurabilityInfo.CurDurability / itemConfig:Durability() * 100) .. "%"
    end
    return 0
end

---@param creepManager CityCreepManager
---@return boolean, number
function CityCreepModule:CalculateSweepCost(minX, maxX, minY, maxY, durability, creepManager)
    local cost = 0
    local tileCost = ConfigRefer.CityConfig:CostDurabilityPerTile()
    local remainDurability = durability
    if remainDurability < tileCost then
        return true, 0
    end

    for y = minY, maxY do
        for x = minX, maxX do
            if creepManager:IsAffect(x, y) then
                if remainDurability >= cost + tileCost then
                    cost = cost + tileCost
                else
                    return true, cost
                end
            end
        end
    end

    return false, cost
end

function CityCreepModule:GetSelectSweeperCfgId()
    return self.selectSweepCfgId
end

function CityCreepModule:SetSelectSweeperCfgId(cfgId)
    self.selectSweepCfgId = cfgId
    if cfgId ~= nil then
        g_Game.PlayerPrefsEx:SetIntByUid(SaveKey, cfgId)
    else
        g_Game.PlayerPrefsEx:DeleteKeyByUid(SaveKey)
    end
end

function CityCreepModule:GetSweeperDurabilitySum(cfgId)
    if cfgId == nil then return 0 end

    local uids = ModuleRefer.InventoryModule:GetUidsByConfigId(cfgId)
    if #uids == 0 then return 0 end

    local ret = 0
    for _, uid in ipairs(uids) do
        local itemInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(uid)
        ret = ret + itemInfo.DurabilityInfo.CurDurability
    end

    return ret
end

return CityCreepModule