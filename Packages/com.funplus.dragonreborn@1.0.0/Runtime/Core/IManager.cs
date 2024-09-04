namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IManager
	{
		/// <summary>
		/// 框架管理，对应于GameStart
		/// </summary>
		/// <param name="configParam"></param>
		void OnGameInitialize(object configParam);
		
		/// <summary>
		/// 框架管理，对应于GameRestart
		/// </summary>
		void Reset();

		void OnLowMemory();
	}
}
