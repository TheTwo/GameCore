// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public readonly struct ConsoleEntry
    {
        public readonly string Channel;
        public readonly LogSeverity Severity;
        public readonly string Message;
        public readonly long FrameCount;
        public readonly double UpTime;
        public readonly string StackText;
        
        public ConsoleEntry(string channel, LogSeverity severity, string message, long frameCount, double upTime, string stackText)
        {
            Channel = channel;
            Severity = severity;
            Message = message;
            FrameCount = frameCount;
            UpTime = upTime;
            StackText = stackText;
        }
    }
}