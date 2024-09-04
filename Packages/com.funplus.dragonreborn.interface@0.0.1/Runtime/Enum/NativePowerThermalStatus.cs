
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	// ReSharper disable once UnusedType.Global
	public enum NativePowerThermalStatus
	{
		// ReSharper disable InconsistentNaming
		THERMAL_STATUS_UNKNOWN = -1,
		// see https://developer.android.com/reference/android/os/PowerManager#THERMAL_STATUS_NONE
		/// <summary>
		/// Not under throttling
		/// </summary>
		THERMAL_STATUS_NONE = 0,
		/// <summary>
		/// Light throttling where UX is not impacted
		/// </summary>
		THERMAL_STATUS_LIGHT = 1,
		/// <summary>
		/// Moderate throttling where UX is not largely impacted
		/// </summary>
		THERMAL_STATUS_MODERATE = 2,
		/// <summary>
		/// 严重 影响体验
		/// </summary>
		THERMAL_STATUS_SEVERE = 3,
		/// <summary>
		/// Platform has done everything to reduce power
		/// </summary>
		THERMAL_STATUS_CRITICAL = 4,
		/// <summary>
		/// Key components in platform are shutting down due to thermal condition. Device functionalities will be limited
		/// </summary>
		THERMAL_STATUS_EMERGENCY = 5,
		/// <summary>
		/// Need shutdown immediately
		/// </summary>
		THERMAL_STATUS_SHUTDOWN = 6,
		THERMAL_STATUS_MAX = 7,
		// ReSharper restore InconsistentNaming
	}
}
