namespace DragonReborn.AssetTool
{
    public interface IRefCounter
    {
        void Increase(string log = "");
        bool Decrease(string log = "");
        int GetRefCount();
		void ResetRefCount();
    }
}
