// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    [UnityEngine.Scripting.RequireImplementors]
    public interface INativeLoadingOverlay : IFrameworkInterface<INativeLoadingOverlay>
    {
        int GetCurrentOverrideIconFileVersion();
        void SetOverrideIconFile(UnityEngine.TextAsset imageBytes, int version);
        void ClearOverrideIconFile();
        void PlayFile(UnityEngine.Vector2 viewPortPos, UnityEngine.Vector2 pivot, UnityEngine.Vector2 size, int speed);
        void PlayRuntimeTemp(UnityEngine.TextAsset imageBytes, UnityEngine.Vector2 viewPortPos, UnityEngine.Vector2 pivot, UnityEngine.Vector2 size, int speed);
        void UpdatePos(UnityEngine.Vector2 viewPortPos);
        void Remove();
    }
}