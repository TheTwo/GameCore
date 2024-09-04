using UnityEngine;
using DragonReborn;

public static class DeviceUtils
{
	public static bool EnableRequestIDFA;
	public const float MarginToLeft = 57.0f;
	public const float MarginToRight = 57.0f;
	public const float MarginToBottom = 20.0f;
	
	
	/// 刘海屏幕
	public static bool IsNotchScreen()
	{
		// UIIPhoneXAdaptorScript.marginToLeft =  MarginToLeft;
		// UIIPhoneXAdaptorScript.marginToRight =  MarginToRight;
		// UIIPhoneXAdaptorScript.marginToBottom =  MarginToBottom;
		
#if UNITY_EDITOR
		if (2436 == Screen.width && 1125 == Screen.height)
		{
			return true;
		}

		if (2688 == Screen.width && 1242 == Screen.height)
		{
			return true;
		}
		
// #elif UNITY_IOS || UNITY_IPHONE
// 		if (!ConfigManager.Instance.IsReady)
// 		{
// 			return true;
// 		}
//
//         string deviceType = KGInternal.getDeviceType();
//         if (ConfigRefer.PhoneTypeConfig.IsIOSNotchScreen(deviceType))
//         {
//             return true;
//         }
// #elif UNITY_ANDROID
// 	UIIPhoneXAdaptorScript.marginToBottom =  0.0f;
// 		return IsAndroidNotchScreen();
 #endif
		return false;
	}

// #if UNITY_ANDROID
// 	private static bool IsAndroidNotchScreen()
// 	{
// 		var androidSDKVersion = KGInternal.getAndroidVersion();
// 		if (androidSDKVersion >= 28)
// 		{
// 			return KGInternal.isNotchScreen();
// 		}
// 		else
// 		{
// 			if (!ConfigManager.Instance.IsReady)
// 			{
// 				return true;
// 			}
// 			
// 			var deviceType = GetAndroidDeviceType();
// 			return ConfigRefer.PhoneTypeConfig.IsAndroidNotchScreen(deviceType);
// 		}
// 	}
// 	
// 	private static string GetAndroidDeviceType()
// 	{
// 		var android_os_build = new AndroidJavaClass("android.os.Build");
// 		return android_os_build.GetStatic<string>("DEVICE");
// 	}
// #endif
}
