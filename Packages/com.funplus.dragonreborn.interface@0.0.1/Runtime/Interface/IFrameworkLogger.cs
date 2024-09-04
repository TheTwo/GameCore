using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    [UnityEngine.Scripting.RequireImplementors]
    public interface IFrameworkLogger : IFrameworkInterface<IFrameworkLogger>
    {
        bool SHOW_STACK_TRACE_IN_LUA();
        void LuaCall(LogSeverity logSeverity, string channel, string luaMessage, string luaStack);
        void Trace(string message, params object[] param);
        void Trace(Color32 color, string message, params object[] param);
        void TraceChannel(string channel, string message, params object[] param);
        void Log(string message, params object[] param);
        void Log(Color32 color, string message, params object[] param);
        void LogChannel(string channel, string message, params object[] param);
        void LogChannel(Color32 color, string channel, string message, params object[] param);
        void Warn(string message, params object[] param);
        void WarnChannel(string channel, string message, params object[] param);
        void Error(string message, params object[] param);
        void ErrorChannel(string channel, string message, params object[] param);
        void Assert(bool condition, string message, params object[] param);
        void SetSeverity(LogSeverity severity);
        LogSeverity GetSeverity();
        void SetOnSeverityChanged(System.Action callBack);
        void RawUnityDefaultLoggerHandleLog(LogType logType, Object context, string format, params object[] args);
        void RawUnityDefaultLoggerHandleException(System.Exception exception, Object context);
    }
}