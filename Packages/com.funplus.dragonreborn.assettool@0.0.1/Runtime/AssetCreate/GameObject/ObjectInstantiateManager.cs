using DragonReborn;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;
using UnityEngine.Profiling;

public class ObjectInstantiateManager : Singleton<ObjectInstantiateManager>, ITicker
{
	private Queue<ObjectInstantiateCmd> _queueCmd;
	private Stopwatch _stopwatch;
	public int ProcessMsPerFrame = 3;
	private long _usedMs;
	private int _count;

	public void Initialize()
	{
		_queueCmd = new();
		_stopwatch = new();
	}

	public void Reset()
	{
		foreach (var cmd in _queueCmd)
		{
			cmd.Callback = null;
		}
		_queueCmd.Clear();
	}

	public void Tick(float delta)
	{
		if (_queueCmd == null || _queueCmd.Count == 0)
		{
			return;
		}

		// 当前帧的时间预算用尽
		if (_usedMs > ProcessMsPerFrame)
		{
			_usedMs = 0;
			_count = 0;
			return;
		}

		_stopwatch.Reset();
		_stopwatch.Start();
		while (_queueCmd.Count > 0)
		{
			var cmd = _queueCmd.Dequeue();
			if (cmd.Callback != null)
			{
				Spawn(cmd.AssetName, cmd.Asset, cmd.Parent, cmd.Callback);
				cmd.Callback = null;
				_usedMs += _stopwatch.ElapsedMilliseconds;
				_count++;

				if (_usedMs > ProcessMsPerFrame)
				{
					break;
				}
			}
		}

		_usedMs = 0;
		_count = 0;
	}

	private static void Spawn(string assetName, GameObject prefab, Transform parent, Action<GameObject> callback)
	{
#if UNITY_EDITOR
		Profiler.BeginSample($"[ObjectInstantiateManager]Spawn: Prefab = {assetName}");
#endif
		
		var go = UnityEngine.Object.Instantiate(prefab, parent);
		
#if UNITY_EDITOR
		Profiler.EndSample();
#endif
		
		callback?.Invoke(go);
	}

	public void Instantiate(GameObject asset, string assetName, Transform parent, Action<GameObject> callback)
	{
		// 如果当前帧还有时间预算，同步创建
		if (_usedMs < ProcessMsPerFrame)
		{
			_stopwatch.Reset();
			_stopwatch.Start();
			Spawn(assetName, asset, parent, callback);
			_usedMs += _stopwatch.ElapsedMilliseconds;
			_count++;
		}
		else
		{
			var cmd = new ObjectInstantiateCmd()
			{
				Asset = asset,
				AssetName = assetName,
				Parent = parent,
				Callback = callback
			};
			_queueCmd.Enqueue(cmd);
		}
	}
}

public class ObjectInstantiateCmd
{
	public GameObject Asset;
	public string AssetName;
	public Transform Parent;
	public Action<GameObject> Callback;
}
