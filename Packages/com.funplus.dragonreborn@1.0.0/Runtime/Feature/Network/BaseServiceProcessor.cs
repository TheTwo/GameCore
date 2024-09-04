using System.Collections.Concurrent;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public abstract class BaseServiceProcessor<TRequest, TResponse>
	{
        public struct Workload
        {
	        // ReSharper disable once InconsistentNaming
	        public TResponse response;
        }

        // ReSharper disable InconsistentNaming
        protected readonly ConcurrentQueue<TRequest> _requestQueue = new ();
        protected readonly ConcurrentQueue<Workload> _responseQueue = new();
		protected HttpRequester.IRequestStrategy _requestStrategy;
		// ReSharper restore InconsistentNaming

		public void SetRequestStrategy(HttpRequester.IRequestStrategy strategy)
		{
			_requestStrategy = strategy;
		}

        public virtual void InsertRequest(TRequest request)
		{
			_requestQueue.Enqueue(request);
		}

        protected virtual void InsertResponse(TResponse response)
		{
			_responseQueue.Enqueue(new Workload
			{
				response = response
			});
		}

		public virtual void Reset()
		{
			_requestQueue.Clear();
			_responseQueue.Clear();
		}

		public abstract void Tick (float delta);
	}
}

