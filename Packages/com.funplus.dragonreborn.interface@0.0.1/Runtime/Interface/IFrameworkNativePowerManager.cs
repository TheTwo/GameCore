// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IFrameworkNativePowerManager : IFrameworkInterface<IFrameworkNativePowerManager>
	{
		void Init();
		void Reset();
		
		NativePowerThermalStatus GetCurrentThermalStatus();

		bool IsPowerSaveMode();
		
		void KeepScreenOn();
		void NoKeepScreenOn();

		void BackupAndroidWindowFlags();
		void RestoreAndroidWindowFlags();
	}
}
