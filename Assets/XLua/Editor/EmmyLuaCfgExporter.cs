using System.Collections.Generic;
using System.IO;
using System.Text;

namespace DragonReborn
{
	public static class EmmyLuaCfgExporter
	{
		public static void GenerateCfgJson()
		{
			var rootFolder = LuaCExportTools.ExternalLuaSourcePathRoot;
			var rootPathStringBuilder = new StringBuilder();
			var queue = new Queue<string>();
			queue.Enqueue(rootFolder);
			while (queue.Count > 0)
			{
				var path = queue.Dequeue();
				if (Directory.Exists(path))
				{
					var subPaths = Directory.GetDirectories(path);
					foreach (var subPath in subPaths)
					{
						var directoryInfo = new DirectoryInfo(subPath);
						if ((directoryInfo.Attributes & FileAttributes.Hidden) != 0)
							continue;

						var relativePath = "\t\t\t\"./" + Path.GetRelativePath(rootFolder, subPath)+"\",";
						relativePath = relativePath.Replace("\\", "/");
						rootPathStringBuilder.AppendLine(relativePath);
						queue.Enqueue(subPath);
					}
				}
			}

			rootPathStringBuilder.AppendLine("\t\t\t\"./\"");
			var defaultCfg = @"
{
	""completion"": {
		""autoRequire"": false,
		""autoRequireFunction"": ""require"",
		""autoRequireNamingConvention"": ""snakeCase"",
		""callSnippet"": false,
		""postfix"": ""@""
	},
	""diagnostics"": {
		""disable"": [
		""deprecated"",
		""access-private-member"",
		""undefined-global""
			],
		""globals"": [
		""watcher"",
		""g_Game""
			],
		""globalRegex"": [
		],
		""severity"": {
		}
	},
	""hint"": {
		""paramHint"": true,
		""indexHint"": true,
		""localHint"": false,
		""overrideHint"": true
	},
	""runtime"": {
		""version"": ""Lua5.3"",
		""requireLikeFunction"": [],
		""frameworkVersions"": [],
		""extensions"": []
	},
	""workspace"": {
		""ignoreDir"": [],
		""library"": [],
		""workspaceRoots"": [
			[############]
		],
		""preloadFileSize"": 12048000
	},
	""resource"": {
		""paths"": [
		]
	},
	""codeLens"":{
		""enable"": false
	}
}";
			var cfgJson = defaultCfg.Replace("[############]", rootPathStringBuilder.ToString());
			var writer = File.CreateText(Path.Combine(rootFolder, ".emmyrc.json"));
			writer.Write(cfgJson);
			writer.Flush();
			writer.Close();
		}
	}
}
