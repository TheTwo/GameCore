local Utils = require("Utils")
local CSExceptionType = typeof(CS.System.Exception)
local LuaStackTraceException = CS.XLua.LuaStackTraceException

---@type CS.SdkAdapter.SdkModels.SdkCrashlytics
local csSdkCrashlytics = {} -- CS.SdkAdapter.SdkModels.SdkCrashlytics

---@class SdkCrashlytics
local SdkCrashlytics = {}

function SdkCrashlytics.LogCSException(csException)
    if not csException then
        return false
    end
    if type(csException) ~= 'userdata' or not csException.GetType or type(csException.GetType) ~= 'function' then
        return false
    end
    local csharpType = csException:GetType()
    if Utils.IsNull(csharpType) then
        return false
    end
    if not CSExceptionType:IsAssignableFrom(csharpType) then
        return false
    end
    if not csSdkCrashlytics.ServiceRunning then
        g_Logger.Error(csException:ToString())
        return true
    end
    csSdkCrashlytics.LogCustomException(csException)
    return true
end

function SdkCrashlytics.LogLuaErrorAsException(luaErrorStr)
    if string.IsNullOrEmpty(luaErrorStr) then
        return false
    end
    if type(luaErrorStr) ~= 'string' then
        return false
    end
    if not csSdkCrashlytics.ServiceRunning then
        g_Logger.Error(luaErrorStr)
        return true
    end
    local ex = LuaStackTraceException(luaErrorStr)
    return SdkCrashlytics.LogCSException(ex)
end

function SdkCrashlytics.RecordCrashlyticsLog(msg)
    if string.IsNullOrEmpty(msg) then return end
    
    if not csSdkCrashlytics.ServiceRunning then
        g_Logger.Log(msg)
        return
    end
    
    csSdkCrashlytics.RecordCrashlyticsLog(msg)
end

function SdkCrashlytics.SetCustomKey(key, value)
    csSdkCrashlytics.SetCustomKey(key, value)
end

function SdkCrashlytics.SetUserId(userId)
    csSdkCrashlytics.SetUserId(userId)
end

function SdkCrashlytics.SetAccountId(account)
    csSdkCrashlytics.SetAccountId(account)
end

function SdkCrashlytics.SetReporter(reporter)
    csSdkCrashlytics.SetReporter(reporter)
end

function SdkCrashlytics.RecordServerConnectInfo(addr, port, svrName)
    csSdkCrashlytics.SetServerInfo(addr, tostring(port), svrName)
end

function SdkCrashlytics.RecordVersionBaseUrl(url)
    SdkCrashlytics.SetCustomKey("VERSION_CONTROL_BASEURL", url)
end

function SdkCrashlytics.RecordBaseLoadingState(stateClassName, isExit)
    if not isExit then
        csSdkCrashlytics.SetLastState(stateClassName)
    end
    if UNITY_EDITOR then
        return
    end
    if isExit then
        SdkCrashlytics.RecordCrashlyticsLog("[LOADING_STATE][OUT]" .. stateClassName)
    else
        SdkCrashlytics.RecordCrashlyticsLog("[LOADING_STATE][IN]" .. stateClassName)
    end
end

function SdkCrashlytics.RecordCityState(stateClassName, isExit)
    if UNITY_EDITOR then
        return
    end
    if isExit then
        SdkCrashlytics.RecordCrashlyticsLog("[CITY_STATE][OUT]" .. stateClassName)
    else
        SdkCrashlytics.RecordCrashlyticsLog("[CITY_STATE][IN]" .. stateClassName)
    end
end

function SdkCrashlytics.RecordOpenUiOperation(uiName)
    csSdkCrashlytics.SetLastUIName(uiName)
    if UNITY_EDITOR then
        return
    end
    SdkCrashlytics.RecordCrashlyticsLog("[OPEN_UI]" .. uiName)
end

function SdkCrashlytics.RegisterProtocolId2Name(protocolId2Name)
    csSdkCrashlytics.RegisterProtocolId2Name(protocolId2Name)
end

function SdkCrashlytics.SetLastNetRequest(protocolId, requestName)
    if UNITY_EDITOR then
        return
    end
    if not csSdkCrashlytics.SetLastNetRequest(protocolId) then
        csSdkCrashlytics.SetLastNetRequestFallback(requestName)
    end
end

function SdkCrashlytics.SetLastNetResponse(protocolId, responseName)
    if UNITY_EDITOR then
        return
    end
    if not csSdkCrashlytics.SetLastNetResponse(protocolId) then
        csSdkCrashlytics.SetLastNetResponseFallback(responseName)
    end
end

function SdkCrashlytics.SetLastNetPush(protocolId, pushName)
    if UNITY_EDITOR then
        return
    end
    if not csSdkCrashlytics.SetLastNetPush(protocolId) then
        csSdkCrashlytics.SetLastNetPushFallback(pushName)
    end
end

function SdkCrashlytics.RecordLogicVersion()
    if UNITY_EDITOR then
        return
    end

    local branch, commitHash = SdkCrashlytics.GetLogicVersionSafely()
    csSdkCrashlytics.SetLogicVersion(branch, commitHash)
end

function SdkCrashlytics.GetLogicVersionSafely()
    local ok, versionInfo = pcall(require, "LogicVersion")
    if not ok then
        return "Unknown", "Unknown"
    end

    return versionInfo.Branch, versionInfo.CommitHash
end

function SdkCrashlytics.DebugTestTriggerException(msg, delay)
    csSdkCrashlytics.DebugTestTriggerException(msg, delay or 0)
end

return SdkCrashlytics