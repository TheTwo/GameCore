using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn
{
	public class TickerList
	{
		private readonly LinkedList<ITicker> _updateList = new LinkedList<ITicker>();
		private readonly HashSet<ITicker> _removeList = new HashSet<ITicker>();
        private readonly bool _ignoreTimeScale;
		private float _lastTickTime = -1.0f;

        public TickerList(bool ignoreTimeScale)
        {
            _ignoreTimeScale = ignoreTimeScale;
        }

		public float LastTickTime => _lastTickTime;

		public void Add(ITicker ticker)
		{
			if (!_updateList.Contains (ticker))
			{
				_updateList.AddLast (ticker);
			}
			_removeList.Remove(ticker);
		}

		public void Remove(ITicker ticker)
		{
			_removeList.Add(ticker);
		}

		public void Tick()
        {
            var currentTime = GetCurrentTime();
			var deltaTime = _lastTickTime > 0 ? currentTime - _lastTickTime : 0;
			_lastTickTime = currentTime;

			UpdateTickers(deltaTime);
			RemoveTickers();
		}

        private float GetCurrentTime()
        {
            return _ignoreTimeScale ? Time.realtimeSinceStartup : Time.time;
        }

		private void UpdateTickers(float deltaTime)
		{
			var node = _updateList.First;
			while (node != null)
			{
				var ticker = node.Value;
				node = node.Next;

				if (!_removeList.Contains(ticker))
				{
					ticker.Tick(deltaTime);
				}
			}
		}

		private void RemoveTickers()
		{
			var node = _updateList.First;
			while (node != null)
			{
				var candidate = node;
				node = node.Next;

				if (_removeList.Contains(candidate.Value))
				{
					_updateList.Remove(candidate);
				}
			}
			_removeList.Clear();
		}

		public void Clear ()
		{
			_lastTickTime = -1.0f;
			_updateList.Clear();
			_removeList.Clear();
		}
	}
}

