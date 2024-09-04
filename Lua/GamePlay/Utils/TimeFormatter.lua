---@type CS.System.DateTimeOffset
local DateTimeOffset = CS.System.DateTimeOffset
local DateTime = CS.System.DateTime
local TimeUtils = CS.TimeUtils
local I18N = require("I18N")
local RefreshType = require("RefreshType")

---@class TimeFormatter
local TimeFormatter = {}
TimeFormatter.OneMinuteSeconds = 60
TimeFormatter.OneHourSeconds = TimeFormatter.OneMinuteSeconds * 60
TimeFormatter.OneDaySeconds = TimeFormatter.OneHourSeconds * 24

---@param seconds number 秒数
---@return string hh:mm:ss
function TimeFormatter.SimpleFormatTime(seconds)
    if not seconds then
        return "--:--:--"
    end
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end
    local h = int // 3600;
    int = int - h * 3600;
    local m = int // 60;
    local s = int % 60;
    return ("%02d:%02d:%02d"):format(h, m, s);
end

---@param seconds number 秒数
---@return string mm:ss
function TimeFormatter.SimpleFormatTimeWithoutHour(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--"
    end
    local h = int // 3600;
    int = int - h * 3600;
    local m = int // 60;
    local s = int % 60;
    return ("%02d:%02d"):format(m, s);
end

---@param seconds number 秒数
---@return string hh:mm:ss
function TimeFormatter.TimerStringFormat(seconds, showZero)
    local int = math.floor(seconds);
    if int ~= int then
        return "0s"
    end
    local h = int // 3600;
    int = int - h * 3600;
    local m = int // 60;
    local s = int % 60;
   
    if h~=0 and s~=0 then
        return ("%02dh%02dm%02ds"):format(h, m, s);
    else
        local retStr = ""
        if h~=0 then
            retStr = retStr .. ("%dh"):format(h)
        end
        if m~=0 then
            retStr = retStr .. ("%dm"):format(m)
        end
        if s~=0 then
            retStr = retStr .. ("%ds"):format(s)
        end
        if string.IsNullOrEmpty(retStr) and showZero then
            return "0s"
        end
        return retStr
    end       
end

---@param seconds number 秒数
---@return string dd hh:mm:ss
function TimeFormatter.SimpleFormatTimeWithDay(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end
    if int > TimeFormatter.OneDaySeconds then
        return string.format("%d Day", int // TimeFormatter.OneDaySeconds)
    end
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return ("%02d:%02d:%02d"):format(h, m, s);
end

---@param seconds number 秒数
---@return string dd hh:mm:ss
function TimeFormatter.SimpleFormatTimeWithDayHour(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end
    if int > TimeFormatter.OneDaySeconds then
        local days = int // TimeFormatter.OneDaySeconds
        int = int - days * TimeFormatter.OneDaySeconds
        local h = int // TimeFormatter.OneHourSeconds;
        return string.format("%dDay%dH", days, h)
    end
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return ("%02d:%02d:%02d"):format(h, m, s);
end

---@param seconds number 秒数
---@return string dd hh:mm:ss
function TimeFormatter.SimpleFormatTimeWithDayHourSeconds(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end

    if int > TimeFormatter.OneDaySeconds then
        local days = int // TimeFormatter.OneDaySeconds
        int = int - days * TimeFormatter.OneDaySeconds
        local h = int // TimeFormatter.OneHourSeconds;
        int = int - h * TimeFormatter.OneHourSeconds;
        local m = int // TimeFormatter.OneMinuteSeconds;
        local s = int % TimeFormatter.OneMinuteSeconds;
        return string.format("%dDay %02d:%02d:%02d", days, h, m, s)
    end

    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return ("%02d:%02d:%02d"):format(h, m, s)
end

---@param seconds number 秒数
---@return string dd hh:mm:ss
function TimeFormatter.SimpleFormatTimeWithDayHourSeconds2(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end

    if int > TimeFormatter.OneDaySeconds then
        local days = int // TimeFormatter.OneDaySeconds
        int = int - days * TimeFormatter.OneDaySeconds
        local h = int // TimeFormatter.OneHourSeconds;
        int = int - h * TimeFormatter.OneHourSeconds;
        local m = int // TimeFormatter.OneMinuteSeconds;
        local s = int % TimeFormatter.OneMinuteSeconds;
        return string.format("%dd %02d:%02d:%02d", days, h, m, s)
    end

    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return ("%02d:%02d:%02d"):format(h, m, s)
end

---@param seconds number 秒数
---@return string hh:mm:ss
function TimeFormatter.SimpleFormatTimeWithoutZero(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end
    local h = int // 3600;
    int = int - h * 3600;
    local m = int // 60;
    local s = int % 60;
    if h > 0 then
        return ("%02d:%02d:%02d"):format(h, m, s);
    elseif m > 0 then
        return ("%02d:%02d"):format(m, s);
    end
    return ("00:%02d"):format(s);
end

---@param formatTime string hh:mm:ss
---@return number seconds 秒数
function TimeFormatter.ParseFormatTimeToSeconds(formatTime)
    local sps = string.split(formatTime, ':')
    local hour = tonumber(sps[1]) or 0
    local minute = tonumber(sps[2]) or 0
    local seconds = tonumber(sps[3]) or 0
    return hour * TimeFormatter.OneHourSeconds + minute * TimeFormatter.OneMinuteSeconds + seconds
end

---@param timeStampSeconds number
---@return CS.System.DateTime
function TimeFormatter.ToDateTime(timeStampSeconds)
    return DateTimeOffset.FromUnixTimeSeconds(math.floor(timeStampSeconds)).UtcDateTime
end

---@return number
function TimeFormatter.GetSecUntilNextDay()
    local now = TimeFormatter.ToDateTime(g_Game.ServerTime:GetServerTimestampInSeconds())
    local tomorrow = now:AddDays(1).Date
    return (tomorrow - now).TotalSeconds
end

TimeFormatter.TimeStampStartDataTime = CS.System.DateTime(1970,1,1, 0, 0,0, CS.System.DateTimeKind.Utc)

---@param dateTime CS.System.DateTime
---@return number
function TimeFormatter.DataTimeToTimeStamp(dateTime)
    return (dateTime - TimeFormatter.TimeStampStartDataTime).TotalSeconds
end

---@param dateTime1 CS.System.DateTime
---@param dateTime2 CS.System.DateTime
function TimeFormatter.InSameDay(dateTime1, dateTime2)
    return dateTime1.Year == dateTime2.Year and dateTime1.Month == dateTime2.Month and dateTime1.Day == dateTime2.Day
end

---@param timeStamp1 number
---@param timeStamp2 number
---@return boolean
function TimeFormatter.InSameDayBySeconds(timeStamp1, timeStamp2)
    local dateTime1 = TimeFormatter.ToDateTime(timeStamp1)
    local dateTime2 = TimeFormatter.ToDateTime(timeStamp2)
    return TimeFormatter.InSameDay(dateTime1, dateTime2)
end

---@param timeStampSeconds number
---@return number,number,number,CS.System.DayOfWeek,"CS.System.TimeSpan"
function TimeFormatter.TimeToDateTime(timeStampSeconds)
    local dateTime = TimeFormatter.ToDateTime(timeStampSeconds)
    return dateTime.Year, dateTime.Month, dateTime.Day, dateTime.DayOfWeek, dateTime.TimeOfDay
end

function TimeFormatter.GetDayStr(day)
    if day == 1 or day == 21 or day == 31 then
        return string.format("%dst", day)
    elseif day == 2 or day == 22 then
        return string.format("%dnd", day)
    elseif day == 3 or day == 23 then
        return string.format("%drd", day)
    end
    return string.format("%dth", day)
end

---@param timeStampSeconds number
---@return string
function TimeFormatter.TimeToDateTimeString(timeStampSeconds)
    local currentCultureInfo = g_Game.LocalizationManager:GetCultureInfo()
    local dateTime = DateTimeOffset.FromUnixTimeSeconds(math.floor(timeStampSeconds)).UtcDateTime
    local month = dateTime:ToString("MMM", currentCultureInfo)
    local year = tostring(dateTime.Year)
    local day = TimeFormatter.GetDayStr(dateTime.Day)
    return string.format("%s %s,%s", month, day, year)
end

---@param timeStampSeconds number
---@param dateTimeFormat string
---@return string
function TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(timeStampSeconds, dateTimeFormat)
    local dateTime = DateTimeOffset.FromUnixTimeSeconds(math.floor(timeStampSeconds)).LocalDateTime
    local currentCultureInfo = g_Game.LocalizationManager:GetCultureInfo()
    return dateTime:ToString(dateTimeFormat, currentCultureInfo)
end

---@param timeStampSeconds number
---@param dateTimeFormat string
---@return string
function TimeFormatter.TimeToDateTimeStringUseFormat(timeStampSeconds, dateTimeFormat)
    local dateTime = DateTimeOffset.FromUnixTimeSeconds(math.floor(timeStampSeconds)).UtcDateTime
    local currentCultureInfo = g_Game.LocalizationManager:GetCultureInfo()
    return dateTime:ToString(dateTimeFormat, currentCultureInfo)
end

---@param timestampInSeconds number
function TimeFormatter.FormatTimesAgo(timestampInSeconds)
    local pastSeconds = g_Game.ServerTime:GetServerTimestampInSeconds() - timestampInSeconds
    if pastSeconds <= TimeFormatter.OneMinuteSeconds then
        -- 刚刚
        return I18N.Get("se_pvp_history_time_1")
    end

    if pastSeconds < TimeFormatter.OneHourSeconds then
        -- {0}分钟以前
        return I18N.GetWithParams("se_pvp_history_time_2", math.floor(pastSeconds / TimeFormatter.OneMinuteSeconds))
    end

    if pastSeconds < TimeFormatter.OneDaySeconds then
        -- {0}小时以前
        return I18N.GetWithParams("se_pvp_history_time_3", math.floor(pastSeconds / TimeFormatter.OneHourSeconds))
    end

    if pastSeconds < TimeFormatter.OneDaySeconds * 7 then
        -- {0}天以前
        return I18N.GetWithParams("se_pvp_history_time_4", math.floor(pastSeconds / TimeFormatter.OneDaySeconds))
    end

    -- 7天以前
    return I18N.Get("se_pvp_history_time_5")
end

---@param timeInSeconds number
---@return string
function TimeFormatter.FormatLastOnlineTime(timeInSeconds)
    if not timeInSeconds or timeInSeconds <= 0 then
        return I18N.Get("online_status_1")
    end
    if timeInSeconds < TimeFormatter.OneMinuteSeconds then
        return I18N.Get("online_status_2")
    end
    if timeInSeconds < TimeFormatter.OneHourSeconds then
        local minutes = math.floor(timeInSeconds // TimeFormatter.OneMinuteSeconds)
        return I18N.GetWithParams("online_status_3", string.format("%d", minutes))
    end
    if timeInSeconds < TimeFormatter.OneDaySeconds then
        local hours = math.floor(timeInSeconds // TimeFormatter.OneHourSeconds)
        return I18N.GetWithParams("online_status_4", string.format("%d", hours))
    end
    local days = math.floor(timeInSeconds // TimeFormatter.OneDaySeconds)
    return I18N.GetWithParams("online_status_5", string.format("%d", days))
end

---@param player wds.AllianceMember
function TimeFormatter.AlliancePlayerLastOnlineTime(player)
    if not player.LatestLogoutTime or not player.LatestLoginTime then
        return TimeFormatter.FormatLastOnlineTime(nil)
    end
    if player.LatestLogoutTime.ServerSecond <= 0 or player.LatestLogoutTime.ServerSecond < player.LatestLoginTime.ServerSecond then
        return TimeFormatter.FormatLastOnlineTime(nil)
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local passTime = nowTime - player.LatestLogoutTime.ServerSecond
    return TimeFormatter.FormatLastOnlineTime(passTime)
end

---@param timeStamp number UTC时间戳毫秒
function TimeFormatter.GetFormatCompleteTime(timeStamp)
    local mhourStr, mminuteStr, secondStr = TimeUtils.GetLocalTimeStr00(timeStamp)
    return string.format("%s %s:%s:%s", TimeUtils.GetLocalDateStr(timeStamp), mhourStr, mminuteStr, secondStr)
end

function TimeFormatter.AllianceCurrencyLogTime(timeStamp, nowTime)
    local passTime = nowTime - timeStamp
    if passTime < TimeFormatter.OneHourSeconds then
        return I18N.GetWithParams("alliance_resource_fenzhong", tostring(math.floor(passTime / TimeFormatter.OneMinuteSeconds)))
    end
    if passTime < TimeFormatter.OneDaySeconds then
        return I18N.GetWithParams("alliance_resource_xiaoshiqian", tostring(math.floor(passTime / TimeFormatter.OneHourSeconds)))
    end
    return TimeFormatter.TimeToDateTimeStringUseFormat(timeStamp, "yyyy.MM.dd")
end

function TimeFormatter.GetTomorrowMidnight()
    local today = DateTime.Now.Date
    local tomorrow = today:AddDays(1)
    return tomorrow
end

---@class DHMSTimeTable
---@field day number
---@field hour number
---@field minute number
---@field second number

---@param seconds number
---@return DHMSTimeTable
function TimeFormatter.GetTimeTableInDHMS(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return {day = 0, hour = 0, minute = 0, second = 0}
    end
    local d = int // TimeFormatter.OneDaySeconds;
    int = int - d * TimeFormatter.OneDaySeconds;
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return {day = d, hour = h, minute = m, second = s}
end

---@param dayOfWeek CS.System.DayOfWeek
---@return number
function TimeFormatter.GetValueOfDayOfWeek(dayOfWeek)
    if dayOfWeek == CS.System.DayOfWeek.Sunday then
        return 0
    elseif dayOfWeek == CS.System.DayOfWeek.Monday then
        return 1
    elseif dayOfWeek == CS.System.DayOfWeek.Tuesday then
        return 2
    elseif dayOfWeek == CS.System.DayOfWeek.Wednesday then
        return 3
    elseif dayOfWeek == CS.System.DayOfWeek.Thursday then
        return 4
    elseif dayOfWeek == CS.System.DayOfWeek.Friday then
        return 5
    elseif dayOfWeek == CS.System.DayOfWeek.Saturday then
        return 6
    end
end

---@param refreshConfig RefreshConfigCell
---@return number
function TimeFormatter.GetRefreshTime(refreshConfig, nearestNext)
    if not refreshConfig then
        return nil
    end
    local t = refreshConfig:Type()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local nowTimeDateTime = TimeFormatter.ToDateTime(nowTime)
    local today = nowTimeDateTime.Date
    local timeOffsetStr = refreshConfig:Param()
    local timeParseSuccess,addTime
    if string.IsNullOrEmpty(timeOffsetStr) then
        addTime = CS.System.TimeSpan() or CS.System.TimeSpan.Parse(timeOffsetStr)
    else
        timeParseSuccess,addTime = CS.System.TimeSpan.TryParse(timeOffsetStr)
        if not timeParseSuccess then
            addTime = CS.System.TimeSpan()
        end
    end
    local currentRefreshTime
    local days = 0
    local offsetDays = 0
    if t == RefreshType.Daily then
        currentRefreshTime = today:Add(addTime)
        offsetDays = 1
    elseif t == RefreshType.Weekly then
        days = TimeFormatter.GetValueOfDayOfWeek(today.DayOfWeek)
        offsetDays = 7
    elseif t == RefreshType.Monthly then
        days = today.Day - 1
        local nextMouth = today:AddMonths(1)
        offsetDays = nextMouth:Subtract(today).Days
    elseif t == RefreshType.Yearly then
        days = today.DayOfYear - 1
        local nextYear = today:AddYears(1)
        offsetDays = nextYear:Subtract(today).Days
    else
        g_Logger.Error("unsupported refresh type:%s", t)
        return nil
    end
    local offsetStart = today:AddDays(-1 * days)
    currentRefreshTime = offsetStart:Add(addTime)
    if nearestNext then
        if currentRefreshTime:CompareTo(nowTimeDateTime) <= 0 then
            currentRefreshTime = currentRefreshTime:AddDays(offsetDays)
        end
    end
    return TimeFormatter.DataTimeToTimeStamp(currentRefreshTime)
end

return TimeFormatter
