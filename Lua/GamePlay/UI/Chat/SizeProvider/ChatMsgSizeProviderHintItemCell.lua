local BaseUIComponent = require ('BaseUIComponent')
local TimeUtils = CS.TimeUtils
local FORMAT_TIME_INDAY = "%s:%s"
local FORMAT_TIME_YESTERDAY = "%s %s:%s"
local FORMAT_TIME_FULL = "%s %s:%s"
local I18N_YESTERDAY = "chat_timestamp"

local I18N = require("I18N")

---@class ChatMsgSizeProviderHintItemCell:BaseUIComponent
local ChatMsgSizeProviderHintItemCell = class('ChatMsgSizeProviderHintItemCell', BaseUIComponent)

function ChatMsgSizeProviderHintItemCell:OnCreate()
	self.textHint = self:Text("p_text_hint")
end

function ChatMsgSizeProviderHintItemCell:OnFeedData(param)
    if (not param) then return end
	self.data = param

	-- 时间戳
	if (self.data.isTimeStamp) then
		local timestamp = math.floor(g_Game.ServerTime:GetServerTimestampInMilliseconds())
		local nyear, nmonth, nday = TimeUtils.GetLocalDateTime(timestamp)
		local myear, mmonth, mday = TimeUtils.GetLocalDateTime(self.data.time)
		local yyear, ymonth, yday = TimeUtils.GetLocalYesterdayDate(timestamp)
		
		-- 同一天内
		if (nyear == myear and nmonth == mmonth and nday == mday) then
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self.textHint.text = string.format(FORMAT_TIME_INDAY, mhourStr, mminuteStr)

		-- 昨天
		elseif (myear == yyear and mmonth == ymonth and mday == yday) then
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self.textHint.text = string.format(FORMAT_TIME_YESTERDAY, I18N.Get(I18N_YESTERDAY), mhourStr, mminuteStr)

		-- 其他
		else
			local mhourStr, mminuteStr = TimeUtils.GetLocalTimeStr00(self.data.time)
			self.textHint.text = string.format(FORMAT_TIME_FULL, TimeUtils.GetLocalDateStr(self.data.time), mhourStr, mminuteStr)
		end

	-- 提示
	elseif (self.data.isHint) then
		self.textHint.text = self.data.text
	end
end

return ChatMsgSizeProviderHintItemCell