
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	[UnityEngine.Scripting.RequireImplementors]
	public interface IAdapterCrashlytics :  IFrameworkInterface<IAdapterCrashlytics>
	{
		bool EnableUploadErrorLog { get; }
		void RecordCrashlyticsLog(string msg);
	}
}
