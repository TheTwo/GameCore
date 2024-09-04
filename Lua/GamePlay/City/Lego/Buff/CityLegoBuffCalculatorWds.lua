local CityLegoBuffCalculatorBase = require("CityLegoBuffCalculatorBase")
---@class CityLegoBuffCalculatorWds:CityLegoBuffCalculatorBase
---@field new fun():CityLegoBuffCalculatorWds
local CityLegoBuffCalculatorWds = class("CityLegoBuffCalculatorWds", CityLegoBuffCalculatorBase)
local CityLegoBuffUnit = require("CityLegoBuffUnit")
local CityLegoBuffProvider_Furniture = require("CityLegoBuffProvider_Furniture")
local CityLegoBuffProvider_Citizen = require("CityLegoBuffProvider_Citizen")
local CityLegoBuffProvider_Pet = require("CityLegoBuffProvider_Pet")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@param legoBuilding CityLegoBuilding
function CityLegoBuffCalculatorWds:ctor(legoBuilding)
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.city
    self:InitProviderInfo()
    self:InitBuffInfo()
end

function CityLegoBuffCalculatorWds:Update()
    if not self:IsDirty() then return end
    
    self:InitProviderInfo()
    self:InitBuffInfo()
end

function CityLegoBuffCalculatorWds:InitProviderInfo()
    self.roomCfgId = self.legoBuilding.roomCfgId
    self.roomLevel = self.legoBuilding.roomLevel
    ---@type table<number, CityLegoBuffProvider_Furniture>
    self.furnitures = {}
    ---@type table<number, CityLegoBuffProvider_Citizen>
    self.citizens = {}
    ---@type table<number, CityLegoBuffProvider_Pet>
    self.pets = {}

    local castle = self.city:GetCastle()
    local castleFurnitureMap = castle.CastleFurniture
    for _, furnitureId in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        if castleFurnitureMap[furnitureId] == nil then
            g_Logger.ErrorChannel("CityLegoBuffCalculatorWds", "CastleFurniture is nil, furnitureId: %d", furnitureId)
        else
            self.furnitures[furnitureId] = CityLegoBuffProvider_Furniture.new(furnitureId, self)
        end
    end

    local castleCitizen = castle.CastleCitizens
    for _, citizenId in ipairs(self.legoBuilding.payload.InnerHeroIds) do
        if castleCitizen[citizenId] == nil then
            g_Logger.ErrorChannel("CityLegoBuffCalculatorWds", "CastleCitizen is nil, citizenId: %d", citizenId)
        else
            self.citizens[citizenId] = CityLegoBuffProvider_Citizen.new(citizenId, self)
        end
    end

    local petMap = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetInfos
    for _, petId in ipairs(self.legoBuilding.payload.InnerPetIds) do
        if petMap[petId] == nil then
            g_Logger.ErrorChannel("CityLegoBuffCalculatorWds", "PetInfo is nil, petId: %d", petId)
        else
            self.pets[petId] = CityLegoBuffProvider_Pet.new(petId, self)
        end
    end
end

function CityLegoBuffCalculatorWds:InitBuffInfo()
    ---@type table<number, CityLegoBuffUnit>
    self.buffMap = {}
    local roomLevelCfg = self.legoBuilding:GetCurrentRoomLevelCfg()
    if roomLevelCfg == nil then
        return
    end

    for i = 1, roomLevelCfg:RoomTagBuffsLength() do
        local buffCfgId = roomLevelCfg:RoomTagBuffs(i)
        local buffCfg = ConfigRefer.RoomTagBuff:Find(buffCfgId)
        self.buffMap[buffCfgId] = CityLegoBuffUnit.new(buffCfg)
        self.buffMap[buffCfgId]:UpdateValidState(self)
    end
end

function CityLegoBuffCalculatorWds:GetTagCount(tagId)
    local count = 0
    for _, provider in pairs(self.furnitures) do
        count = count + provider:GetTagCount(tagId)
    end
    for _, provider in pairs(self.citizens) do
        count = count + provider:GetTagCount(tagId)
    end
    for _, provider in pairs(self.pets) do
        count = count + provider:GetTagCount(tagId)
    end
    return count
end

---@param buffCfg RoomTagBuffConfigCell
---@return table<number, CityLegoBuffProvider> @key:buffCfg第几个tag, value:对应的provider, 为空表示没有对应的provider
function CityLegoBuffCalculatorWds:GetTagProviderMap(buffCfg)
    local providerMap = {}
    if buffCfg:RoomTagListLength() == 0 then
        return providerMap
    end

    local tags2Providers = {}
    for _, provider in pairs(self.furnitures) do
        for tagCfgId, count in pairs(provider.tagMap) do
            tags2Providers[tagCfgId] = tags2Providers[tagCfgId] or {}
            for i = 1, count do
                table.insert(tags2Providers[tagCfgId], provider)
            end
        end
    end

    for _, provider in pairs(self.citizens) do
        for tagCfgId, count in pairs(provider.tagMap) do
            tags2Providers[tagCfgId] = tags2Providers[tagCfgId] or {}
            for i = 1, count do
                table.insert(tags2Providers[tagCfgId], provider)
            end
        end
    end

    for _, provider in pairs(self.pets) do
        for tagCfgId, count in pairs(provider.tagMap) do
            tags2Providers[tagCfgId] = tags2Providers[tagCfgId] or {}
            for i = 1, count do
                table.insert(tags2Providers[tagCfgId], provider)
            end
        end
    end

    for i = 1, buffCfg:RoomTagListLength() do
        local tagCfgId = buffCfg:RoomTagList(i)
        if tags2Providers[tagCfgId] and #tags2Providers[tagCfgId] > 0 then
            local provider = table.remove(tags2Providers[tagCfgId], 1)
            providerMap[i] = provider
        end
    end

    return providerMap
end

---@return CityLegoBuffProvider[]
function CityLegoBuffCalculatorWds:GetAllPrividers()
    local ret = {}
    for _, provider in pairs(self.furnitures) do
        table.insert(ret, provider)
    end
    for _, provider in pairs(self.citizens) do
        table.insert(ret, provider)
    end
    for _, provider in pairs(self.pets) do
        table.insert(ret, provider)
    end
    return ret
end

---@param changeIds table<number, boolean>
function CityLegoBuffCalculatorWds:OnFurnitureUpdate(changeIds)
    for furnitureId, _ in pairs(changeIds) do
        if self.furnitures[furnitureId] then
            self.furnitures[furnitureId]:UpdateTagMap()
        end
    end
end

function CityLegoBuffCalculatorWds:IsDirty()
    if self.roomCfgId ~= self.legoBuilding.roomCfgId then
        return true
    end

    if self.roomLevel ~= self.legoBuilding.roomLevel then
        return true
    end

    local furnitureCount = table.nums(self.furnitures)
    if furnitureCount ~= self.legoBuilding.payload.InnerFurnitureIds:Count() then
        return true
    end

    for _, furnitureId in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        if not self.furnitures[furnitureId] then
            return true
        end    
    end

    local citizenCount = table.nums(self.citizens)
    if citizenCount ~= self.legoBuilding.payload.InnerHeroIds:Count() then
        return true
    end

    for _, citizenId in ipairs(self.legoBuilding.payload.InnerHeroIds) do
        if not self.citizens[citizenId] then
            return true
        end
    end

    local petCount = table.nums(self.pets)
    if petCount ~= self.legoBuilding.payload.InnerPetIds:Count() then
        return true
    end

    for _, petId in ipairs(self.legoBuilding.payload.InnerPetIds) do
        if not self.pets[petId] then
            return true
        end
    end

    return false
end

return CityLegoBuffCalculatorWds