using System.Runtime.CompilerServices;
using System.Threading;

// ReSharper disable once CheckNamespace
namespace XLua.LuaDLL
{
	public static partial class LuaDLLWrapper
	{
		private static long _preCallIdx;
		private static long _threadId;
		private static volatile bool _watchWorking;

		public static void SetRenderThreadId(long threadId)
		{
			_threadId = threadId;
		}

		public static void SetWatcherWorkStart()
		{
			_watchWorking = true;
		}

		public static void SetWatchWorkEnd()
		{
			_watchWorking = false;
		}

		private static long PreCallInjected([CallerMemberName] string caller = null)
		{
			// add check method here
			return Interlocked.Increment(ref _preCallIdx);
		}

		private static void EndCallInjected(long preCallRet)
		{
			
		}
	}
}
