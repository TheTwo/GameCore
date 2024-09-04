using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    [Flags]
    public enum LogSeverity
    {
        Undefined = 0,
        Trace = 1,
        Message = 1 << 1,
        Warning = 1 << 2,
        Error = 1 << 3,
        Assert = 1 << 4,
    }
}