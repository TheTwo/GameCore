using System.Collections.Generic;
using System;
using System.Threading;

namespace DragonReborn
{
	public class TaskManager : Singleton<TaskManager>, ITicker, IManager
	{
		private const int MaxThreads = 1;

		// 主线程子线程都需要访问的变量（需要加锁）
		private int _numThreads;
		private Queue<Action> _childThreadedActions;
		private List<Action> _mainThreadedActions;

		// 只有主线程要访问的变量（不需要加锁）
		private List<Action> _currentActions;

		public void OnGameInitialize(object configParam)
		{
			_childThreadedActions = new Queue<Action>();
			_mainThreadedActions = new List<Action>();
			_currentActions = new List<Action>();

			_numThreads = 0;
		}

		public void Reset()
		{
			_childThreadedActions.Clear();
			_mainThreadedActions.Clear();
			_currentActions.Clear();
		}

		public void QueueOnMainThread(Action action)
		{
			lock (_mainThreadedActions)
			{
				_mainThreadedActions.Add(action);
			}
		}

		public void RunAsync(Action a)
		{
			lock (_childThreadedActions)
			{
				_childThreadedActions.Enqueue(a);
			}
		}

		private void RunAction(object action)
		{
			try
			{
				((Action)action)();
			}
			finally
			{
				Interlocked.Decrement(ref _numThreads);
			}
		}

		// Update is called once per frame
		public void Tick(float delta)
		{
			// do sub thread actions
			lock (_childThreadedActions)
			{
				if (_numThreads < MaxThreads && _childThreadedActions.Count > 0)
				{
					Interlocked.Increment(ref _numThreads);
					ThreadPool.QueueUserWorkItem(RunAction, _childThreadedActions.Dequeue());
				}
			}

			// do main queue actions
			lock (_mainThreadedActions)
			{
				_currentActions.Clear();
				_currentActions.AddRange(_mainThreadedActions);
				_mainThreadedActions.Clear();
			}

			foreach (var a in _currentActions)
			{
				a();
			}
		}

		public void OnLowMemory()
		{

		}
	}
}
