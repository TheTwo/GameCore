using System;
using UnityEngine;

public class EnvironmentVariable
{
    public bool UNITY_EDITOR()
    {
#if UNITY_EDITOR
            return true;
#else
            return false;
#endif
    }
    
    public bool UNITY_ANDROID()
    {
#if UNITY_ANDROID
            return true;
#else
            return false;
#endif
    }
    
    public bool UNITY_IOS()
    {
#if UNITY_IPHONE
            return true;
#else
            return false;
#endif
    }
    
    public bool UNITY_STANDALONE_OSX()
    {
#if UNITY_STANDALONE_OSX
            return true;
#else
	    return false;
#endif
    }
    
    public bool UNITY_STANDALONE_WIN()
    {
#if UNITY_STANDALONE_WIN
            return true;
#else
	    return false;
#endif
    }
    
    public bool UNITY_DEBUG()
    {
#if UNITY_DEBUG
            return true;
#else
            return false;
#endif
    }

    public bool UNITY_RUNTIME_ON_GUI_ENABLED()
    {
#if UNITY_RUNTIME_ON_GUI_ENABLED || UNITY_EDITOR
        return true;
#else
        return false;
#endif
    }

	public bool USE_FPXSDK()
	{
#if USE_FPXSDK
		return true;
#else
		return false;
#endif
	}

	public bool USE_BUNDLE_ANDROID()
    {
#if USE_BUNDLE_ANDROID
        return true;
#else
        return false;
#endif
    }

    public bool USE_BUNDLE_IOS()
    {
#if USE_BUNDLE_IOS
        return true;
#else
        return false;
#endif
    }
    
    public bool USE_BUNDLE_OSX()
    {
#if USE_BUNDLE_OSX
        return true;
#else
	    return false;
#endif
    }
    
    public bool USE_BUNDLE_WIN()
    {
#if USE_BUNDLE_WIN
        return true;
#else
	    return false;
#endif
    }

    public bool IS_32_BIT()
    {
        return IntPtr.Size == 4;
    }

    public bool USE_UWA()
    {
#if UWA_ENABLED_IN_PROJECT && (UNITY_IPHONE || UNITY_ANDROID || UNITY_STANDALONE_WIN)
        return true;
#else
	    return false;
#endif
    }

    public bool USE_LOCAL_CONFIG()
    {
#if UNITY_EDITOR
	    return UnityEditor.EditorPrefs.GetBool(ScriptEngine.USE_LOCAL_CONFIG, false);
#else
		return false;
#endif
    }

    public bool USE_PRIVATE_SERVER_LOCAL_CONFIG()
    {
#if UNITY_EDITOR
	    return UnityEditor.EditorPrefs.GetBool(ScriptEngine.USE_PRIVATE_SERVER_LOCAL_CONFIG, false);
#else
		return false;
#endif
    }

    public bool INGAME_CONSOLE_ENABLED()
    {
#if INGAME_CONSOLE_ENABLED
	return true;
#else
	return false;
#endif
    }

    public bool SHADER_CREATE_PROGRAM_TRACKING()
    {
#if SHADER_CREATE_PROGRAM_TRACKING
        return true;
#else
	    return false;
#endif
    }
}
