using System.Collections.Generic;

namespace DragonReborn
{
	public interface IUpdater
	{
		void DoUpdate();
		void DoLateUpdate();
	}

	public static class Updater
	{
		private static readonly Dictionary<IUpdater, int> Indices = new();
		private static readonly List<IUpdater> Updaters = new();
		private static readonly List<IUpdater> Looping = new();

		public static bool Add(IUpdater updater)
		{
			if (Indices.TryGetValue(updater, out var index))
			{
				return false;
			}

			index = Updaters.Count;
			Updaters.Add(updater);
			Indices[updater] = index;
			return true;
		}

		public static bool Remove(IUpdater updater)
		{
			if (!Indices.TryGetValue(updater, out var index))
			{
				return false;
			}

			var lastIndex = Updaters.Count - 1;
			var lastUpdater = Updaters[lastIndex];

			Updaters[index] = lastUpdater;
			Indices[lastUpdater] = index;

			Updaters.RemoveAt(lastIndex);
			Indices.Remove(updater);

			return true;
		}

		public static void Clear()
		{
			Indices.Clear();
			Updaters.Clear();
		}

		public static void Update()
		{
			Looping.AddRange(Updaters);
			foreach (var updater in Looping)
			{
				updater.DoUpdate();
			}

			Looping.Clear();
		}

		public static void LateUpdate()
		{
			Looping.AddRange(Updaters);
			foreach (var updater in Looping)
			{
				updater.DoLateUpdate();
			}

			Looping.Clear();
		}
	}
}
