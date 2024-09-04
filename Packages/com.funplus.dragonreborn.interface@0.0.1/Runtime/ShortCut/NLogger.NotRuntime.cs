using System;
using UnityEngine;
using Debug = UnityEngine.Debug;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static partial class NLogger
    {
#if UNITY_EDITOR
        private static void OnEnterEditor()
        {
            LoggerImpl = new NoneRuntimeLogger();
        }
        
        [UnityEditor.InitializeOnEnterPlayMode]
        private static void OnEnterGame()
        {
            static void PlayModeChange(UnityEditor.PlayModeStateChange playModeStateChange)
            {
                if (playModeStateChange != UnityEditor.PlayModeStateChange.EnteredEditMode) return;
                UnityEditor.EditorApplication.playModeStateChanged -= PlayModeChange;
                OnEnterEditor();
            }

            UnityEditor.EditorApplication.playModeStateChanged += PlayModeChange;
        }
#endif

        private class NoneRuntimeLogger : IFrameworkLogger
        {
            private static string Format(string fmt, params object[] param)
            {
                return param?.Length > 0 ? string.Format(fmt, param) : fmt;
            }
            
            bool IFrameworkLogger.SHOW_STACK_TRACE_IN_LUA() => true;

            void IFrameworkLogger.LuaCall(LogSeverity logSeverity, string channel, string luaMessage, string luaStack)
            {
                switch (logSeverity)
                {
                    case LogSeverity.Warning:
                        Debug.LogWarningFormat(null, "[{0}]{1}\n{2}", channel, luaMessage, luaStack);
                        break;
                    case LogSeverity.Error:
                    case LogSeverity.Assert:
                        Debug.LogFormat(null, "{0}", luaMessage);
                        Debug.LogErrorFormat(null, "[{0}]{1}\n{2}", channel, luaMessage, luaStack);
                        break;
                    default:
                        Debug.LogFormat(null, "[{0}]{1}\n{2}", channel, luaMessage, luaStack);
                        break;
                }
            }

            void IFrameworkLogger.Trace(string message, params object[] param)
            {
                Debug.LogFormat(null, message, param);
            }

            void IFrameworkLogger.Trace(Color32 color, string message, params object[] param)
            {
                Debug.LogFormat(null, "<color=#{0:X2}{1:X2}{2:X2}>{3}</color>", color.r, color.g, color.b, Format(message, param));
            }

            void IFrameworkLogger.TraceChannel(string channel, string message, params object[] param)
            {
                Debug.LogFormat(null, "[{0}]{1}", channel, Format(message, param));
            }

            void IFrameworkLogger.Log(string message, params object[] param)
            {
                Debug.LogFormat(null, message, param);
            }

            void IFrameworkLogger.Log(Color32 color, string message, params object[] param)
            {
                Debug.LogFormat(null, "<color=#{0:X2}{1:X2}{2:X2}>{3}</color>", color.r, color.g, color.b, Format(message, param));
            }

            void IFrameworkLogger.LogChannel(string channel, string message, params object[] param)
            {
                Debug.LogFormat(null, "[{0}]{1}", channel, Format(message, param));
            }

            void IFrameworkLogger.LogChannel(Color32 color, string channel, string message, params object[] param)
            {
                Debug.LogFormat(null, "<color=#{0:X2}{1:X2}{2:X2}>[{3}]{4}</color>", color.r, color.g, color.b, channel, Format(message, param));
            }

            void IFrameworkLogger.Warn(string message, params object[] param)
            {
                Debug.LogWarningFormat(null, message, param);
            }

            void IFrameworkLogger.WarnChannel(string channel, string message, params object[] param)
            {
                Debug.LogWarningFormat(null, "[{0}]{1}", channel, Format(message, param));
            }

            void IFrameworkLogger.Error(string message, params object[] param)
            {
                Debug.LogErrorFormat(null, message, param);
            }

            void IFrameworkLogger.ErrorChannel(string channel, string message, params object[] param)
            {
                Debug.LogErrorFormat(null, "[{0}]{1}", channel, Format(message, param));
            }

            void IFrameworkLogger.Assert(bool condition, string message, params object[] param)
            {
                Debug.AssertFormat(condition, message, param);
            }

            void IFrameworkLogger.SetSeverity(LogSeverity severity)
            {
                //ignore
            }

            LogSeverity IFrameworkLogger.GetSeverity()
            {
                return ~LogSeverity.Undefined;
            }

            void IFrameworkLogger.SetOnSeverityChanged(Action callBack)
            {
                //ignore
            }

            void IFrameworkLogger.RawUnityDefaultLoggerHandleLog(LogType logType, UnityEngine.Object context, string format, params object[] args)
            {
                //ignore
            }

            void IFrameworkLogger.RawUnityDefaultLoggerHandleException(Exception exception, UnityEngine.Object context)
            {
                //ignore
            }
        }
    }
}