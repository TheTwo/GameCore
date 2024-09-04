---@class DebugExceptionHandle
---@field new fun():DebugExceptionHandle
local DebugExceptionHandle = class("DebugExceptionHandle")

function DebugExceptionHandle:OnLuaException(exceptionString)
    local I18N = require("I18N")
    if UNITY_EDITOR or UNITY_DEBUG then
        g_Game:RestartGameManually(("[EX]%s"):format(I18N.Get("error_feedback_title")), "#Lua异常", exceptionString, true)
    else
        g_Game:RestartGameManually(("[EX]%s"):format(I18N.Get("error_feedback_title")), I18N.Get("errCode_Fallback"), exceptionString, true)
    end
end

function DebugExceptionHandle:OnCSharpException(exceptionString)
    local I18N = require("I18N")
    if UNITY_EDITOR or UNITY_DEBUG then
        g_Game:RestartGameManually(("[EX]%s"):format(I18N.Get("error_feedback_title")), "#CSharp异常", exceptionString, true)
    else
        g_Game:RestartGameManually(("[EX]%s"):format(I18N.Get("error_feedback_title")), I18N.Get("errCode_Fallback"), exceptionString, true)
    end
end

return DebugExceptionHandle