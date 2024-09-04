local BaseModule = require("BaseModule")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local rapidJson = require("rapidjson")

local Profiler = CS.UnityEngine.Profiling.Profiler
local SystemInfo = CS.UnityEngine.Device.SystemInfo
local TextureFormat = CS.UnityEngine.TextureFormat
local Guid = CS.System.Guid

---@class PerformanceModule
local cls = class("PerformanceModule",BaseModule)

local LOG_COUNT_ONCE = 30
local MEGA_BYTES = 1024 * 1024
local manualGC

function cls:ctor()
    self.fps = setmetatable({}, {})
    self.reservedMem = setmetatable({}, {})
    self.mono = setmetatable({}, {})
    self.tags = setmetatable({}, {})
    self.jank = setmetatable({}, {})
    self.bigjank = setmetatable({}, {})
    self.stutter = setmetatable({}, {})
    
    rapidJson.array(self.fps)
    rapidJson.array(self.reservedMem)
    rapidJson.array(self.mono)
    rapidJson.array(self.tags)
    rapidJson.array(self.jank)
    rapidJson.array(self.bigjank)
    rapidJson.array(self.stutter)

    self.loadingFinish = false
    self.recordCount = 0
    self.battle_uid = Guid.NewGuid():ToString()
end

function cls:OnRegister()
    -- 重载此函数
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))


	---- 添加手动 CG 控制系统
	--manualGC = CS.UnityEngine.GameObject("GCManualControl")
	--manualGC:AddComponent(typeof(CS.DragonReborn.Performance.GCManualControl))
end

function cls:OnRemove()
    -- 重载此函数
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))

	CS.UnityEngine.Object.Destroy(manualGC)
end

function cls:Release()
    -- 重载此函数
end

function cls:OnLoggedIn()
    self:LogGameStart()
end

function cls:SetLoadingFinish(value)
    self.loadingFinish = value
end

function cls:OnSecondTick()
    if not self.loadingFinish then
        return
    end

    local fps = g_Game.PerformanceLevelManager:GetFps()
    table.insert(self.fps, math.float02(fps))

    local jank = g_Game.PerformanceLevelManager:GetJankTimes()
    table.insert(self.jank, math.floor(jank))

    local bigjank = g_Game.PerformanceLevelManager:GetBigJankTimes()
    table.insert(self.bigjank, math.floor(bigjank))

    local stutter = g_Game.PerformanceLevelManager:GetAllJankTimes()
    table.insert(self.stutter, math.floor(stutter))
    
    local unityMem = Profiler.GetTotalReservedMemoryLong() / MEGA_BYTES
    local monoMem = Profiler.GetMonoHeapSizeLong() / MEGA_BYTES
    table.insert(self.reservedMem, math.float02(unityMem + monoMem))
    table.insert(self.mono, math.float02(monoMem))

    self.recordCount = self.recordCount + 1
    if self.recordCount >= LOG_COUNT_ONCE then
        self:LogClientPerf()
    end
end

---@param tag string
function cls:AddTag(tag)
    local index = table.keyof(self.tags, tag)
    if not index then
        table.insert(self.tags, tag)
        self:LogClientPerf()
    end
end

---@param tag string
function cls:RemoveTag(tag)
    local index = table.keyof(self.tags, tag)
    if index then
        self:LogClientPerf()
        table.remove(self.tags, index)
    end
end

function cls:LogGameStart()
    local dataDict = {}
    dataDict['event_name'] = 'apm_battle_start'
    dataDict['event_ts'] = math.floor(g_Game.ServerTime:GetServerTimestampInMilliseconds())
    
    local details = {}
    dataDict['details'] = details
    details['device_model'] = SystemInfo.deviceModel
    details['graphics_device_name'] = SystemInfo.graphicsDeviceName
    details['operating_system'] = SystemInfo.operatingSystem
    details['processor_type'] = SystemInfo.processorType
    details['system_memory_size'] = SystemInfo.systemMemorySize
    details['graphics_memory_size'] = SystemInfo.graphicsMemorySize
    details['battle_uid'] = self.battle_uid
    details['device_unique_identifier'] = SystemInfo.deviceUniqueIdentifier
    details['device_quality'] = g_Game.PerformanceLevelManager:GetDeviceLevel():GetHashCode()
    details['version'] = ModuleRefer.AppInfoModule:VersionName()
    details['channel'] = ModuleRefer.AppInfoModule:PkgChannel()

    if SystemInfo.supportsInstancing then
        details['support_instancing'] = 1
    else
        details['support_instancing'] = 0
    end

    if SystemInfo.SupportsTextureFormat(TextureFormat.RGBAHalf) then
        details['support_rgbahalf'] = 1
    else
        details['support_rgbahalf'] = 0
    end

    if SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_4x4) and
    SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_5x5) and
    SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_6x6) and 
    SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_8x8) and 
    SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_10x10) and 
    SystemInfo.SupportsTextureFormat(TextureFormat.ASTC_12x12) 
    then
        details['support_astc'] = 1
    else
        details['support_astc'] = 0
    end

    if SystemInfo.supports2DArrayTextures then
        details['support_texturearray'] = 1
    else
        details['support_texturearray'] = 0
    end

    details['graphics_version'] = SystemInfo.graphicsDeviceVersion
    details['graphics_type'] = tostring(SystemInfo.graphicsDeviceType)

    local properties = {}
    dataDict['properties'] = properties
    properties['game_uid'] = ModuleRefer.PlayerModule:GetPlayerId()

    ModuleRefer.FPXSDKModule:TrackXperf(dataDict)
end

function cls:LogClientPerf()
    if self.recordCount == 0 then
        return
    end

    local dataDict = {}
    dataDict['event_name'] = 'apm_client_perf'
    dataDict['event_ts'] = math.floor(g_Game.ServerTime:GetServerTimestampInMilliseconds())
    
    local details = {}
    dataDict['details'] = details
    details['fps_array'] = self.fps
    details['rss_array'] = self.reservedMem
    details['mono_array'] = self.mono
    details['battle_uid'] = self.battle_uid
    details['tag'] = self.tags

    details['jank_array'] = self.jank
    details['bigjank_array'] = self.bigjank
    details['stutter_array'] = self.stutter

    local properties = {}
    dataDict['properties'] = properties
    properties['game_uid'] = ModuleRefer.PlayerModule:GetPlayerId()

    ModuleRefer.FPXSDKModule:TrackXperf(dataDict)

    self.recordCount = 0
    table.clear(self.fps)
    table.clear(self.reservedMem)
    table.clear(self.mono)
    table.clear(self.jank)
    table.clear(self.bigjank)
    table.clear(self.stutter)
end

return cls
