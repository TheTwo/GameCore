using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static partial class FrameworkInterfaceManager
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSplashScreen)]
        private static void BeforeSplashScreen()
        {
#if UNITY_EDITOR
	        if (UnityEditor.EditorBuildSettings.scenes == null || UnityEditor.EditorBuildSettings.scenes.Length <= 0) return;
	        var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
	        if (!scene.IsValid()) return;
	        if (scene.path != UnityEditor.EditorBuildSettings.scenes[0].path) return;
#endif
            GenerateInterfaces();
        }
    }
}