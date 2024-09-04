namespace DragonReborn.AssetTool
{
    public interface IAsyncRequest
    {
        bool CheckComplete();
        bool NeedRemove
        {
            get;
        }
    }
}