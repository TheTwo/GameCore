local Utils = require("Utils")
local TimeFormatter = require("TimeFormatter")
---@class DoNotShowAgainHelper
local DoNotShowAgainHelper = {}

local Cycle = {
    Daily = 1,
    Forever = 2,
}

DoNotShowAgainHelper.Cycle = Cycle

---@param key string
function DoNotShowAgainHelper.SetDoNotShowAgain(key)
    if Utils.IsNullOrEmpty(key) then
        return
    end
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()

    local value = tonumber(curTimeSec)
    g_Game.PlayerPrefsEx:SetStringByUid(key, value)
end

---@param key string
function DoNotShowAgainHelper.RemoveDoNotShowAgain(key)
    if Utils.IsNullOrEmpty(key) then
        return
    end
    g_Game.PlayerPrefsEx:SetStringByUid(key, "0")
end

---@param key string
---@param cycle number @default Daily
function DoNotShowAgainHelper.CanShowAgain(key, cycle)
    if Utils.IsNullOrEmpty(key) then
        return true
    end
    local lastShowTime = g_Game.PlayerPrefsEx:GetStringByUid(key, "0")
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastShowTimeSec = tonumber(lastShowTime)
    if lastShowTimeSec == 0 then
        return true
    end
    if cycle == Cycle.Daily then
        return not TimeFormatter.InSameDayBySeconds(lastShowTimeSec, curTimeSec)
    elseif cycle == Cycle.Forever then
        return false
    end
end

return DoNotShowAgainHelper