---@class CityMapBinaryData
---@field new fun():CityMapBinaryData
local CityMapBinaryData = class("CityMapBinaryData")
local CityGridConfig = require("CityGridConfig")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")

function CityMapBinaryData:ctor(sizeX, sizeY)
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.length = self.sizeX * self.sizeY
    self.zoneData = bytearray.new(self.length)
    self.validData = bitarray.new(self.length)
    self.area2idx = {}
end

---@private
function CityMapBinaryData:UnpackFromByteArray(ptr, length)
    local count = CityGridConfig.Instance.cellsX * CityGridConfig.Instance.cellsY
    if length ~= count then
        error("数据与预期不符")
    end
    local handle = streamhandle.new(ptr, length)
    for i = 1, length do
        local value = handle:readbyte()
        local isValid = (value & 0x01) == 0
        local zoneId = value >> 1

        self.zoneData[i] = zoneId
        self.validData[i] = isValid
        self.area2idx[zoneId] = self.area2idx[zoneId] or {}
        table.insert(self.area2idx[zoneId], i)
    end
end

function CityMapBinaryData:IsLocationValid(x, y)
    local idx = y * self.sizeX + x + 1
    return self.validData[idx]
end

function CityMapBinaryData:OnSyncAssetReady(flag)
    if flag then
        g_Game.AssetManager:LoadTextWithCallback(ManualResourceConst.cityData, Delegate.GetOrCreate(self, self.UnpackFromByteArray))
    else
        g_Logger.Error("cityData数据加载失败")
    end
end

local inst = CityMapBinaryData.new(CityGridConfig.Instance.cellsX, CityGridConfig.Instance.cellsY)
CityMapBinaryData.Instance = inst

local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
local set = HashSetString()
set:Add(ManualResourceConst.cityData)
g_Game.AssetManager:EnsureSyncLoadAssets(set, true, Delegate.GetOrCreate(inst, inst.OnSyncAssetReady))

return CityMapBinaryData