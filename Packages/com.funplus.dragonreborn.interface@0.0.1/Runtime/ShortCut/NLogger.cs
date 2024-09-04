using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static partial class NLogger
    {
        internal static IFrameworkLogger LoggerImpl = new NoneRuntimeLogger();

        public static bool SHOW_STACK_TRACE_IN_LUA()
        {
            return LoggerImpl?.SHOW_STACK_TRACE_IN_LUA() ?? false;
        }
        
        public static void LuaCall(LogSeverity logSeverity, string channel, string luaMessage, string luaStack)
        {
            LoggerImpl?.LuaCall(logSeverity, channel, luaMessage, luaStack);
        }

        public static void Trace(string message, params object[] param)
        {
            LoggerImpl?.Trace(message, param);
        }

        public static void Trace(Color32 color, string message, params object[] param)
        {
            LoggerImpl?.Trace(color, message, param);
        }

        public static void TraceChannel(string channel, string message, params object[] param)
        {
            LoggerImpl?.TraceChannel(channel, message, param);
        }

        public static void Log(string message, params object[] param)
        {
            LoggerImpl?.Log(message, param);
        }

        public static void Log(Color32 color, string message, params object[] param)
        {
            LoggerImpl?.Log(color, message, param);
        }

        public static void LogChannel(string channel, string message, params object[] param)
        {
            LoggerImpl?.LogChannel(channel, message, param);
        }

        public static void LogChannel(Color32 color, string channel, string message, params object[] param)
        {
            LoggerImpl?.LogChannel(color, channel, message, param);
        }

        public static void Warn(string message, params object[] param)
        {
            LoggerImpl?.Warn(message, param);
        }

        public static void WarnChannel(string channel, string message, params object[] param)
        {
            LoggerImpl?.WarnChannel(channel, message, param);
        }

        public static void Error(string message, params object[] param)
        {
            LoggerImpl?.Error(message, param);
        }

        public static void ErrorChannel(string channel, string message, params object[] param)
        {
            LoggerImpl?.ErrorChannel(channel, message, param);
        }

        public static void Assert(bool condition, string message, params object[] param)
        {
            LoggerImpl?.Assert(condition, message, param);
        }

        public static void SetSeverity(LogSeverity severity)
        {
            LoggerImpl?.SetSeverity(severity);
        }

        public static LogSeverity GetSeverity()
        {
            return LoggerImpl?.GetSeverity() ?? default;
        }

        public static void SetOnSeverityChanged(System.Action callBack)
        {
            LoggerImpl?.SetOnSeverityChanged(callBack);
        }

        public static void RawUnityDefaultLoggerHandleLog(LogType logType, Object context, string format,
            params object[] args)
        {
            LoggerImpl?.RawUnityDefaultLoggerHandleLog(logType, context, format, args);
        }

        public static void RawUnityDefaultLoggerHandleException(System.Exception exception, Object context)
        {
            LoggerImpl?.RawUnityDefaultLoggerHandleException(exception, context);
        }
    }
}