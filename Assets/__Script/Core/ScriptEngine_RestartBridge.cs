using DragonReborn;

// ReSharper disable once CheckNamespace
// ReSharper disable once InconsistentNaming
internal class ScriptEngine_RestartBridge : IRestartGameInterface
{
	private ScriptEngine_RestartBridge()
	{ }

	public static ScriptEngine_RestartBridge Instance { get; } = new();

	public void TriggerLuaRestartGame(string titleKey, string contentKey, bool showReportBtn = false)
	{
		if (!ScriptEngine.Initialized)
		{
			UnityEngine.Debug.LogErrorFormat("ScriptEngine not Initialized!");
			return;
		}
		ScriptEngine.Instance.TriggerLuaRestartGame(titleKey, contentKey, showReportBtn);
	}

// #if UNITY_EDITOR
// 	[UnityEditor.MenuItem("Tools/UnitTest/ScriptEngine_RestartBridge_test")]
// 	private static void UnitTest()
// 	{
// 		if (FrameworkInterfaceManager.QueryFrameInterface<IRestartGameInterface>(out var handle))
// 		{
// 			handle.TriggerLuaRestartGame("Warning", "Download Asset failed. Need Restart Game!!!");
// 		}
// 	}
// #endif
}

// ReSharper disable once CheckNamespace
// ReSharper disable once InconsistentNaming
internal class ScriptEngine_RestartBridgeDescriptor : FrameInterfaceDescriptor<IRestartGameInterface>
{
	private static readonly ScriptEngine_RestartBridgeDescriptor Descriptor = new ();

	private ScriptEngine_RestartBridgeDescriptor()
	{ }

	[UnityEngine.RuntimeInitializeOnLoadMethod(UnityEngine.RuntimeInitializeLoadType.AfterAssembliesLoaded)]
	private static void RegistryInterface()
	{
		FrameworkInterfaceManager.RegisterFrameInterface(Descriptor);
	}

	protected override IRestartGameInterface Create()
	{
		return ScriptEngine_RestartBridge.Instance;
	}
}
