
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public static class RenderParallelTasksBridge
	{
		public enum Status
		{
			Unknown,
			NotInRendering,
			InRendering,
		}

		public static Status TaskStatus { get; set; } = Status.Unknown;
	}
}
