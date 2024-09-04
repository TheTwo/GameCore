#if THREAD_SAFE || HOTFIX_ENABLE

using System;
using System.Diagnostics;
using System.Threading;

public class LockUtils
{
	[Conditional("LockUtils_CheckLock_ENABLE")]
    public static void CheckLock(object obj)
    {
        if (Monitor.TryEnter(obj))
        {
            Monitor.Exit(obj);
        }
        else
        {
	        SdkAdapter.SdkModels.SdkCrashlytics.LogCustomException(new Exception("Lua同时在多个线程下访问, 需要排查堆栈"));
        }
    }
}
#endif
