using System;
using UnityEngine;
using System.Globalization;
using DragonReborn;

// ReSharper disable once CheckNamespace
public sealed class GameWrapper : MonoBehaviour
{
	private void Start()
	{
		Physics.queriesHitTriggers = false;//editor need this. but game not.
		// 临时关闭 URP DEBUG
		UnityEngine.Rendering.DebugManager.instance.enableRuntimeUI = false;
		Application.targetFrameRate = 60;

		Application.runInBackground = true;

		Input.gyro.enabled = true;

		Screen.sleepTimeout = SleepTimeout.NeverSleep;
		
		DontDestroyOnLoad(gameObject);

		// 避免南非地区，4.99 ToString成4,99的问题
		CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
		
		ScriptEngine.Instance.Startup();

		
#if UNITY_DEBUG
		LangValidationManager.OnGameStarted(new LangValidationUtils());
#endif
	}

	private void Update()
	{
		ScriptEngine.Instance.Update(Time.deltaTime);
		Updater.Update();
	}

	private void LateUpdate()
	{
		ScriptEngine.Instance.LateUpdate(Time.deltaTime);
		Updater.LateUpdate();
	}

	private void OnApplicationPause(bool pause)
	{
		ScriptEngine.Instance.OnApplicationPause(pause);
	}

	private void OnApplicationFocus(bool focus)
	{
		ScriptEngine.Instance.OnApplicationFocus(focus);
	}

	private void OnApplicationQuit()
	{
		Exception shutdownException = null;
		try
		{
			ScriptEngine.Instance.Shutdown();
		}
		catch (Exception delayThrow)
		{
			shutdownException = delayThrow;
		}
		if (null != shutdownException)
		{
			throw shutdownException;
		}
		IOUtils.OnApplicationQuit();
	}

	private void OnEnable()
	{
		UnityEngine.Device.Application.lowMemory += OnLowMemory;
	}

	private void OnDisable()
	{
		UnityEngine.Device.Application.lowMemory -= OnLowMemory;
	}

	private void OnLowMemory()
	{
		NLogger.Log("OnLowMemory");
		ScriptEngine.Instance.OnLowMemory();
	}
}
