
// ReSharper disable once CheckNamespace
namespace DragonReborn.Utilities
{
	public class PowerManager : Singleton<PowerManager>, IManager
	{
		private bool _init;
		private IFrameworkNativePowerManager _nativePowerManager;

		// for old luac compatible
		public void Initialize()
		{
			// InitOnce();
		}

		public void OnGameInitialize(object configParam)
		{
			InitOnce();
		}

		public void Reset()
		{
			_init = false;
			_nativePowerManager?.Reset();
			_nativePowerManager = null;
		}

		private void InitOnce()
		{
			if (_init) return;
			_init = true;
			FrameworkInterfaceManager.QueryFrameInterface(out _nativePowerManager);
			_nativePowerManager?.Init();
		}

		public NativePowerThermalStatus GetCurrentThermalStatus()
		{
			return _nativePowerManager?.GetCurrentThermalStatus() ?? NativePowerThermalStatus.THERMAL_STATUS_UNKNOWN;
		}

		public bool IsPowerSaveMode()
		{
			return _nativePowerManager?.IsPowerSaveMode() ?? false;
		}

		public void KeepScreenOn()
		{
			_nativePowerManager?.KeepScreenOn();
		}
		
		public void NoKeepScreenOn()
		{
			_nativePowerManager?.NoKeepScreenOn();
		}
		
		public void BackupAndroidWindowFlags()
		{
			_nativePowerManager?.BackupAndroidWindowFlags();
		}

		public void RestoreAndroidWindowFlags()
		{
			_nativePowerManager?.RestoreAndroidWindowFlags();
		}

		public void OnLowMemory()
		{

		}
	}
}
