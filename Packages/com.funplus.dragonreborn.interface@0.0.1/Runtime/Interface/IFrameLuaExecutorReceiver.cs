
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public interface IFrameLuaExecutorReceiver
	{
		public delegate bool LuaExecutor(string code, out string ret);

		void OnSetupExecutor(LuaExecutor executor);

		void OnReleaseExecutor();
	}
}
