using System;
using System.Collections.Generic;
using UnityEngine;

namespace XLua
{
	public struct GCRecord
	{
		public DateTime StartTime;
		public TimeSpan DeltaTime;
	}
	
	public class LuaGCMonitorStrategy
	{
		public const int DEFAULT_PAUSE = 200;
		public const int DEFAULT_STEPMUL = 200;

		//private int Pause;
		//private int StepMul;

		private DateTime _time;
		private readonly Queue<GCRecord> _gcRecords = new(16);
		private TimeSpan _averageDeltaTime;

		public int GCTimesPer10Min => _gcRecords.Count;
		public double GCAverageCostTime => _averageDeltaTime.TotalSeconds;

		public LuaGCMonitorStrategy()
		{
			//Pause = DEFAULT_PAUSE;
			//StepMul = DEFAULT_STEPMUL;
		}
		
		public void OnStart()
		{
			_time = DateTime.Now;
		}

		public void OnEnd()
		{
			if (_time == new DateTime())
				return;
			
			var deltaTime = DateTime.Now - _time;
			if (deltaTime.TotalMilliseconds > Double.Epsilon)
			{
				_gcRecords.Enqueue(new GCRecord
				{
					StartTime = _time,
					DeltaTime = deltaTime,
				});
				PostEnd();
			}
		}

		private void PostEnd()
		{
			var now = DateTime.Now;
			while (_gcRecords.TryPeek(out var result))
			{
				if ((now - result.StartTime).TotalSeconds <= 600)
				{
					break;
				}

				_gcRecords.Dequeue();
			}

			var deltaTime = TimeSpan.Zero;
			var times = 0;
			foreach (var record in _gcRecords)
			{
				deltaTime += record.DeltaTime;
				times++;
			}

			// OverflowException : TimeSpan overflowed because the duration is too long.
			_averageDeltaTime = times > 0 ? deltaTime / times : TimeSpan.Zero;
		}
	}
}
