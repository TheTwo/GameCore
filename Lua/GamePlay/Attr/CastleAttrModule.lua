local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local DBEntityPath = require("DBEntityPath")
local AttrComputeType = require("AttrComputeType")
local AttrProvider_Wds = require("AttrProvider_Wds")
local EventConst = require("EventConst")
local EnableLog = false

---@class CastleAttrModule:BaseModule
---@field private m_BaseCfgMaps table<number, table<number, AttrElementConfigCell>>
---@field private m_MultiCfgMaps table<number, table<number, AttrElementConfigCell>>
---@field private m_PointCfgMaps table<number, table<number, AttrElementConfigCell>>
---@field private m_BuildingProviders table<number, AttrProvider_Wds>
---@field private m_FurnitureProviders table<number, AttrProvider_Wds>
---@field private m_CitizenProviders table<number, AttrProvider_Wds>
---@field private m_GlobalProvider AttrProvider_Wds
local CastleAttrModule = class('CastleAttrModule', BaseModule)

function CastleAttrModule:OnRegister()
    self:InitCfgCache()
    self:InitProviderCache()
    self:InitCityAttrValue2Name()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.BuildingAttr.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingAttrChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.FurnitureAttr.MsgPath , Delegate.GetOrCreate(self, self.OnFunirtureAttrChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.CitizenAttr.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenAttrChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.GlobalAttr.MsgPath, Delegate.GetOrCreate(self, self.OnGlobalAttrChanged))
end

function CastleAttrModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.BuildingAttr.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingAttrChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.FurnitureAttr.MsgPath , Delegate.GetOrCreate(self, self.OnFunirtureAttrChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.CitizenAttr.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenAttrChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAttribute.GlobalAttr.MsgPath, Delegate.GetOrCreate(self, self.OnGlobalAttrChanged))
    self:ClearCfgCache()
    self:ClearProviderCache()
    self:ClearCityAttrValue2Name()
end

function CastleAttrModule:GetCastleBrief()
    return ModuleRefer.PlayerModule:GetCastle()
end

function CastleAttrModule:SwitchLog(value)
    EnableLog = value
end

---@private
function CastleAttrModule:InitCfgCache()
    self.m_BaseCfgMaps = {}
    self.m_MultiCfgMaps = {}
    self.m_PointCfgMaps = {}
    for idx, cell in ConfigRefer.AttrElement:ipairs() do
        local computeType = cell:ComputeType()
        local attrTypeCfg = ConfigRefer.AttrType:Find(cell:Type())

        if attrTypeCfg ~= nil then
            local cityAttr = attrTypeCfg:CityAttr()
            if computeType == AttrComputeType.Base then
                self.m_BaseCfgMaps[cityAttr] = self.m_BaseCfgMaps[cityAttr] or {}
                self.m_BaseCfgMaps[cityAttr][cell:Id()] = cell
            elseif computeType == AttrComputeType.Multi then
                self.m_MultiCfgMaps[cityAttr] = self.m_MultiCfgMaps[cityAttr] or {}
                self.m_MultiCfgMaps[cityAttr][cell:Id()] = cell
            elseif computeType == AttrComputeType.Point then
                self.m_PointCfgMaps[cityAttr] = self.m_PointCfgMaps[cityAttr] or {}
                self.m_PointCfgMaps[cityAttr][cell:Id()] = cell
            end
        end
    end
end

---@private
function CastleAttrModule:ClearCfgCache()
    self.m_BaseCfgMaps = nil
    self.m_MultiCfgMaps = nil
    self.m_PointCfgMaps = nil
end

---@private
function CastleAttrModule:InitProviderCache()
    local m_CastleBrief = self:GetCastleBrief()
    if m_CastleBrief == nil then
        g_Logger.Error("初始化过早或数据异常，无法获取主城信息")
        return
    end

    local castle = m_CastleBrief.Castle
    if castle == nil then
        g_Logger.Error("初始化过早或数据异常，无法获取主城信息")
        return
    end

    local attr = castle.CastleAttribute
    if attr == nil then
        g_Logger.Error("初始化过早或数据异常，无法获取主城信息")
        return
    end

    self.m_BuildingProviders = {}
    for id, info in pairs(attr.BuildingAttr) do
        self.m_BuildingProviders[id] = AttrProvider_Wds.new(info.AttrType2Val)
    end
    self.m_FurnitureProviders = {}
    for id, info in pairs(attr.FurnitureAttr) do
        self.m_FurnitureProviders[id] = AttrProvider_Wds.new(info.AttrType2Val)
    end
    self.m_CitizenProviders = {}
    for id, info in pairs(attr.CitizenAttr) do
        self.m_CitizenProviders[id] = AttrProvider_Wds.new(info.AttrType2Val)
    end

    self.m_GlobalProvider = AttrProvider_Wds.new(attr.GlobalAttr)
end

---@private
function CastleAttrModule:ClearProviderCache()
    self.m_BuildingProviders = nil
    self.m_FurnitureProviders = nil
    self.m_CitizenProviders = nil
    self.m_GlobalProvider = nil
end

function CastleAttrModule:InitCityAttrValue2Name()
    self.m_CityAttrValue2Name = {}
    local CityAttrType = require("CityAttrType")
    for name, value in pairs(CityAttrType) do
        self.m_CityAttrValue2Name[value] = name
    end
end

function CastleAttrModule:ClearCityAttrValue2Name()
    self.m_CityAttrValue2Name = nil
end

function CastleAttrModule:GetCityAttrName(value)
    if self.m_CityAttrValue2Name == nil then
        return "Unknown"
    else
        return self.m_CityAttrValue2Name[value] or "Unknown"
    end
end

---@param attrType number @ref-CityAttrType
function CastleAttrModule:SimpleGetValue(attrType)
    local b, m, p = self:GetAttrValue(attrType)
    return b * (m + 1) + p
end

function CastleAttrModule:GetValueWithFurniture(attrType, furnitureId, skipGlobal)
    local b, m, p = self:GetAttrValue(attrType, nil, furnitureId, nil, skipGlobal)
    return b * (m + 1) + p
end

function CastleAttrModule:GetValueWithPet(attrType, petId)
    local b, m, p = self:GetAttrValue(attrType, nil, nil, petId)
    return b * (m + 1) + p
end

function CastleAttrModule:GetValueWithFurnitureAndCitizen(attrType, furnitureId, citizenId)
    local b, m, p = self:GetAttrValue(attrType, nil, furnitureId, citizenId)
    return b * (m + 1) + p
end

---@private
function CastleAttrModule:GetAttrValue(attrType, buildingId, furnitureId, citizenId, skipGlobal)
    if EnableLog then
        g_Logger.TraceChannel("CastleAttrModule", "开始计算%s", self:GetCityAttrName(attrType))
    end

    local baseCfgMap, multiCfgMap, pointCfgMap = self.m_BaseCfgMaps[attrType], self.m_MultiCfgMaps[attrType], self.m_PointCfgMaps[attrType]
    --- 查不到关联属性Id
    if baseCfgMap == nil and multiCfgMap == nil and pointCfgMap == nil then
        if EnableLog then
            g_Logger.TraceChannel("CastleAttrModule", "无法查询到任何配置关联此属性，返回base:0, multi:0, point:0")
        end
        return 0, 0, 0
    end

    local baseValue, multiValue, pointValue = 0, 0, 0

    if buildingId then
        local provider = self.m_BuildingProviders[buildingId]
        if provider then
            local a, b, c = provider:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, self:GetCityAttrName(attrType))
            if EnableLog then
                g_Logger.TraceChannel("CastleAttrModule", "从建筑%d上获取到base:%s, multi:%s, point:%s", buildingId, a, b, c)
            end
            baseValue, multiValue, pointValue = baseValue + a, multiValue + b, pointValue + c
        end
    end

    if furnitureId then
        local provider = self.m_FurnitureProviders[furnitureId]
        if provider then
            local a, b, c = provider:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, self:GetCityAttrName(attrType))
            if EnableLog then
                g_Logger.TraceChannel("CastleAttrModule", "从家具%d上获取到base:%s, multi:%s, point:%s", furnitureId, a, b, c)
            end
            baseValue, multiValue, pointValue = baseValue + a, multiValue + b, pointValue + c
        end
    end

    if citizenId then
        local provider = self.m_CitizenProviders[citizenId]
        if provider then
            local a, b, c = provider:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, self:GetCityAttrName(attrType))
            if EnableLog then
                g_Logger.TraceChannel("CastleAttrModule", "从居民%d上获取到base:%s, multi:%s, point:%s", citizenId, a, b, c)
            end
            baseValue, multiValue, pointValue = baseValue + a, multiValue + b, pointValue + c
        end
    end

    if not skipGlobal then
        local a, b, c = self.m_GlobalProvider:Calculate(baseCfgMap, multiCfgMap, pointCfgMap, self:GetCityAttrName(attrType))
        if EnableLog then
            g_Logger.TraceChannel("CastleAttrModule", "从全局属性上获取到base:%s, multi:%s, point:%s", a, b, c)
        end
        baseValue, multiValue, pointValue = baseValue + a, multiValue + b, pointValue + c
    end
    return baseValue, multiValue, pointValue
end

---@private
---@param entity wds.CastleBrief
---@param changeTable table<number, wds.CastleAttrInfo> | MapField
function CastleAttrModule:OnBuildingAttrChanged(entity, changeTable)
    if entity ~= self:GetCastleBrief() then
        return
    end

    for id, data in pairs(entity.Castle.CastleAttribute.BuildingAttr) do
        if self.m_BuildingProviders[id] == nil then
            self.m_BuildingProviders[id] = AttrProvider_Wds.new(data.AttrType2Val)
        else
            self.m_BuildingProviders[id]:UpdateWds(data.AttrType2Val)
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CASTLE_ATTR_UPDATE)
end

---@private
---@param entity wds.CastleBrief
---@param changeTable table<number, wds.CastleAttrInfo> | MapField
function CastleAttrModule:OnFunirtureAttrChanged(entity, changeTable)
    if entity ~= self:GetCastleBrief() then
        return
    end

    for id, data in pairs(entity.Castle.CastleAttribute.FurnitureAttr) do
        if self.m_FurnitureProviders[id] == nil then
            self.m_FurnitureProviders[id] = AttrProvider_Wds.new(data.AttrType2Val)
        else
            self.m_FurnitureProviders[id]:UpdateWds(data.AttrType2Val)
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CASTLE_ATTR_UPDATE)
end

---@private
---@param entity wds.CastleBrief
---@param changeTable table<number, wds.CastleAttrInfo> | MapField
function CastleAttrModule:OnCitizenAttrChanged(entity, changeTable)
    if entity ~= self:GetCastleBrief() then
        return
    end

    for id, data in pairs(entity.Castle.CastleAttribute.CitizenAttr) do
        if self.m_CitizenProviders[id] == nil then
            self.m_CitizenProviders[id] = AttrProvider_Wds.new(data.AttrType2Val)
        else
            self.m_CitizenProviders[id]:UpdateWds(data.AttrType2Val)
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CASTLE_ATTR_UPDATE)
end

---@private
---@param entity wds.CastleBrief
function CastleAttrModule:OnGlobalAttrChanged(entity, changeTable)
    if entity ~= self:GetCastleBrief() then
        return
    end

    self.m_GlobalProvider:UpdateWds(entity.Castle.CastleAttribute.GlobalAttr)
    g_Game.EventManager:TriggerEvent(EventConst.CASTLE_ATTR_UPDATE)
end


---原始API，计算任一CastleBrief的属性值，如果要查询主城属性，调用GetXXX接口
---@param castleBrief wds.CastleBrief
function CastleAttrModule:CalcAttrValueFromCastleBrief(attrType, castleBrief, buildingId, furnitureId, citizenId)
    if castleBrief == nil then return 0 end

    local castle = castleBrief.Castle
    if castle == nil then return 0 end

    local attr = castle.CastleAttribute
    if attr == nil then return 0 end

    local baseCfgMap, multiCfgMap, pointCfgMap = self.m_BaseCfgMaps[attrType], self.m_MultiCfgMaps[attrType], self.m_PointCfgMaps[attrType]
    --- 查不到关联属性Id
    if baseCfgMap == nil and multiCfgMap == nil and pointCfgMap == nil then
        return 0
    end

    local baseValue, multiValue, pointValue = 0, 0, 0

    --- 单建筑属性
    if buildingId then
        local buildingAttr = attr.BuildingAttr[buildingId]
        if buildingAttr then
            for id, value in pairs(buildingAttr.AttrType2Val) do
                if baseCfgMap[id] then
                    local cfg = baseCfgMap[id]
                    baseValue = baseValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif multiCfgMap[id] then
                    local cfg = multiCfgMap[id]
                    multiValue = multiValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif pointCfgMap[id] then
                    local cfg = pointCfgMap[id]
                    pointValue = pointValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                end
            end
        end
    end

    --- 单家具属性
    if furnitureId then
        local furnitureAttr = attr.FurnitureAttr[furnitureId]
        if furnitureAttr then
            for id, value in pairs(furnitureAttr.AttrType2Val) do
                if baseCfgMap[id] then
                    local cfg = baseCfgMap[id]
                    baseValue = baseValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif multiCfgMap[id] then
                    local cfg = multiCfgMap[id]
                    multiValue = multiValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif pointCfgMap[id] then
                    local cfg = pointCfgMap[id]
                    pointValue = pointValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                end
            end
        end
    end

    --- 单居民属性
    if citizenId then
        local citizenAttr = attr.CitizenAttr[citizenId]
        if citizenAttr then
            for id, value in pairs(citizenAttr.AttrType2Val) do
                if baseCfgMap[id] then
                    local cfg = baseCfgMap[id]
                    baseValue = baseValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif multiCfgMap[id] then
                    local cfg = multiCfgMap[id]
                    multiValue = multiValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                elseif pointCfgMap[id] then
                    local cfg = pointCfgMap[id]
                    pointValue = pointValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
                end
            end
        end
    end

    --- 全局属性必然参与计算
    for id, value in pairs(attr.GlobalAttr) do
        if baseCfgMap[id] then
            local cfg = baseCfgMap[id]
            baseValue = baseValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
        elseif multiCfgMap[id] then
            local cfg = multiCfgMap[id]
            multiValue = multiValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
        elseif pointCfgMap[id] then
            local cfg = pointCfgMap[id]
            pointValue = pointValue + ModuleRefer.AttrModule:GetAttrValueByType(cfg, value)
        end
    end

    return baseValue * (1 + multiValue) + pointValue
end

return CastleAttrModule