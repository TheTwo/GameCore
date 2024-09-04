using UnityEngine.Networking;

namespace DragonReborn
{
	internal class SimpleHttpOperation : IHttpAsyncOperation
	{
		private readonly UnityWebRequestAsyncOperation _operation;

		public SimpleHttpOperation(UnityWebRequestAsyncOperation operation)
		{
			_operation = operation;
		}

		public UnityWebRequest Request => _operation.webRequest;

		public bool IsDone => _operation.isDone;

		public byte Priority
		{
			get => (byte)_operation.priority;
			set => _operation.priority = value;
		}

		public float Progress => _operation.progress;

		public bool IsAborted
		{
			get; private set;
		}

		public void Abort()
		{
			try
			{
				IsAborted = true;
				_operation.webRequest.Abort();
			}
			catch
			{
				// 如果请求应经调用过Dispose()，会抛ArgumentNullException
			}
		}
	}
}
