local GMPage = require("GMPage")

local GMPageUtils = require("GMPageUtils")
local GUILayout = require("GUILayout")
local UnityEngine = CS.UnityEngine
local SystemInfo = UnityEngine.Device.SystemInfo
local Application = UnityEngine.Device.Application
local Screen = UnityEngine.Device.Screen
local Time = UnityEngine.Time
local QualitySettings = UnityEngine.QualitySettings
local JobsUtility = CS.Unity.Jobs.LowLevel.Unsafe.JobsUtility

--- enum types
local DeviceType = UnityEngine.DeviceType
local BatteryStatus = UnityEngine.BatteryStatus
local SystemLanguage = UnityEngine.SystemLanguage
local RuntimePlatform = UnityEngine.RuntimePlatform
local ApplicationInstallMode = UnityEngine.ApplicationInstallMode
local ApplicationSandboxType = UnityEngine.ApplicationSandboxType
local ScreenOrientation = UnityEngine.ScreenOrientation
local NativePowerThermalStatus = CS.DragonReborn.NativePowerThermalStatus

---@class GMPageSystemInfo
local GMPageSystemInfo = class('GMPageSystemInfo', GMPage)

GMPageSystemInfo.InfoCollectionLowerAdd = false
GMPageSystemInfo.InfoCollection = {
    {"---------------- System ----------------", function() return nil end},
    {"Operating System", function() return SystemInfo.operatingSystem end},
    {"Device Name", function() return SystemInfo.deviceName end},
    {"Device Type", function() return GMPageUtils.PrintEnum(DeviceType, SystemInfo.deviceType) end},
    {"Device Model", function() return SystemInfo.deviceModel end},
    {"CPU Type", function() return SystemInfo.processorType end},
    {"CPU Count", function() return tostring(SystemInfo.processorCount) end},
    {"System Memory", function() return tostring(SystemInfo.systemMemorySize) end},
    {"Battery", function() return GMPageUtils.PrintEnum(BatteryStatus, SystemInfo.batteryStatus) end},
    {"Battery Level", function() return string.format("%0.2f", SystemInfo.batteryLevel) end},
    {"---------------- Unity ----------------", function() return nil end},
    {"Unity", function() return Application.unityVersion end},
    {"System Language", function() return GMPageUtils.PrintEnum(SystemLanguage, Application.systemLanguage) end},
    {"Platform", function() return GMPageUtils.PrintEnum(RuntimePlatform, Application.platform) end},
    {"Install Mode", function() return GMPageUtils.PrintEnum(ApplicationInstallMode, Application.installMode) end},
    {"Sandbox", function() return GMPageUtils.PrintEnum(ApplicationSandboxType, Application.sandboxType) end},
    {"Application Version", function() return Application.version end},
    {"Application Build Guid", function() return Application.buildGUID end},
    {"Application Identifier", function() return Application.identifier end},
    {"---------------- Display -----------------", function() return nil end},
    {"Resolution", function() return string.format("%dx%d", Screen.width, Screen.height) end},
    {"DPI", function() return string.format("%0.2f", Screen.dpi) end},
    {"Orientation", function() return GMPageUtils.PrintEnum(ScreenOrientation, Screen.orientation) end},
    {"---------------- Runtime -----------------", function() return nil end},
    {"Play Time", function() return string.format("%0.3f", Time.unscaledTime) end},
    {"Current Scene", function()
        local activeScene = UnityEngine.SceneManagement.SceneManager.GetActiveScene()
        return string.format("%s (Index: %d)", activeScene.name, activeScene.buildIndex)
    end},
    {"Quality", function() 
        local qLevel = QualitySettings.GetQualityLevel()
        local qNames = QualitySettings.names
        return qNames[qLevel] .. string.format(" (%d)", qLevel)
    end},
    {"ThermalStatus", function() 
        ---@type CS.DragonReborn.Utilities.PowerManager
        local pm = CS.DragonReborn.Utilities.PowerManager.Instance
        local status = pm:GetCurrentThermalStatus()
        return GMPageUtils.PrintEnum(NativePowerThermalStatus, status)
    end},
    {"---------------- Graphics -----------------", function() return nil end},
    {"Device Name", function() return SystemInfo.graphicsDeviceName end},
    {"Device Vendor", function() return SystemInfo.graphicsDeviceVendor end},
    {"Device Version", function() return SystemInfo.graphicsDeviceVersion end},
    {"Graphics Memory", function() return tostring(SystemInfo.graphicsMemorySize) end},
    {"Max Tex Size", function() return tostring(SystemInfo.maxTextureSize) end},
    {"---------------- Jobs -----------------", function() return nil end},
    {"Job Worker Count", function() return tostring(JobsUtility.JobWorkerCount) end},
    {"Job Worker Max Count", function() return tostring(JobsUtility.JobWorkerMaximumCount) end},
    {"Job Thread Max Count", function() return tostring(JobsUtility.MaxJobThreadCount) end},
    {"Job IsExecuting", function() return GMPageUtils.PrintBool(JobsUtility.IsExecutingJob) end},
    {"Job Debugger Enabled", function() return GMPageUtils.PrintBool(JobsUtility.JobDebuggerEnabled) end},
    {"Job Compiler Enabled", function() return GMPageUtils.PrintBool(JobsUtility.JobCompilerEnabled) end},
}

if not GMPageSystemInfo.InfoCollectionLowerAdd then
    GMPageSystemInfo.InfoCollectionLowerAdd = true
    for _,i in ipairs(GMPageSystemInfo.InfoCollection) do
        i[3] = string.lower(i[1])
    end
end

function GMPageSystemInfo:ctor()
    self._scrollPos = UnityEngine.Vector2.zero
    self._filter = nil
end

function GMPageSystemInfo:OnGUI()
    GUILayout.BeginVertical()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Search:",GUILayout.shrinkWidth)
    self._filter = GUILayout.TextField(self._filter, GUILayout.expandWidth)
    if GUILayout.Button("Copy", GUILayout.shrinkWidth) then
        self:Copy()
    end
    GUILayout.EndHorizontal()
    local filter
    local inFilterMode = not string.IsNullOrEmpty(self._filter)
    if inFilterMode then
        filter = string.lower(self._filter)
    end
    self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)
    for _,i in ipairs(self.InfoCollection) do
        local _, content = pcall(i[2])
        if nil == content then
            if not inFilterMode then
                GUILayout.Label(i[1])
            end
        else
            if (not inFilterMode) or string.find(i[3], filter) then
                GUILayout.Label(string.format("%s:%s", i[1], content))
            end
        end
    end
    GUILayout.EndScrollView()
    GUILayout.EndVertical()
end

function GMPageSystemInfo:Copy()
    local toCopy = {}
    for _,i in ipairs(self.InfoCollection) do
        local content = i[2]()
        if nil == content then
            table.insert(toCopy, i[1])
        else
            table.insert(toCopy,string.format("%s:%s", i[1], content))
        end
    end
    UnityEngine.GUIUtility.systemCopyBuffer = table.concat(toCopy, '\n')
end

return GMPageSystemInfo