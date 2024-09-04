
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IFrameVersionControl : IFrameworkInterface<IFrameVersionControl>
	{
		bool IsFileReady(string relativeFilePath);
		bool InSyncing(string relativeFilePath);
		void SyncFile(string relativeFilePath);
	}
}
