using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

public class PlayableDirectorListenerWrapper : MonoBehaviour
{
	public PlayableDirector targetDirector;
	public Action<PlayableDirector> stoppedCallback;

	private bool _stoppedTriggered = false;

	private void OnEnable()
	{
		if (targetDirector == null)
		{
			TryGetComponent(out targetDirector);
		}
	}

	private void OnDisable()
	{
		if (targetDirector != null)
		{
			targetDirector.stopped -= OnStopped;
		}
	}

	public void AddStoppedListener()
	{
		if (targetDirector != null)
		{
			targetDirector.stopped += OnStopped;
		}
	}

	public void RemoveStoppedListener()
	{
		if (targetDirector != null)
		{
			targetDirector.stopped -= OnStopped;
		}
	}

	private void OnStopped(PlayableDirector director)
	{
		_stoppedTriggered = true;
	}

	private void Update()
	{
		if (_stoppedTriggered)
		{
			_stoppedTriggered = false;
			stoppedCallback?.Invoke(targetDirector);
		}
	}
}
