// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IRestartGameInterface : IFrameworkInterface<IRestartGameInterface>
	{
		void TriggerLuaRestartGame(string titleKey, string contentKey, bool showReportBtn = false);
	}
}