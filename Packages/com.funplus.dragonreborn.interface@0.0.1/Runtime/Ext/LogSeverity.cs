using System;
using System.Collections.Generic;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static class LogSeverityHelper
    {
        public static LogSeverity ToLogSeverity(this LogType logType)
        {
            switch (logType)
            {
                case LogType.Error:
                    return LogSeverity.Error;
                case LogType.Assert:
                    return LogSeverity.Assert;
                case LogType.Warning:
                    return LogSeverity.Warning;
                case LogType.Log:
                    return LogSeverity.Message;
                case LogType.Exception:
                    return LogSeverity.Error;
                default:
#if UNITY_DEBUG
                    throw new ArgumentOutOfRangeException(nameof(logType), logType, null);
#else
                    return LogSeverity.Assert;
#endif
            }
        }

        public static LogType ToLogType(this LogSeverity logSeverity)
        {
            switch (logSeverity)
            {
                case LogSeverity.Trace:
                case LogSeverity.Message:
                    return LogType.Log;
                case LogSeverity.Warning:
                    return LogType.Warning;
                case LogSeverity.Error:
                    return LogType.Error;
                case LogSeverity.Assert:
                    return LogType.Assert;
                // ReSharper disable once RedundantCaseLabel
                case LogSeverity.Undefined:
                default:
#if UNITY_DEBUG
                    throw new ArgumentOutOfRangeException(nameof(logSeverity), logSeverity, null);
#else
                    return LogType.Assert;
#endif
            }
        }
    }
}