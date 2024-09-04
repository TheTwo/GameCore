namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IFrameworkLuaStackTrace : IFrameworkInterface<IFrameworkLuaStackTrace>
	{
		string StackTrace();
	}
}
