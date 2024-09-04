

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
#if UNITY_DEBUG
    [UnityEngine.Scripting.RequireImplementors]
#endif
    public interface IFrameworkInGameConsole : IFrameworkInterface<IFrameworkInGameConsole>
    {
        public delegate void LogCallBack(in ConsoleEntry consoleEntry);
        
        LogCallBack CreateInstance();
        void DestroyInstance();
        void SetVisible(bool isVisible);
    }
}