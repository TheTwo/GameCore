namespace DragonReborn
{
    [UnityEngine.Scripting.RequireImplementors]
    public interface IUILifeCircleEventReceiver : IFrameworkInterface<IUILifeCircleEventReceiver>
    {
        public void StartRecord();
        public void StopRecord();
        
        public void BeforeUIPrefabCreate(int runTimeId, string uiMediatorName, string uiPrefabAssetName);
        public void AfterUIClosed(int runTimeId);
    }
}