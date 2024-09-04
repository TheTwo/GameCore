namespace DragonReborn
{
    public interface INetworkAgent
    {
        IHttpApi Http { get; }
		void Update(float delta);
		void Reset();

	}
}
