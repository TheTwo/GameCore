#if UNITY_DEBUG && ((USE_BUNDLE_ANDROID || USE_BUNDLE_IOS || USE_BUNDLE_OSX || USE_BUNDLE_WIN) || !UNITY_EDITOR)
#define FUNCTION_ON
#endif

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public static class IOAccessRecorder
	{
#if FUNCTION_ON
		private static readonly System.Collections.Generic.List<(string, System.Collections.Generic.List<string>)> FileData = new();
		private static readonly System.Collections.Generic.HashSet<string> FileSet = new();
		private static readonly System.Collections.Generic.List<(string, System.Collections.Generic.List<string>)> AssetData = new();
		private static readonly System.Collections.Generic.HashSet<string> AssetSet = new();
		private static readonly System.Collections.Generic.List<(string, System.Collections.Generic.List<string>)> Mixed = new();
#endif

		[System.Diagnostics.Conditional("UNITY_DEBUG")]
		public static void StartStep(string step)
		{
#if FUNCTION_ON
			FileData.Add((step, new System.Collections.Generic.List<string>()));
			AssetData.Add((step, new System.Collections.Generic.List<string>()));
			Mixed.Add((step, new System.Collections.Generic.List<string>()));
#endif
		}

		[System.Diagnostics.Conditional("UNITY_DEBUG")]
		public static void RecordFile(string relativePath)
		{
#if FUNCTION_ON
			if (!FileSet.Add(relativePath)) return;
			if (FileData.Count <= 0)
			{
				FileData.Add(("Init", new System.Collections.Generic.List<string>()));
			}
			FileData[^1].Item2.Add(relativePath);
			if (Mixed.Count <= 0)
			{
				Mixed.Add(("Init", new System.Collections.Generic.List<string>()));
			}
			Mixed[^1].Item2.Add($"file:|{relativePath}");
#endif
		}
		
		[System.Diagnostics.Conditional("UNITY_DEBUG")]
		public static void RecordAsset(string relativePath)
		{
#if FUNCTION_ON
			if (!AssetSet.Add(relativePath)) return;
			if (AssetData.Count <= 0)
			{
				AssetData.Add(("Init", new System.Collections.Generic.List<string>()));
			}
			AssetData[^1].Item2.Add(relativePath);
			if (Mixed.Count <= 0)
			{
				Mixed.Add(("Init", new System.Collections.Generic.List<string>()));
			}
			Mixed[^1].Item2.Add($"asset:|{relativePath}");
#endif
		}

		[System.Diagnostics.Conditional("UNITY_DEBUG")]
		public static void Reset()
		{
#if FUNCTION_ON
			FileData.Clear();
			FileSet.Clear();
			AssetData.Clear();
			AssetSet.Clear();
			Mixed.Clear();
#endif
		}

		[System.Diagnostics.Conditional("UNITY_DEBUG")]
		public static void WriteDumpFile()
		{
#if FUNCTION_ON
			var path = System.IO.Path.Combine(UnityEngine.Application.persistentDataPath, "IOFileAccessLog.log");
			using var writer = new System.IO.StreamWriter(path);
			foreach (var (tag, file) in FileData)
			{
				writer.WriteLine($"Begin:[{tag}]");
				foreach (var relPath in file)
				{
					writer.WriteLine($" - {relPath}");
				}
			}
			path = System.IO.Path.Combine(UnityEngine.Application.persistentDataPath, "IOAccessAccessLog.log");
			using var writer2 = new System.IO.StreamWriter(path);
			foreach (var (tag, file) in AssetData)
			{
				writer2.WriteLine($"Begin:[{tag}]");
				foreach (var relPath in file)
				{
					writer2.WriteLine($" - {relPath}");
				}
			}
			path = System.IO.Path.Combine(UnityEngine.Application.persistentDataPath, "IOAccessMixedLog.log");
			using var writer3 = new System.IO.StreamWriter(path);
			foreach (var (tag, file) in Mixed)
			{
				writer2.WriteLine($"Begin:[{tag}]");
				foreach (var relPath in file)
				{
					writer2.WriteLine($" - {relPath}");
				}
			}
#endif
		}
	}
}