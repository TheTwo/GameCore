---@class ReleaseExceptionHandle
---@field new fun():ReleaseExceptionHandle
local ReleaseExceptionHandle = class("ReleaseExceptionHandle")

function ReleaseExceptionHandle:ctor()
    self.exceptionBudgetSize = 3
    self.exceptionBudget = {}
end

function ReleaseExceptionHandle:OnLuaException(exceptionString)
    self:OnException(exceptionString)
end

function ReleaseExceptionHandle:OnCSharpException(exceptionString)
    self:OnException(exceptionString)
end

function ReleaseExceptionHandle:OnException(exceptionString)
	--及时暴露问题,防止后续出现不可预知的问题
    --if #self.exceptionBudget < self.exceptionBudgetSize then
    --    table.insert(self.exceptionBudget, {exception = exceptionString, time = CS.UnityEngine.Time.realtimeSinceStartup})
    --    return
    --end
	--
    --local firstExWrap = table.remove(self.exceptionBudget, 1)
    --if firstExWrap.time + 60 < CS.UnityEngine.Time.realtimeSinceStartup then
    --    table.insert(self.exceptionBudget, {exception = exceptionString, time = CS.UnityEngine.Time.realtimeSinceStartup})
    --    return
    --end

    local I18N = require("I18N")
    g_Game:RestartGameManually(("[EX]%s"):format(I18N.Get("error_feedback_title")), I18N.Get("errCode_Fallback"), exceptionString, true)
end

return ReleaseExceptionHandle
