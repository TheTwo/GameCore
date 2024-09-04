---@class ServerTime
---@field new fun():ServerTime
local ServerTime = class('ServerTime', require("BaseManager"))

function ServerTime:ctor()
	self:Reset()
end

function ServerTime:Reset()
	self.syncServerTimestampInMilliseconds = CS.TimeUtils.GetCurrentUtcTimestamp()
	self.syncLocalTimestampInSeconds = g_Game.Time.realtimeSinceStartup
	self.sync = false
end

---@param timestamp number @comment 毫秒级时间戳
function ServerTime:SetServerTime(timestamp)
	if self.syncServerTimestampInMilliseconds < timestamp or not self.sync then
		self.syncServerTimestampInMilliseconds = timestamp
		self.syncLocalTimestampInSeconds = g_Game.Time.realtimeSinceStartup
		self.sync = true
	end
end

---@return number
function ServerTime:GetServerTimestampInMilliseconds()
	local duration = self:GetRealTimeSinceLastSync()
	return math.floor(self.syncServerTimestampInMilliseconds + duration * 1000)
end

---@return number
function ServerTime:GetServerTimestampInSeconds()
	local duration = self:GetRealTimeSinceLastSync()
	return math.floor(self.syncServerTimestampInMilliseconds / 1000 + duration)
end

---@return number
function ServerTime:GetServerTimestampInSecondsNoFloor()
    local duration = self:GetRealTimeSinceLastSync()
    return self.syncServerTimestampInMilliseconds / 1000 + duration
end

function ServerTime:GetServerTimestampInDays()
	--86400 = 24 * 60 * 60
	return math.floor( self:GetServerTimestampInSeconds() / 86400 )
end

---@return number
function ServerTime:GetRealTimeSinceLastSync()
	return g_Game.Time.realtimeSinceStartup - self.syncLocalTimestampInSeconds
end

---@class TimeTable
---@field hour number
---@field min number
---@field sec number

---@return TimeTable
function ServerTime:GetServerTimeTable()
	---86400 = 24 * 60 * 60
	local timestampInSeconds = math.floor(self:GetServerTimestampInSeconds())
	local seconds = math.floor(timestampInSeconds % 86400)
	---@type TimeTable
	local ret = {}
	ret.hour = math.floor(seconds / 3600 )
	seconds = seconds % 3600
	ret.min = math.floor(seconds / 60)
	seconds = seconds % 60
	ret.sec = seconds
	return ret
end

return ServerTime