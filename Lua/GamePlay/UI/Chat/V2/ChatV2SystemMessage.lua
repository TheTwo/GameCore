local BaseUIComponent = require ('BaseUIComponent')
local TimeUtils = CS.TimeUtils
local FORMAT_TIME_INDAY = "%s:%s"
local FORMAT_TIME_YESTERDAY = "%s %s:%s"
local FORMAT_TIME_FULL = "%s %s:%s"

local I18N_YESTERDAY = "chat_timestamp"
local I18N = require("I18N")

---@class ChatV2SystemMessage:BaseUIComponent
local ChatV2SystemMessage = class('ChatV2SystemMessage', BaseUIComponent)

function ChatV2SystemMessage:OnCreate()
    self._p_text_hint = self:Text("p_text_hint")
end

---@class ChatV2SystemMessageData
---@field isTimeStamp boolean
---@field isHint boolean
---@field time number
---@field text string

---@param data ChatV2SystemMessageData
function ChatV2SystemMessage:OnFeedData(data)
    self.data = data

	-- 时间戳
	if (self.data.isTimeStamp) then
		local timestamp = math.floor(g_Game.ServerTime:GetServerTimestampInMilliseconds())
		local nyear, nmonth, nday = TimeUtils.GetLocalDateTime(timestamp)
		local myear, mmonth, mday = TimeUtils.GetLocalDateTime(self.data.time)
		local yyear, ymonth, yday = TimeUtils.GetLocalYesterdayDate(timestamp)
		
		-- 同一天内
		if (nyear == myear and nmonth == mmonth and nday == mday) then
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self._p_text_hint.text = string.format(FORMAT_TIME_INDAY, mhourStr, mminuteStr)

		-- 昨天
		elseif (myear == yyear and mmonth == ymonth and mday == yday) then
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self._p_text_hint.text = string.format(FORMAT_TIME_YESTERDAY, I18N.Get(I18N_YESTERDAY), mhourStr, mminuteStr)

		-- 其他
		else
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self._p_text_hint.text = string.format(FORMAT_TIME_FULL, TimeUtils.GetLocalDateStr(self.data.time), mhourStr, mminuteStr)
		end

	-- 提示
	elseif (self.data.isHint) then
		self._p_text_hint.text = self.data.text
	end
end

return ChatV2SystemMessage