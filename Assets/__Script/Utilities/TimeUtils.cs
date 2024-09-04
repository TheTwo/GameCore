using System;
using System.Globalization;

public static class TimeUtils
{
	private static DateTime? _serverTime;

	/// <summary>
	/// 使用服务器时间
	/// </summary>
	/// <param name="serverTimeMs">以毫秒为单位的时间戳</param>
	public static void UseServerTime(long serverTimeMs)
	{
		_serverTime = GetDateTimeFromTimestampMilliseconds(serverTimeMs);
	}

	/// <summary>
	/// 使用本地时间
	/// </summary>
	public static void UseLocalTime()
	{
		_serverTime = null;
	}

	/// <summary>
	/// 通过以秒为单位的时间戳获取剩余时间
	/// </summary>
	/// <param name="seconds">秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="hour">小时数</param>
	/// <param name="minute">分钟数</param>
	/// <param name="second">秒数</param>
	public static void GetRemainTimeFromTimestampSeconds(int seconds, out int day, out int hour, out int minute, out int second)
	{
		GetRemainTimeFromTimestampMilliseconds(seconds * 1000L, out day, out hour, out minute, out second);
	}

	/// <summary>
	/// 通过以秒为单位的时间戳获取剩余时间（字符串格式）
	/// </summary>
	/// <param name="seconds">秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="dayFormat">天数格式</param>
	/// <param name="dayStr">天数字串</param>
	/// <param name="hour">小时数</param>
	/// <param name="hourFormat">小时数格式</param>
	/// <param name="hourStr">小时数字串</param>
	/// <param name="minute">分钟数</param>
	/// <param name="minuteFormat">分钟数格式</param>
	/// <param name="minuteStr">分钟数字串</param>
	/// <param name="second">秒数</param>
	/// <param name="secondFormat">秒数格式</param>
	/// <param name="secondStr">秒数字串</param>
	public static void GetRemainTimeWithFormatStrFromTimestampSeconds(int seconds, 
		string dayFormat, string hourFormat, string minuteFormat, string secondFormat,
		out int day, out string dayStr, 
		out int hour, out string hourStr, 
		out int minute, out string minuteStr, 
		out int second, out string secondStr)
	{
		GetRemainTimeWithFormatStrFromTimestampMilliseconds(seconds * 1000L, dayFormat, hourFormat, minuteFormat, secondFormat, 
			out day, out dayStr, out hour, out hourStr, out minute, out minuteStr, out second, out secondStr);
	}

	/// <summary>
	/// 通过以毫秒为单位的时间戳获取剩余时间
	/// </summary>
	/// <param name="ms">毫秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="hour">小时数</param>
	/// <param name="minute">分钟数</param>
	/// <param name="second">秒数</param>
	public static void GetRemainTimeFromTimestampMilliseconds(long ms, out int day, out int hour, out int minute, out int second)
	{
		TimeSpan ts = new(GetDateTimeFromTimestampMilliseconds(ms).Ticks - (_serverTime.HasValue ? _serverTime.Value.Ticks : DateTime.Now.Ticks));
		day = ts.Days;
		hour = ts.Hours;
		minute = ts.Minutes;
		second = ts.Seconds;
	}

	/// <summary>
	/// 通过以毫秒为单位的时间戳获取剩余时间（包含字符串格式）
	/// </summary>
	/// <param name="ms">毫秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="dayFormat">天数格式</param>
	/// <param name="dayStr">天数字串</param>
	/// <param name="hour">小时数</param>
	/// <param name="hourFormat">小时数格式</param>
	/// <param name="hourStr">小时数字串</param>
	/// <param name="minute">分钟数</param>
	/// <param name="minuteFormat">分钟数格式</param>
	/// <param name="minuteStr">分钟数字串</param>
	/// <param name="second">秒数</param>
	/// <param name="secondFormat">秒数格式</param>
	/// <param name="secondStr">秒数字串</param>
	public static void GetRemainTimeWithFormatStrFromTimestampMilliseconds(long ms, 
		string dayFormat, string hourFormat, string minuteFormat, string secondFormat, 
		out int day, out string dayStr, 
		out int hour, out string hourStr, 
		out int minute, out string minuteStr, 
		out int second, out string secondStr)
	{
		TimeSpan ts = new(GetDateTimeFromTimestampMilliseconds(ms).Ticks - (_serverTime.HasValue ? _serverTime.Value.Ticks : DateTime.Now.Ticks));
		day = ts.Days;
		dayStr = day.ToString(dayFormat);
		hour = ts.Hours;
		hourStr = hour.ToString(hourFormat);
		minute = ts.Minutes;
		minuteStr = minute.ToString(minuteFormat);
		second = ts.Seconds;
		secondStr = second.ToString(secondFormat);
	}

	/// <summary>
	/// 通过以秒为单位的时间戳获取经过时间
	/// </summary>
	/// <param name="seconds">秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="hour">小时数</param>
	/// <param name="minute">分钟数</param>
	/// <param name="second">秒数</param>
	public static void GetElapsedTimeFromTimestampSeconds(int seconds, out int day, out int hour, out int minute, out int second)
	{
		GetElapsedTimeFromTimestampMilliseconds(seconds * 1000L, out day, out hour, out minute, out second);
	}

	/// <summary>
	/// 通过以毫秒为单位的时间戳获取经过时间
	/// </summary>
	/// <param name="ms">毫秒时间戳</param>
	/// <param name="day">天数</param>
	/// <param name="hour">小时数</param>
	/// <param name="minute">分钟数</param>
	/// <param name="second">秒数</param>
	public static void GetElapsedTimeFromTimestampMilliseconds(long ms, out int day, out int hour, out int minute, out int second)
	{
		TimeSpan ts = new((_serverTime.HasValue ? _serverTime.Value.Ticks : DateTime.Now.Ticks) - GetDateTimeFromTimestampMilliseconds(ms).Ticks);
		day = ts.Days;
		hour = ts.Hours;
		minute = ts.Minutes;
		second = ts.Seconds;
	}

	/// <summary>
	/// 通过以秒为单位的时间戳获取日期
	/// </summary>
	/// <param name="seconds">秒时间戳</param>
	/// <returns></returns>
	public static DateTime GetDateTimeFromTimestampSeconds(int seconds)
	{
		return GetDateTimeFromTimestampMilliseconds(seconds * 1000L);
	}

	/// <summary>
	/// 通过以毫秒为单位的时间戳获取日期
	/// </summary>
	/// <param name="ms">毫秒时间戳</param>
	/// <returns></returns>
	public static DateTime GetDateTimeFromTimestampMilliseconds(long ms)
	{
		return new DateTime(1970, 1, 1).AddMilliseconds(ms).ToLocalTime();
	}

	/// <summary>
	/// 通过以秒为单位的时间戳获取日期字符串
	/// </summary>
	/// <param name="seconds">秒时间戳</param>
	/// <param name="langCode">语言代码</param>
	/// <returns></returns>
	public static string GetDateStringFromTimestampSeconds(int seconds, string langCode = "zh-CN")
	{
		var cultureInfo = CultureInfo.GetCultureInfo(langCode);
		return GetDateTimeFromTimestampSeconds(seconds).ToString("d", cultureInfo);
	}

	/// <summary>
	/// 通过以毫秒为单位的时间戳获取日期字符串
	/// </summary>
	/// <param name="ms">毫秒时间戳</param>
	/// <param name="langCode">语言代码</param>
	/// <returns></returns>
	public static string GetDateStringFromTimestampMilliseconds(long ms, string langCode = "zh-CN")
	{
		var cultureInfo = CultureInfo.GetCultureInfo(langCode);
		return GetDateTimeFromTimestampMilliseconds(ms).ToString("d", cultureInfo);
	}

	/// <summary>
	/// 获取当前时区的日期时间
	/// </summary>
	/// <param name="utcTimestamp">UTC时间戳</param>
	/// <returns></returns>
	public static void GetLocalDateTime(long utcTimestamp, out int year, out int month, out int day, out int hour, out int minute, out int second, out int ms)
	{
		var dt = DateTimeOffset.FromUnixTimeMilliseconds(utcTimestamp).LocalDateTime;
		year = dt.Year;
		month = dt.Month;
		day = dt.Day;
		hour = dt.Hour;
		minute = dt.Minute;
		second = dt.Second;
		ms = dt.Millisecond;
	}

	/// <summary>
	/// 获取当前时区的昨天日期
	/// </summary>
	/// <param name="utcTimestamp">UTC时间戳</param>
	/// <returns></returns>
	public static void GetLocalYesterdayDate(long utcTimestamp, out int year, out int month, out int day)
	{
		var dt = DateTimeOffset.FromUnixTimeMilliseconds(utcTimestamp).LocalDateTime.AddDays(-1);
		year = dt.Year;
		month = dt.Month;
		day = dt.Day;
	}

	/// <summary>
	/// 获取当前时区的时间字符串(2位)
	/// </summary>
	/// <param name="utcTimestamp">UTC时间戳毫秒</param>
	/// <returns></returns>
	public static void GetLocalTimeStr00(long utcTimestamp, out string hourStr, out string minuteStr, out string secondStr)
	{
		var dt = DateTimeOffset.FromUnixTimeMilliseconds(utcTimestamp).LocalDateTime;
		hourStr = dt.Hour.ToString("00");
		minuteStr = dt.Minute.ToString("00");
		secondStr = dt.Second.ToString("00");
	}

	/// <summary>
	/// 获取当前时区的日期字符串(使用本地格式)
	/// </summary>
	/// <param name="utcTimestamp">UTC时间戳毫秒</param>
	/// <returns></returns>
	public static string GetLocalDateStr(long utcTimestamp)
	{
		var dt = DateTimeOffset.FromUnixTimeMilliseconds(utcTimestamp).LocalDateTime;
		return dt.ToShortDateString();
	}

	/// <summary>
	/// 获取当前Utc时间的毫秒时间戳
	/// </summary>
	/// <returns></returns>
	public static long GetCurrentUtcTimestamp()
	{
		var ts = DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, 0);
		return Convert.ToInt64(ts.TotalMilliseconds);
	}
}
