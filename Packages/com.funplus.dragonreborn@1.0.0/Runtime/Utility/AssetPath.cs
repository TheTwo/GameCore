using System.IO;

namespace DragonReborn
{
	public class AssetPath
	{
		public static string Combine(string path1, string path2)
		{
			return Path.Combine(path1, path2).Replace('\\', '/');
		}

		public static string Combine(string path1, string path2, string path3)
		{
			return Path.Combine(path1, path2, path3).Replace('\\', '/');
		}

		public static string Combine(string path1, string path2, string path3, string path4)
		{
			return Path.Combine(path1, path2, path3, path4).Replace('\\', '/');
		}

		public static string Combine(params string[] paths)
		{
			return Path.Combine(paths).Replace('\\', '/');
		}

		public static string GetRelativePath(string relativeTo, string path)
		{
			return Path.GetRelativePath(relativeTo, path).Replace('\\', '/');
		}

		public static string GetFullPath(string relativePath)
		{
			return Path.GetFullPath(relativePath).Replace('\\', '/');
		}
	}
}
