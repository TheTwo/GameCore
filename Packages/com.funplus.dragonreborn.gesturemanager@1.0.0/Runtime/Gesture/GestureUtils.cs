// from finger gesture
using UnityEngine;

public enum DistanceUnit
{
	Pixels,
	Inches,
	Centimeters,
}

public static class GestureUtils
{
	const float DESKTOP_SCREEN_STANDARD_DPI = 96; // default win7 dpi
	const float INCHES_TO_CENTIMETERS = 2.54f; // 1 inch = 2.54 cm
	const float CENTIMETERS_TO_INCHES = 1.0f / INCHES_TO_CENTIMETERS; // 1 cm = 0.3937... inches

	static float _moveTolerance = 0.04f; // (in cm by default - see DistanceUnit)
	static float _pinchTolerance = 0.04f; // (in cm by default - see DistanceUnit)
	static float _screenDpi = 0;

	/// Screen Dots-Per-Inch
	public static float ScreenDPI
	{
		get 
		{
			// not intialized?
			if( _screenDpi <= 0 )
			{
				_screenDpi = Screen.dpi;

				// on desktop, dpi can be 0 - default to a standard dpi for screens
				if( _screenDpi <= 0 )
					_screenDpi = DESKTOP_SCREEN_STANDARD_DPI;

				#if UNITY_IPHONE
				// try to detect some devices that aren't supported by Unity (yet)
				if( UnityEngine.iOS.Device.generation == UnityEngine.iOS.DeviceGeneration.Unknown ||
				UnityEngine.iOS.Device.generation == UnityEngine.iOS.DeviceGeneration.iPadUnknown ||
				UnityEngine.iOS.Device.generation == UnityEngine.iOS.DeviceGeneration.iPhoneUnknown )
				{
				// ipad mini 2 ?
                    if( Screen.width == 2048 && Screen.height == 1536 && _screenDpi == 260 )
                        _screenDpi = 326;
				}
				#endif
			}

			return _screenDpi; 
		}
	}

	public static float MoveTolerance
	{
		get
		{
			return Convert (_moveTolerance, DistanceUnit.Centimeters, DistanceUnit.Pixels);
		}
	}

	public static float PinchTolerance
	{
		get
		{
			return Convert (_pinchTolerance, DistanceUnit.Centimeters, DistanceUnit.Pixels);
		}
	}

	public static float Convert( float distance, DistanceUnit fromUnit, DistanceUnit toUnit )
	{
		float dpi = ScreenDPI;
		float pixelDistance; 

		switch( fromUnit )
		{
		case DistanceUnit.Centimeters:
			pixelDistance = distance * CENTIMETERS_TO_INCHES * dpi; // cm -> in -> px
			break;

		case DistanceUnit.Inches:
			pixelDistance = distance * dpi; // in -> px
			break;

		case DistanceUnit.Pixels:
		default:
			pixelDistance = distance;
			break;
		}

		switch( toUnit )
		{
		case DistanceUnit.Inches:
			return pixelDistance / dpi; // px -> in

		case DistanceUnit.Centimeters:
			return ( pixelDistance / dpi ) * INCHES_TO_CENTIMETERS;  // px -> in -> cm

		case DistanceUnit.Pixels:
			return pixelDistance;
		}

		return pixelDistance;
	}
}