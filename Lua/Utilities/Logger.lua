local Logger = {}
---@type CS.DragonReborn.NLogger
local loggerImpl = CS.DragonReborn.NLogger
---@type CS.DragonReborn.LogSeverity
local LogSeverity = CS.DragonReborn.LogSeverity
local currentLogSeverity = loggerImpl.GetSeverity():GetHashCode()
local dirSeparatorChar = string.byte('/')
local dirSeparatorChar2 = string.byte('\\')
local extSeparatorChar = string.byte('.')

local tracebackEnable = loggerImpl.SHOW_STACK_TRACE_IN_LUA()
if not tracebackEnable then
    Logger.tracebackEnable = false
else
    Logger.tracebackEnable = (CS.UnityEngine.PlayerPrefs.GetInt("SHOW_STACK_TRACE_IN_LUA", 1) ~= 0)
end

Logger.DevelopmentLogSeverity = LogSeverity.Trace | LogSeverity.Message | LogSeverity.Warning | LogSeverity.Error | LogSeverity.Assert
Logger.NormalLogSeverity = LogSeverity.Error | LogSeverity.Assert
Logger.OffLogSeverity = LogSeverity.Undefined

loggerImpl.SetOnSeverityChanged(function() 
    currentLogSeverity = loggerImpl.GetSeverity():GetHashCode()
end)

local function getFileName(short_src)
    if string.IsNullOrEmpty(short_src) then
        return short_src
    end
    local length = #short_src
    for i = length, 1, -1 do
        if short_src:byte(i) == dirSeparatorChar or short_src:byte(i) == dirSeparatorChar2 then
            if i == length then
                return short_src
            end
            short_src = string.sub(short_src, i + 1, length)
            break
        end
    end
    length = #short_src
    for i = length, 2, -1 do
        if short_src:byte(i) == extSeparatorChar then
            return string.sub(short_src, 1, i - 1)
        end
    end
    return short_src
end

local function formatContent(channel, fmt, ...)
    if nil == channel then
        local info = debug.getinfo(3, 'S')
        if info then
            if not (info.short_src == nil or info.short_src == '') then
                local fileName = getFileName(info.short_src)
                if type(fmt) ~= "string" then
                    return tostring(fmt), fileName
                end
                local success,formattedStr = pcall(string.format, fmt, ...)
                if success then
                    return formattedStr, fileName
                else
                    return tostring(fmt), fileName
                end
            end
        end
        channel = "?"
    end
    if type(fmt) ~= "string" then
        return tostring(fmt), channel
    end
    return string.format(fmt, ...), channel
end

local function getStackInfo(ignoreTracebackSwitch)
    if ignoreTracebackSwitch then
        return debug.traceback(nil,3)
    end
    if Logger.tracebackEnable then
        return debug.traceback(nil,3)
    end
    return nil
end

local function IsFilterType(logSeverity)
    return (currentLogSeverity & logSeverity:GetHashCode()) ~= 0
end

---@param fmt string
---@vararg any
function Logger.Trace(fmt, ...)
    if not IsFilterType(LogSeverity.Trace) then
        return
    end
    local f,fileName = formatContent(nil, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Trace, fileName, f , getStackInfo())
end

---@param channel string @"nil - auto"
---@param fmt string
---@vararg any
function Logger.TraceChannel(channel, fmt, ...)
    if not IsFilterType(LogSeverity.Trace) then
        return
    end
    local f,fileName = formatContent(channel, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Trace, fileName, f, getStackInfo())
end

---@param fmt string
---@vararg any
function Logger.Log(fmt, ...)
    if not IsFilterType(LogSeverity.Message) then
        return
    end
    local f,fileName = formatContent(nil, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Message, fileName, f, getStackInfo())
end

---@param channel string @"nil - auto"
---@param fmt string
---@vararg any
function Logger.LogChannel(channel, fmt, ...)
    if not IsFilterType(LogSeverity.Message) then
        return
    end
    local f,fileName = formatContent(channel, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Message, fileName, f, getStackInfo())
end

---@param fmt string
---@vararg any
function Logger.Warn(fmt, ...)
    if not IsFilterType(LogSeverity.Warning) then
        return
    end
    local f, fileName = formatContent(nil, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Warning, fileName, f, getStackInfo())
end

---@param channel string @"nil - auto"
---@param fmt string
---@vararg any
function Logger.WarnChannel(channel, fmt, ...)
    if not IsFilterType(LogSeverity.Warning) then
        return
    end
    local f,fileName = formatContent(channel, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Warning, fileName, f, getStackInfo())
end

---@param fmt string
---@vararg any
function Logger.Error(fmt, ...)
    if not IsFilterType(LogSeverity.Error) then
        return
    end
    local f, fileName = formatContent(nil, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Error, fileName, f, getStackInfo(USE_UWA))
end

---@param channel string @"nil - auto"
---@param fmt string
---@vararg any
function Logger.ErrorChannel(channel, fmt, ...)
    if not IsFilterType(LogSeverity.Error) then
        return
    end
    local f,fileName = formatContent(channel, fmt, ...)
    loggerImpl.LuaCall(LogSeverity.Error, fileName, f, getStackInfo(USE_UWA))
end

---@param condition any | "boolean"
---@param fmt string
---@vararg any
function Logger.Assert(condition, fmt, ...)
    if not condition then
        if not IsFilterType(LogSeverity.Assert) then
            return
        end
        local f, fileName = formatContent(nil, fmt, ...)
        loggerImpl.LuaCall(LogSeverity.Assert, fileName, f, getStackInfo(USE_UWA))
    end
end

---@param condition any | "boolean"
---@param channel string @"nil - auto"
---@param fmt string
---@vararg any
function Logger.AssertChannel(condition, channel ,fmt, ...)
    if not condition then
        if not IsFilterType(LogSeverity.Assert) then
            return
        end
        local f,fileName = formatContent(channel, fmt, ...)
        loggerImpl.LuaCall(LogSeverity.Assert, fileName, f, getStackInfo(USE_UWA))
    end
end

function Logger.GameShutdown()
    loggerImpl.SetOnSeverityChanged(nil)
end

---@type CS.DragonReborn.LogSeverity
function Logger.SetLogSeverity(logSeverity)
    loggerImpl.SetSeverity(logSeverity)
end

-- for debug usage, do not use
---@private
function Logger.RawUnityLoggerLog(fmt, ...)
    local f, _ = formatContent(string.Empty, fmt, ...)
    loggerImpl.RawUnityDefaultLoggerHandleLog(CS.UnityEngine.LogType.Log, nil, f)
end

Logger.SpChar_Right = "✔︎"
Logger.SpChar_Wrong = "✖︎"

return Logger