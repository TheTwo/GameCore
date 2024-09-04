// ReSharper disable once UnusedType.Global
// ReSharper disable once CheckNamespace
public static class AssetModeSwitch
{
#if UNITY_EDITOR
	public const string AssetModeSwitchEditorKey = "EDITOR_ASSETMODESWITCH";
#endif

	/// <summary>
	/// 获取运行时是否在真机或编辑器模拟真机模式
	/// </summary>
	/// <returns></returns>
	public static bool IsDeviceMode()
	{
#if UNITY_EDITOR
		return UnityEditor.EditorApplication.isPlaying && UnityEditor.EditorPrefs.GetBool(AssetModeSwitchEditorKey, false);
#else
		return true;
#endif
	}
}