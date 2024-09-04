local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')

local Application = CS.UnityEngine.Application

---@class PerformanceLevelManager
---@field new fun():PerformanceLevelManager
---@field manager CS.DragonReborn.Performance.PerformanceLevelManager
---@field setInitQualityCallbacks table
---@field setEnterSceneQualityCallbacks table
---@field isReady boolean
---@field configCell QualityLevelConfigCell
local PerformanceLevelManager = class("PerformanceLevelManager", require("BaseManager"))

local MIN_FRAMES_RECORD = 4
local JANK_THRESHOLD_VALUE = 84
local BIG_JANK_THRESHOLD_VALUE = 125
local FPS_RECORD_COUNT = 10

function PerformanceLevelManager:ctor()
    self.manager = CS.DragonReborn.Performance.PerformanceLevelManager.Instance
    self.isReady = false
    
    --initialize when config is ready
    self.loadingFinish = false
    self.frameTimesPerSec = {}
    self.fpsQueue = {}
    self.curJankTimes = 0
    self.curBigJankTimes = 0
	self.allJankTime = 0
    self.lastTimestamp = 0
    self.accumFrames = 0
    self.currFps = 0
    self.starting = false
    self.overrideDynamicFps = nil
end

function PerformanceLevelManager:Reset()
    self:UnregisterListeners()

    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)

    self.manager = nil
    
    self.isReady = false
end

function PerformanceLevelManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end


function PerformanceLevelManager:Initialize(qualityLevel)
    self.qualityLevelConfigId = qualityLevel
    g_Logger.Log("Initialize SetQuality id: %s", self.qualityLevelConfigId)
    if UNITY_DEBUG or UNITY_RUNTIME_ON_GUI_ENABLED then
        local RuntimeDebugSettings = require('RuntimeDebugSettings')
        local has, qualityLevelId = RuntimeDebugSettings:GetDeviceLevel()
        if has then
            self.qualityLevelConfigId = qualityLevelId
            g_Logger.Log("Initialize SetQuality id: %s, override by RuntimeDebugSettings", self.qualityLevelConfigId)
        end
    end
    
    if self.qualityLevelConfigId == 0 then
        self.qualityLevelConfigId = 101
        g_Logger.Log("Initialize SetQuality id: %s, override by ERROR", self.qualityLevelConfigId)
    end
    
    local configCell = ConfigRefer.QualityLevel:Find(self.qualityLevelConfigId)
    if not configCell then
        g_Logger.Error('找不到QualityLevel %s, 请检查配置', self.qualityLevelConfigId)
        return
    end

    self.qualityLevelConfig = configCell
    -- self.fps = configCell:Fps()
    -- self.dynamicFps = configCell:DynamicFps()
    -- self.activeFps = self.fps
    -- Application.targetFrameRate = self.activeFps

    local RuntimeDebugSettings = require('RuntimeDebugSettings')
    local has, fpsMode = RuntimeDebugSettings:GetInt('fps_mode')
    if has and fpsMode == RuntimeDebugSettings.FPS_MODE_60 then
        self.fps = 60
        self.dynamicFps = 60
        self.activeFps = self.dynamicFps
        Application.targetFrameRate = self.activeFps
    elseif has and fpsMode == RuntimeDebugSettings.FPS_MODE_30 then
        self.fps = 30
        self.dynamicFps = 30
        self.activeFps = self.dynamicFps
        Application.targetFrameRate = self.activeFps
    elseif has and fpsMode == RuntimeDebugSettings.FPS_MODE_dynamic then
        self.fps = 30
        self.dynamicFps = 60
        self.activeFps = self.dynamicFps
        Application.targetFrameRate = self.activeFps
    else
        self.fps = configCell:Fps()
        self.dynamicFps = configCell:DynamicFps()
        self.activeFps = self.fps
        Application.targetFrameRate = self.activeFps
    end

    -- TODO for renderdoc
    --使用RenderDoc在Unity Editor下抓帧分析渲染性能时，需要保证GameView的帧率和在Unity Editor的帧率相同，否则无法捕获GameView的渲染调用
    -- Application.targetFrameRate = 0

    self.manager:OnGameInitialize()
    self:RegisterListeners()

    ModuleRefer.DeviceQualityModule:UpdateQualitySettings(configCell)
    self:SetBestDeviceLevel(configCell:MinPerfLevel())
    ModuleRefer.FPXSDKModule:OverrideDeviceLevel(configCell:MinPerfLevel())
    self.isReady = true
end

function PerformanceLevelManager:RegisterListeners()
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.ENTER_SCENE_QUALITY_CHANGED, Delegate.GetOrCreate(self, self.OnEnterSceneQualityChanged))
    g_Game.EventManager:AddListener(EventConst.RENDER_FRAME_RATE_SPEEDUP_START, Delegate.GetOrCreate(self, self.OnRenderFrameRateSpeedupStart))
    g_Game.EventManager:AddListener(EventConst.RENDER_FRAME_RATE_SPEEDUP_END, Delegate.GetOrCreate(self, self.OnRenderFrameRateSpeedupEnd))
    g_Game.EventManager:AddListener(EventConst.RENDER_FRAME_RATE_OVERRIDE, Delegate.GetOrCreate(self, self.OnRenderFrameRateOverride))
end

function PerformanceLevelManager:UnregisterListeners()
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.ENTER_SCENE_QUALITY_CHANGED, Delegate.GetOrCreate(self, self.OnEnterSceneQualityChanged))
    g_Game.EventManager:RemoveListener(EventConst.RENDER_FRAME_RATE_SPEEDUP_START, Delegate.GetOrCreate(self, self.OnRenderFrameRateSpeedupStart))
    g_Game.EventManager:RemoveListener(EventConst.RENDER_FRAME_RATE_SPEEDUP_END, Delegate.GetOrCreate(self, self.OnRenderFrameRateSpeedupEnd))
    g_Game.EventManager:RemoveListener(EventConst.RENDER_FRAME_RATE_OVERRIDE, Delegate.GetOrCreate(self, self.OnRenderFrameRateOverride))
end

function PerformanceLevelManager:OnRenderFrameRateSpeedupStart()
    self.activeFps = self:GetDynamicFps()
    Application.targetFrameRate = self.activeFps
    self.starting = true
end

function PerformanceLevelManager:OnRenderFrameRateSpeedupEnd()
    self.activeFps = self.fps
    Application.targetFrameRate = self.activeFps
    self.starting = false
end

function PerformanceLevelManager:GetDynamicFps()
    return self.overrideDynamicFps or self.dynamicFps
end

function PerformanceLevelManager:OnRenderFrameRateOverride(overrideDynamicFps)
    self.overrideDynamicFps = overrideDynamicFps
    if self.starting then
        self:OnRenderFrameRateSpeedupStart()
    end
end

function PerformanceLevelManager:SetLoadingFinish(value)
    self.loadingFinish = value
end

function PerformanceLevelManager:Tick(delta)
    if not self.isReady then
        return
    end

    self.accumFrames = self.accumFrames + 1
    table.insert(self.frameTimesPerSec, delta)

    local timeNow = g_Game.Time.realtimeSinceStartup
    if self.lastTimestamp <= 0 then self.lastTimestamp = timeNow end

    if timeNow > self.lastTimestamp + 1 then
        local fps = self.accumFrames / (timeNow - self.lastTimestamp)
        self.accumFrames = 0
        self.lastTimestamp = timeNow
        
        table.insert(self.fpsQueue, fps)

        self.currFps = self:GetAverageFPS()

        self:RecordJank()
    end
end

function PerformanceLevelManager:RecordJank()
    self.curJankTimes = 0
    self.curBigJankTimes = 0
	self.allJankTime = 0

    if #self.frameTimesPerSec >= MIN_FRAMES_RECORD and self.loadingFinish then
        for i = MIN_FRAMES_RECORD, #self.frameTimesPerSec do
            local frameTime = self.frameTimesPerSec[i]
            local time = math.floor(frameTime * 1000)
            if time > JANK_THRESHOLD_VALUE then
                local lastAvgTimes = 0
                for j = 1, MIN_FRAMES_RECORD - 1 do
                    local tmpFrameTime = self.frameTimesPerSec[j]
                    lastAvgTimes = lastAvgTimes + tmpFrameTime
                end
                lastAvgTimes = lastAvgTimes / (MIN_FRAMES_RECORD - 1)

                if frameTime > lastAvgTimes * 2 then
                    if time > BIG_JANK_THRESHOLD_VALUE then
                        self.curBigJankTimes = self.curBigJankTimes + 1
                    else
                        self.curJankTimes = self.curJankTimes + 1
                    end

                    self.allJankTime = self.allJankTime + time
                end
            end
        end
    end

    table.clear(self.frameTimesPerSec)
end

function PerformanceLevelManager:GetAverageFPS()
    while #self.fpsQueue > FPS_RECORD_COUNT do
        table.remove(self.fpsQueue, 1)
    end

    local sum = 0
    for _, fps in ipairs(self.fpsQueue) do
        sum = sum + fps
    end

    local fps = sum / #self.fpsQueue
    return fps
end

function PerformanceLevelManager:GetFps()
    return self.currFps
end

function PerformanceLevelManager:GetJankTimes()
    return self.curJankTimes
end

function PerformanceLevelManager:GetBigJankTimes()
    return self.curBigJankTimes
end

function PerformanceLevelManager:GetAllJankTimes()
    return self.allJankTime
end

---@return CS.DragonReborn.Performance.DeviceLevel
function PerformanceLevelManager:GetDeviceLevel()
    local deviceLevel = self.manager:GetDeviceLevel()
    return deviceLevel
end

---@return boolean
function PerformanceLevelManager:IsLowMemoryDevice()
    return self.manager:IsLowMemoryDevice()
end

---@param deviceLevel CS.DragonReborn.Performance.DeviceLevel
function PerformanceLevelManager:SetBestDeviceLevel(deviceLevel)
    self.manager:SetBestDeviceLevel(deviceLevel)
end

function PerformanceLevelManager:OnEnterSceneQualityChanged()
    if not self.qualityLevelConfig then
        g_Logger.Error('qualityLevelConfig is nil')
        return
    end

    ModuleRefer.DeviceQualityModule:UpdateEnterSceneQualitySetting(self.qualityLevelConfig)
end

---@return number, number, number
function PerformanceLevelManager:GetDisconnectParam()
    local level = self.qualityLevelConfig:MinPerfLevel()
    if level == 2 then
        return 1800, 22, 9000
    elseif level == 1 then
        return 1800, 22, 6000
    else
        return 1800, 22, 4500
    end
end

function PerformanceLevelManager:GetMaxDecorationAndUnitProcessCountPerFrame()
    local level = self.qualityLevelConfig:MinPerfLevel()
    if level == 2 then
        return 100, 20
    elseif level == 1 then
        return 100, 10
    else
        return 100, 5
    end
end

function PerformanceLevelManager:IsHighLevel()
    return self.qualityLevelConfig:MinPerfLevel() == 2
end

function PerformanceLevelManager:IsMiddleLevel()
    return self.qualityLevelConfig:MinPerfLevel() == 1
end

function PerformanceLevelManager:IsLowLevel()
    return self.qualityLevelConfig:MinPerfLevel() == 0
end

return PerformanceLevelManager
