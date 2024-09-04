---@class DeviceUtil
local DeviceUtil = {}

local SystemInfo = CS.UnityEngine.Device.SystemInfo
local TextureFormat = CS.UnityEngine.TextureFormat
local errorPrinted = false
local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine") 

function DeviceUtil.IsSupportDevice()
    local supportsInstancing = SystemInfo.supportsInstancing
    local supportsTextureArray = SystemInfo.supports2DArrayTextures
    local supportRGBAHalfTexture = SystemInfo.SupportsTextureFormat(TextureFormat.RGBAHalf);
    
    if not supportsInstancing or not supportsTextureArray or not supportRGBAHalfTexture then
        if not errorPrinted then
            errorPrinted = true
            g_Logger.Error("supportsInstancing： " .. tostring(supportsInstancing))
            g_Logger.Error("supportsTextureArray： " .. tostring(supportsTextureArray))
            g_Logger.Error("supportRGBAHalfTexture " .. tostring(supportRGBAHalfTexture))
        end
        return false
    end

    return true
end

function DeviceUtil.GetCurrentPlatform()
    if UNITY_EDITOR then
        if USE_BUNDLE_ANDROID then return 'android' end
        if USE_BUNDLE_IOS then return 'ios' end
		if USE_BUNDLE_WIN then return 'windows' end
        if UNITY_STANDALONE_OSX then return 'osx' end
        if UNITY_STANDALONE_WIN then return 'windows' end
    else
        if UNITY_ANDROID then return 'android' end
        if UNITY_IOS then return 'ios' end
        if UNITY_STANDALONE_OSX then return 'osx' end
        if UNITY_STANDALONE_WIN then return 'windows' end
    end

    return 'android'
end

function DeviceUtil.IsLowMemoryDevice()
	if UNITY_DEBUG or UNITY_RUNTIME_ON_GUI_ENABLED then
		local RuntimeDebugSettings = require('RuntimeDebugSettings')
		if RuntimeDebugSettings:GetString(RuntimeDebugSettingsKeyDefine.DebugLowMemoryDevice) then
			return RuntimeDebugSettings:IsLowMemoryDevice()
		end
	end

	return  false  --g_Game.PerformanceLevelManager:IsLowMemoryDevice()
end

return DeviceUtil
