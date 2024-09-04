using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEngine;
using UnityEngine.Build.Pipeline;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	using BuildBundleRet = ValueTuple<CompatibilityAssetBundleManifest,DateTime, bool>;

	// ReSharper disable once ClassNeverInstantiated.Global
	public class AssetBundleGenerator
    {
	    public static string AssetBundleOutputPath { get; set; }
	    // ReSharper disable ConvertToConstant.Global
	    // ReSharper disable InconsistentNaming
	    public static readonly string BUNDLE_ASSETS_CONFIG_FILE = BundleAssetDataManager.BUNDLE_ASSETS_CONFIG_FILE;//"bundle_assets_{0}.json";
	    public static readonly string BUNDLE_DEPENDENCE_CONFIG_FILE = BundleDependenceManager.BUNDLE_DEPENDENCE_CONFIG_FILE;//"bundle_dependence_{0}.json";
		public static readonly string BUNDLE_VERSION_FILE = "bundle_version.json";
		public static readonly string BUNDLE_NAME2MD5_OVERRIDE_HASH_FILE = "bundle_name2md5_override_hash.json";
		public const string BUNDLE_RELATIVE_BASE_PATH = "GameAssets/AssetBundle";
		public const string BUNDLE_RELATIVE_ANDROID_PATH = "Android";
		public const string BUNDLE_RELATIVE_IOS_PATH = "IOS";
		public const string BUNDLE_RELATIVE_OSX_PATH = "OSX";
		public const string BUNDLE_RELATIVE_WINDOWS_PATH = "Windows";
		public const string BUNDLE_PATH = "Assets/StreamingAssets/" + BUNDLE_RELATIVE_BASE_PATH;
		public const string IOS_BUNDLE_PATH = BUNDLE_PATH + "/" + BUNDLE_RELATIVE_IOS_PATH;
		public const string ANDROID_BUNDLE_PATH = BUNDLE_PATH + "/" + BUNDLE_RELATIVE_ANDROID_PATH;
		public const string OSX_BUNDLE_PATH = BUNDLE_PATH + "/" + BUNDLE_RELATIVE_OSX_PATH;
		public const string WIN_BUNDLE_PATH = BUNDLE_PATH + "/" + BUNDLE_RELATIVE_WINDOWS_PATH;
		// ReSharper restore ConvertToConstant.Global
		// ReSharper restore InconsistentNaming

		public static string GetBundleRelativeFolder(BuildTarget target)
		{
			switch (target)
			{
				case BuildTarget.StandaloneOSX:
					return BUNDLE_RELATIVE_BASE_PATH + "/" + BUNDLE_RELATIVE_OSX_PATH;
				case BuildTarget.StandaloneWindows:
				case BuildTarget.StandaloneWindows64:
					return BUNDLE_RELATIVE_BASE_PATH + "/" + BUNDLE_RELATIVE_WINDOWS_PATH;
				case BuildTarget.iOS:
					return BUNDLE_RELATIVE_BASE_PATH + "/" + BUNDLE_RELATIVE_IOS_PATH;
				case BuildTarget.Android:
					return BUNDLE_RELATIVE_BASE_PATH + "/" + BUNDLE_RELATIVE_ANDROID_PATH;
				default:
					throw new ArgumentOutOfRangeException(nameof(target), target, null);
			}
		}

		private static HashSet<string> _allAddressNames = new HashSet<string>();
		private static List<string> _tmpAddressNameList = new List<string>();

		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundleForIOS")]
		public static void GenerateAssetBundleForIOS()
		{
			var isEncrypt = IOUtils.HasEncryptTag();

			var context = new Dictionary<string, object>
			{
				["StaticBundleProcessRule"] = (int)BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset
			};

			GenerateAssetBundle(BuildTarget.iOS, isEncrypt, context, out _);
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundleForAndroid")]
		public static void GenerateAssetBundleForAndroid()
		{
			var isEncrypt = IOUtils.HasEncryptTag();

			var context = new Dictionary<string, object>
			{
				["StaticBundleProcessRule"] = (int) BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset
			};

			GenerateAssetBundle(BuildTarget.Android, isEncrypt, context, out _);
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundleForAndroid(模式1)")]
		public static void GenerateAssetBundleForAndroid_Mode1()
		{
			var isEncrypt = IOUtils.HasEncryptTag();

			var context = new Dictionary<string, object>
			{
				["StaticBundleProcessRule"] = (int)BundleProcessRule.OnlyReferencedAndRefAboveOneAssetGenerateBundleByFolder
			};

			GenerateAssetBundle(BuildTarget.Android, isEncrypt, context, out _);
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundleForOSX")]
		public static void GenerateAssetBundleForOSX()
		{
			var isEncrypt = IOUtils.HasEncryptTag();

			var context = new Dictionary<string, object>
			{
				["StaticBundleProcessRule"] = (int)BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset
			};

			GenerateAssetBundle(BuildTarget.StandaloneOSX, isEncrypt, context, out _);
		}
		
		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundleForWin")]
		public static void GenerateAssetBundleForWin()
		{
			var isEncrypt = IOUtils.HasEncryptTag();

			var context = new Dictionary<string, object>
			{
				["StaticBundleProcessRule"] = (int)BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset
			};

			GenerateAssetBundle(BuildTarget.StandaloneWindows64, isEncrypt, context, out _);
		}

		[MenuItem("DragonReborn/资源工具箱/出包工具/Bundle/GenerateAssetBundlePrepare")]
		public static void GenerateAssetBundlePrepare()
		{
			NLogger.Log("------------------------ begin GenerateAssetBundlePrepare ----------------------------------");
			// TextureTools.PruneTextures();
			// SpriteAtlasTool.GenerateSpriteAtlas();
			// ShaderVariantCollector.CollectShaders();
			NLogger.Log("------------------------ end GenerateAssetBundlePrepare ----------------------------------");
		}

		public static void GenerateAssetBundle(BuildTarget target, bool useEngrypt, IReadOnlyDictionary<string, object> operationContext, out string bundleName2Md5OverrideHash)
		{
			if (!Application.isBatchMode)
			{
				if (target != EditorUserBuildSettings.activeBuildTarget)
				{
					if (!EditorUtility.DisplayDialog("目标平台变化", "构建Bundle的目标平台与当前编辑器目标平台不一致,继续将换编辑器目标平台", "继续", "取消"))
					{
						bundleName2Md5OverrideHash = string.Empty;
						return;
					}
				}
			}

			GenerateAssetBundlePrepare();

			if (Directory.Exists(BUNDLE_PATH))
			{
				Directory.Delete(BUNDLE_PATH, true);
			}

			AssetBundleOutputPath = GetBundleOutputPath(target);

			var m = BuildBundle(target, operationContext);
			GenerateAssetBundleImplement(m, useEngrypt, out bundleName2Md5OverrideHash);
		}

		public static string GetBundleOutputPath(BuildTarget target)
		{
			switch (target)
			{
				case BuildTarget.iOS:
					return IOS_BUNDLE_PATH;
				case BuildTarget.Android:
					return ANDROID_BUNDLE_PATH;
				case BuildTarget.StandaloneOSX:
					return OSX_BUNDLE_PATH;
				case BuildTarget.StandaloneWindows64:
					return WIN_BUNDLE_PATH;
				default:
					throw new NotSupportedException();
			}
		}

		public static string GetAssetBundlePath(string assetBundle)
		{
			return Path.Combine(AssetBundleOutputPath, assetBundle);
		}

		public static string GetBundleVersionPath()
		{
			return Path.Combine(BUNDLE_PATH, BUNDLE_VERSION_FILE);
		}
		
		private static BuildBundleRet BuildBundle(BuildTarget target, IReadOnlyDictionary<string, object> operationContext)
		{
			var buildOperation = new BuildBundleOperation(target, operationContext);
			buildOperation.PreBuildOperations();
			buildOperation.DoBuildOperation();
			var exitCode = buildOperation.PostBuildOperation();
			if (exitCode < ReturnCode.Success)
			{
				if (Application.isBatchMode)
				{
					throw new OperationCanceledException($"Build AssetBundle error:{exitCode}");
				}
			}
			return (buildOperation.Manifest, buildOperation.StartTime, buildOperation.SplitInPackAndOta);
		}

		[MenuItem("Tools/BuildBundleDryRun")]
		private static void BuildBundleDryRun()
		{
			BuildBundleDryRun(EditorUserBuildSettings.activeBuildTarget);
		}

		private static CompatibilityAssetBundleManifest BuildBundleDryRun(BuildTarget target)
		{
			AssetBundleOutputPath = $"Assets/StreamingAssets/GameAssets/AssetBundle/{target}";
			var buildOperation = new BuildBundleOperation(target, null);
			buildOperation.PreBuildOperations();
			buildOperation.ModifyAsDryRun();
			buildOperation.DoBuildOperation();
			buildOperation.PostBuildOperation();
			return buildOperation.Manifest;
		}

		private static List<string> GetAddressableNamesList(string[] assetNames)
		{
			_tmpAddressNameList.Clear();
			foreach (var assetPath in assetNames)
			{
				if (IsAssetNeedLoad(assetPath))
				{
					var assetIndex = Path.GetFileNameWithoutExtension(assetPath);
					if (_allAddressNames.Contains(assetIndex))
					{
						_tmpAddressNameList.Add(null);
						// throw new Exception("GetAddressableNamesList AssetName Duplicate " + assetIndex);
						NLogger.Error("GetAddressableNamesList AssetName Duplicate " + assetIndex);
						continue;
					}
					_allAddressNames.Add(assetIndex);
					_tmpAddressNameList.Add(assetIndex);
				}
				else
				{
					_tmpAddressNameList.Add(null);
				}
			}
			
			return _tmpAddressNameList;
		}
		
		private static bool IsAssetNeedLoad(string assetPath)
		{
			const string resourcesTag = "/_resources/";
			// ReSharper disable once StringLiteralTypo
			const string shaderCollectionTag = "/shadercollector/";
			const string shaderHandCollectTag = "/shadercollectbyhand/";
			// ReSharper disable once StringLiteralTypo
			const string shaderCollectionEndFix = ".shadervariants";
		
			if (assetPath.EndsWith(".anim"))
			{
				return false;
			}
			
			int index = assetPath.IndexOf(resourcesTag, StringComparison.CurrentCultureIgnoreCase);
			if (index > 0)
			{
				return true;
			}
			index = assetPath.IndexOf(shaderCollectionTag, StringComparison.OrdinalIgnoreCase);
			if (index > 0 && assetPath.EndsWith(shaderCollectionEndFix, StringComparison.OrdinalIgnoreCase))
			{
				return true;
			}
			index = assetPath.IndexOf(shaderHandCollectTag, StringComparison.OrdinalIgnoreCase);
			if (index > 0 && assetPath.EndsWith(shaderCollectionEndFix, StringComparison.OrdinalIgnoreCase))
			{
				return true;
			}

			return false;
		}
		
		private static void GenerateAssetBundleImplement(BuildBundleRet buildRet, bool useEngrypt, out string bundleName2Md5OverrideHash)
		{
			var (manifest, _, _) = buildRet;
			GenerateBundleName2Md5OverrideHashInfo(buildRet, useEngrypt, out bundleName2Md5OverrideHash);
			
			// ==>bundle_dependences_{resVersion}.json
			GenerateDependenceInfo(buildRet, useEngrypt, out var dependenceFilePath);
			
			// ==>bundle_assets_{resVersion}.json
			GenerateBundleAssetsInfo(buildRet, useEngrypt, out var asset2BundleFile);

			// ==> encrypt
			if (useEngrypt)
			{
				EncryptBundles(manifest);
				EncryptBundlesInfoJson(dependenceFilePath, asset2BundleFile);
			}
			
			// ==> modify names
			PostModifyBundleFileName(buildRet, useEngrypt);
		}

		private static long GetAssetBundlesSize(string[] bundles)
		{
			var totalSize = 0L;
			if (bundles == null || bundles.Length == 0)
			{
				return totalSize;
			}

			foreach (var bundle in bundles)
			{
				var fullpath = GetAssetBundlePath(bundle);
				totalSize += File.ReadAllBytes(fullpath).LongLength;
			}
			return totalSize;
		}

		private static void GenerateBundleName2Md5OverrideHashInfo(BuildBundleRet buildRet, bool useHashBundleName,
			out string mapFilePath)
		{
			var (manifest, _, _) = buildRet;
			var allAssetBundles = GetAllAssetBundles(manifest);

			var mapFile = new SortedDictionary<string, string>();

			if (useHashBundleName)
			{
				foreach (var assetBundleName in allAssetBundles)
				{
					var hashedName = AssetBundleBuildGenerator.BundleNameToHash(assetBundleName);
					var bundleHash = manifest.GetAssetBundleHash(assetBundleName);
					mapFile.Add(hashedName, bundleHash.ToString());
				}
			}
			else
			{
				foreach (var assetBundleName in allAssetBundles)
				{
					var bundleHash = manifest.GetAssetBundleHash(assetBundleName);
					mapFile.Add(assetBundleName, bundleHash.ToString());
				}
			}

			mapFilePath = GetAssetBundlePath(BUNDLE_NAME2MD5_OVERRIDE_HASH_FILE);
			var jsonString = DataUtils.ToJson(mapFile);
			File.WriteAllText(mapFilePath, jsonString);
		}
		
		private static void GenerateDependenceInfo(BuildBundleRet buildRet, bool useHashBundleName, out string dependenceFilePath)
		{
			var (manifest, _, _) = buildRet;
			var allAssetBundles = GetAllAssetBundles(manifest);

			var allDependenceMap = new SortedDictionary<string, (string[],Hash128)>();
			var allDependenceMapBeforeRename = new SortedDictionary<string, (string[],Hash128)>();

			if (useHashBundleName)
			{
				foreach (var assetBundleName in allAssetBundles)
				{
					var hashedName = AssetBundleBuildGenerator.BundleNameToHash(assetBundleName);
					var allDependence = manifest.GetAllDependencies(assetBundleName);
					var allDependenceRealName = new string[allDependence.Length];
					Array.Copy(allDependence, allDependenceRealName, allDependence.Length);
					for (var i = 0; i < allDependence.Length; i++)
					{
						allDependence[i] = AssetBundleBuildGenerator.BundleNameToHash(allDependence[i]);
					}
					allDependenceMap.Add(hashedName, (allDependence,manifest.GetAssetBundleHash(assetBundleName)));
					var addPair = (allDependenceRealName, manifest.GetAssetBundleHash(assetBundleName));
					allDependenceMapBeforeRename.Add(assetBundleName, addPair);
				}
			}
			else
			{
				foreach (var assetBundleName in allAssetBundles)
				{
					var allDependence = manifest.GetAllDependencies(assetBundleName);
					var addPair = (allDependence, manifest.GetAssetBundleHash(assetBundleName));
					allDependenceMap.Add(assetBundleName, addPair);
					allDependenceMapBeforeRename.Add(assetBundleName, addPair);
				}
			}

			dependenceFilePath = GetAssetBundlePath(BUNDLE_DEPENDENCE_CONFIG_FILE);
			var jsonString = DataUtils.ToJson(BundleDependenceConfigJson.CreateFromDic(allDependenceMap));
			File.WriteAllText(dependenceFilePath, jsonString);

			var sb = new StringBuilder();
			sb.AppendLine("AssetBundleName,Depedencies,Count,TotalSize");
			foreach (var (bundleName, pair) in allDependenceMapBeforeRename)
			{
				sb.AppendLine($"{bundleName},{string.Join(';', pair.Item1)},{pair.Item1.Length},{GetAssetBundlesSize(pair.Item1)}");
			}
			var outputPath = Path.Combine(Application.dataPath, "../Logs/AssetBundle依赖分析.csv");
			File.WriteAllText(outputPath, sb.ToString());
		}

		private static void GenerateBundleAssetsInfo(BuildBundleRet buildRet, bool useHashBundleName, out string asset2BundleFile)
		{
			var (manifest, _, splitInPackAndOta) = buildRet;
			var allAssetBundles = GetAllAssetBundles(manifest);
			var asset2Bundle = new SortedDictionary<string, string>();
			var scene2Bundle = new SortedDictionary<string, string>();
			var bundle2Hash = new Dictionary<string, Hash128>();
			
			foreach (var assetBundleName in allAssetBundles)
			{
				var useBundleName = useHashBundleName? AssetBundleBuildGenerator.BundleNameToHash(assetBundleName) : assetBundleName;
				bundle2Hash.Add(useBundleName, manifest.GetAssetBundleHash(assetBundleName));
				if (!AssetBundleBuildGenerator.BundleNeedAssetsListByName(assetBundleName, splitInPackAndOta)) continue;
				var assetBundle = AssetBundle.LoadFromFile(GetAssetBundlePath(assetBundleName));
				if (assetBundle.isStreamedSceneAssetBundle)
				{
					var scenePaths = assetBundle.GetAllScenePaths();
					foreach (var scene in scenePaths)
					{
						if (!scene2Bundle.ContainsKey(scene))
						{
							scene2Bundle.Add(scene, useBundleName);
						}
						else
						{
							Debug.LogError(scene + " ------------- exist");
						}
					}
				}
				else
				{
					var allAssetNames = assetBundle.GetAllAssetNames();
					foreach (var assetName in allAssetNames)
					{
						if (assetName.EndsWith(".shader", StringComparison.OrdinalIgnoreCase)) continue;
						if (!asset2Bundle.ContainsKey(assetName))
						{
							asset2Bundle.Add(assetName, useBundleName);
						}
						else
						{
							Debug.LogError(assetName + " ------------- exist");
						}
					}
				}
				assetBundle.Unload(true);
			}

			asset2BundleFile = GetAssetBundlePath(string.Format(BUNDLE_ASSETS_CONFIG_FILE));
			var jsonString = DataUtils.ToJson(BundleAssetAndSceneConfigJson.Create(asset2Bundle, scene2Bundle, bundle2Hash));
			File.WriteAllText(asset2BundleFile, jsonString);
		}

		protected static void EncryptBundles(CompatibilityAssetBundleManifest manifest)
		{
			var allAssetBundles = GetAllAssetBundles(manifest);
			foreach (var assetBundle in allAssetBundles)
			{
				var md5 = AssetBundleBuildGenerator.BundleNameToHash(assetBundle);
				var bundlePath = GetAssetBundlePath(assetBundle);
				SafetyUtils.EncryptHeadOffset(md5, bundlePath);
			}
		}

		private static void EncryptBundlesInfoJson(string dependenceFilePath, string asset2BundleFile)
		{
			SafetyUtils.EncryptXOR(dependenceFilePath);
			SafetyUtils.EncryptXOR(asset2BundleFile);
		}

		private static void PostModifyBundleFileName(BuildBundleRet buildRet, bool useEncrypt)
		{
			var (manifest, startTime, _) = buildRet;
			var allAssetBundles = GetAllAssetBundles(manifest);
			Func<string, string> finalPathGetter = useEncrypt ? GetFinalAssetBundlePath : s => s + PathHelper.BUNDLE_END_FIX;

			Parallel.ForEach(allAssetBundles, assetBundleName =>
			{
				var f = GetAssetBundlePath(assetBundleName);
				File.Move(f, finalPathGetter(f));
			});

			if (!useEncrypt) return;
			var time = startTime.ToString("_yyyy_MM_dd_HH_mm_ss");
			var writeHashName2BundleOriginNameFile = Path.Combine(Application.dataPath, "../Logs/BundleHashName2Origin" + time + ".log");
			using var writer = new StreamWriter(writeHashName2BundleOriginNameFile, false, Encoding.UTF8);
			foreach (var bundleName in allAssetBundles)
			{
				writer.WriteLine($"{AssetBundleBuildGenerator.BundleNameToHash(bundleName)} {bundleName} {SafetyUtils.GetHeadOffset(AssetBundleBuildGenerator.BundleNameToHash(bundleName))}");
			}
			writer.Close();

			static string GetFinalAssetBundlePath(string inputPath)
			{
				var bundleName = Path.GetFileNameWithoutExtension(inputPath);
				return Path.Combine(Path.GetDirectoryName(inputPath) ?? string.Empty ,
				                 AssetBundleBuildGenerator.BundleNameToHash(bundleName) +
				                 PathHelper.BUNDLE_END_FIX);
			}
		}
		
		private static string[] GetAllAssetBundles(CompatibilityAssetBundleManifest manifest)
		{
			if(manifest != null)
			{
				return manifest.GetAllAssetBundles();
			}

			return new string[] {};
		}
		
		[MenuItem("DragonReborn/资源工具箱/资源规范/资源分析(DryRunBuildBundle)")]
		public static void AnalyzeInputAssetAndOutputDependenceBundle()
		{
			var inputFile = EditorUtility.OpenFilePanel("选择需要分析的列表文件", Path.Combine(Application.dataPath, "../"), "*");
			if (string.IsNullOrWhiteSpace(inputFile)) return;
			if (!File.Exists(inputFile))
			{
				Debug.LogErrorFormat("输入的文件不存在:{0}", inputFile);
				return;
			}
			var allLines = File.ReadAllLines(inputFile);
			if (allLines.Length <= 0)
			{
				Debug.LogErrorFormat("输入的文件没有内容:{0}", inputFile);
				return;
			}
			var time = DateTime.Now.ToString("_yyyy_MM_dd_HH_mm_ss");
			var saveFile = Path.Combine(Application.dataPath, "../Logs/资源依赖分析结果" + time + ".log");
			if (string.IsNullOrWhiteSpace(saveFile)) return;
			var folder = Path.GetDirectoryName(saveFile);
			var collectionFile = string.IsNullOrWhiteSpace(folder) ? (Path.GetFileNameWithoutExtension(saveFile) + "_collection" + Path.GetExtension(saveFile)) :Path.Combine(folder,
				Path.GetFileNameWithoutExtension(saveFile) + "_collection" + Path.GetExtension(saveFile));
			var dependenceFile = string.IsNullOrWhiteSpace(folder) ? (Path.GetFileNameWithoutExtension(saveFile) + "_collection" + Path.GetExtension(saveFile)) :Path.Combine(folder,
				Path.GetFileNameWithoutExtension(saveFile) + "_dependence" + Path.GetExtension(saveFile));
			AssetBundleOutputPath = $"Assets/StreamingAssets/GameAssets/AssetBundle/{EditorUserBuildSettings.activeBuildTarget}";
			var operation = new BuildBundleOperation(EditorUserBuildSettings.activeBuildTarget, null);
			operation.PreBuildOperations();
			operation.ModifyAsDryRun();
			operation.DoBuildOperation();
			operation.PostBuildOperation();
			var detailManifest = operation.DetailManifest.Result;
			var allBundleNameSet = new HashSet<string>(StringComparer.Ordinal);
			using var depFile = new StreamWriter(dependenceFile, false, Encoding.UTF8);
			depFile.WriteLine("{");
			foreach (var allLine in allLines)
			{
				var t = allLine.Trim();
				if (string.IsNullOrWhiteSpace(t)) continue;
				if (!detailManifest.Asset2DepBundle.TryGetValue(t, out var bundleName) || bundleName.Count <= 0) continue;
				allBundleNameSet.UnionWith(bundleName);
				depFile.Write("\t\"");
				depFile.Write(allLine);
				depFile.WriteLine("\":[");
				var index = 0;
				foreach (var b in bundleName)
				{
					depFile.Write($"\t\t\"{b}\"");
					if (++index < bundleName.Count)
					{
						depFile.WriteLine(",");
					}
				}
				depFile.WriteLine();
				depFile.WriteLine("\t],");
			}
			depFile.WriteLine("}");
			var list = allBundleNameSet.ToArray();
			Array.Sort(list, StringComparer.Ordinal);
			File.WriteAllLines(collectionFile, list);
			GenerateDependenceInfo((operation.Manifest, operation.StartTime, operation.SplitInPackAndOta), false, out _);
			if (EditorUtility.DisplayDialog("完毕", "是否打开文件夹", "打开文件夹", "取消"))
			{
				Application.OpenURL("file:///" + folder);
			}
		}

		private class BuildBundleOperation
		{
			private readonly BuildTarget _target;
			private BundleBuildParameters _buildParams;
			private BundleBuildContent _buildContent;
			private IList<IBuildTask> _taskList;
			private ReturnCode _exitCode;
			private IBundleBuildResults _results;
			private IContextObject[] _injectUserDefineContext;
			private GetResultTask<IDetailManifest> _detailManifest;
			private GetResultTask<IImplicitDependenciesAssets> _implicitDependenciesAssets;
			private GetResultTask<ISpriteTextureReferenceRecord> _spriteTextureReferences;
			private GetResultTask<IInValidAssetReferenceRecord> _inValidAssetReferenceRecord;
			private GetResultTask<IMarkStaticBundleProcessRule> _markStaticBundleProcessRule;

			private CompatibilityAssetBundleManifest _manifest;
			private DateTime _startTime;
			private bool _splitInPackAndOta;

			public CompatibilityAssetBundleManifest Manifest => _manifest;
			public GetResultTask<IDetailManifest> DetailManifest => _detailManifest;
			public DateTime StartTime => _startTime;
			public bool SplitInPackAndOta => _splitInPackAndOta;
			private readonly IReadOnlyDictionary<string, object> _operationContext;

			public BuildBundleOperation(BuildTarget target, IReadOnlyDictionary<string, object> operationContext)
			{
				_target = target;
				_operationContext = operationContext;
			}

			public void PreBuildOperations()
			{
				// make Build Parameters 
				var buildGroup = BuildPipeline.GetBuildTargetGroup(_target);
				var buildParams = new CustomBundleBuildParameter(_target, buildGroup, AssetBundleOutputPath);
				
				// 设置这个 可以让不同的bundle 使用不同的压缩方式
				buildParams.SetBundleCompressionFormatProvider(InPackBundleNoCompressed);
				
				_buildParams = buildParams;
				// 采用LZ4压缩
				_buildParams.BundleCompression = UnityEngine.BuildCompression.LZ4;
				// 不追加hash
				_buildParams.AppendHash = false;
				// IL2CPP 裁剪保护 assetbundle内用到的Unity类型
				_buildParams.WriteLinkXML = true;

				// TODO 可以尝试用Cache Server加速
				// Set build parameters for connecting to the Cache Server
				_buildParams.UseCache = true;
				// buildParams.CacheServerHost = "buildcache.unitygames.com";
				// buildParams.CacheServerPort = 8126;
				
				// art resource 资源名 白名单
				HashSet<string> artResourceWhitelist = null;
				var whitelistFilePath = Path.Combine(Application.dataPath, "ConfigUsedAssets.txt");
				if (File.Exists(whitelistFilePath))
				{
					var trimEnd = new[] { '\n', '\r' };
					var allLines = File.ReadAllLines(whitelistFilePath);
					artResourceWhitelist = new HashSet<string>();
					foreach (var assetName in allLines)
					{
						var trimName = assetName.TrimEnd(trimEnd);
						if (string.IsNullOrEmpty(trimName)) continue;
						artResourceWhitelist.Add(trimName);
					}
				}

				// art resource 资源名 黑名单 白名单模式时不生效
				HashSet<string> artResourceBlackList = null;
				if (artResourceWhitelist == null 
				    && _operationContext != null 
				    && _operationContext.TryGetValue("ART_RESOURCE_ASSET_BLACKLIST_FILE", out var filePathObj) 
				    && filePathObj is string filePath
				    && File.Exists(filePath))
				{
					var trimEnd = new[] { '\n', '\r' };
					var allLines = File.ReadAllLines(filePath);
					artResourceBlackList = new HashSet<string>();
					foreach (var assetName in allLines)
					{
						var trimName = assetName.TrimEnd(trimEnd);
						if (string.IsNullOrEmpty(trimName)) continue;
						artResourceBlackList.Add(trimName);
					}
				}

				// The content to build
				// var bundleBuilds = ContentBuildInterface.GenerateAssetBundleBuilds();
				var bundleBuilds = AssetBundleBuildGenerator.GenerateAssetBundleBuilds(null
					, out var spriteToBundleName
					, out var bundleNameGetter
					, out var mappedAssets
					, out _splitInPackAndOta
					, artResourceBlackList
					, artResourceWhitelist);
				// throw new System.ArgumentException("AssetBundleBuildGenerator TEST Stop");
				// Update the addressableNames to load by the file name without extension
				_allAddressNames.Clear();
				var allInAssetBuildGuids = new Dictionary<GUID, string>();
				for (var i = 0; i < bundleBuilds.Length; i++)
				{
					ref var build = ref bundleBuilds[i];
					for (int j = 0; j < build.assetNames.Length; j++)
					{
						var a = build.assetNames[j];
						allInAssetBuildGuids.Add(AssetDatabase.GUIDFromAssetPath(a), build.assetBundleName);
					}
					if (!AssetBundleBuildGenerator.BundleNeedAssetsListByName(build.assetBundleName, _splitInPackAndOta)) continue;
					if (build.addressableNames == null ||
					    build.addressableNames.Length != build.assetNames.Length)
					{
						build.addressableNames = GetAddressableNamesList(build.assetNames).ToArray();
					}
				}

				foreach (var mappedAsset in mappedAssets)
				{
					var guid = AssetDatabase.GUIDFromAssetPath(mappedAsset.Key);
					if (allInAssetBuildGuids.ContainsKey(guid)) continue;
					allInAssetBuildGuids[guid] = mappedAsset.Value;
				}

				_buildContent = new BundleBuildContent(bundleBuilds);

				// build AssetBundles
				_taskList = DefaultBuildTasks.Create(DefaultBuildTasks.Preset.AssetBundleCompatible);
				PruneSpriteAtlasSingleTextureTask.AddToBuildTasks(_taskList, spriteToBundleName);
				RecordSpriteTextureReferenceTask.AddToBuildTasks(_taskList, spriteToBundleName);
				var ignoreGuids = new HashSet<GUID>()
				{
					BuildTaskHelper.GetUnityDefaultResourceGuid(),
					BuildTaskHelper.GetUnityEditorResourceGuid(),
				};
				var monoScriptType = typeof(MonoScript);
				var shaderType = typeof(Shader);
				var shaderVariantCollectionType = typeof(ShaderVariantCollection);
				var builtInGuid = BuildTaskHelper.GetUnityBuiltInExtraGuid();
				var unityDefaultResourceGuid = BuildTaskHelper.GetUnityDefaultResourceGuid();
				var reMapRule = new ReMapAssetToBundleTask.MatchRuleFunc[]
				{
					(Type type, in ObjectIdentifier _, out string bundleName) =>
					{
						if ((type == shaderType || type == shaderVariantCollectionType))
						{
							bundleName = _splitInPackAndOta ? AssetBundleBuildGenerator.InPackPreFix + AssetBundleBuildGenerator.ShaderBundleName : AssetBundleBuildGenerator.ShaderBundleName;
							return true;
						}
					
						bundleName = default;
						return false;
					},
					(Type type, in ObjectIdentifier objectIdentifier, out string bundleName) =>
					{
						if (objectIdentifier.guid == builtInGuid && (type != shaderType && type != shaderVariantCollectionType))
						{
							bundleName = _splitInPackAndOta ? AssetBundleBuildGenerator.InPackPreFix + AssetBundleBuildGenerator.UnityBuiltInBundleName : AssetBundleBuildGenerator.UnityBuiltInBundleName;
							return true;
						}

						bundleName = default;
						return false;
					},
					// (Type type, in ObjectIdentifier objectIdentifier, out string bundleName) =>
					// {
					// 	if (monoScriptType == type && objectIdentifier.guid != unityDefaultResourceGuid)
					// 	{
					// 		bundleName = _splitInPackAndOta ? AssetBundleBuildGenerator.InPackPreFix + AssetBundleBuildGenerator.UnityMonoScriptBundleName : AssetBundleBuildGenerator.UnityMonoScriptBundleName;
					// 		return true;
					// 	}
					// 	bundleName = default;
					// 	return false;
					// }
				};
				ReMapAssetToBundleTask.AddToBuildTasks(_taskList, reMapRule, ignoreGuids);
				AutoGenerateStaticBundleByReferencesTask.AddToBuildTasks(_taskList, bundleNameGetter, allInAssetBuildGuids, _splitInPackAndOta);
				CheckInvalidAssetReferenceTask.AddToBuildTasks(_taskList);
				ProcessBundleXmlTask.AddToBuildTasks(_taskList,
					Path.Combine(Application.dataPath, "BundleLinkXml/link.xml"));
				CollectImplicitDependenciesAssetsTask.AddToBuildTasks(_taskList, allInAssetBuildGuids);
				OutPutAssetDependenceBundleMapTask.AddToBuildTasks(_taskList);
				_implicitDependenciesAssets = GetResultTask<IImplicitDependenciesAssets>.AddToBuildTasks(_taskList);
				_detailManifest = GetResultTask<IDetailManifest>.AddToBuildTasks(_taskList);
				_spriteTextureReferences = GetResultTask<ISpriteTextureReferenceRecord>.AddToBuildTasks(_taskList);
				_inValidAssetReferenceRecord = GetResultTask<IInValidAssetReferenceRecord>.AddToBuildTasks(_taskList, default, false);
				_markStaticBundleProcessRule = GetResultTask<IMarkStaticBundleProcessRule>.AddToBuildTasks(_taskList, default, false);
				_injectUserDefineContext = new IContextObject[] { new InValidAssetCheckRule(false, new HashSet<GUID>()
				{
					// BuildTaskHelper.GetUnityDefaultResourceGuid(),
					// BuildTaskHelper.GetUnityBuiltInExtraGuid(),
				}),
					// new MarkStaticBundleProcessRule(BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset),
					MarkStaticBundleProcessRule.BuildFromContextDic(_operationContext)
				};
			}

			private static bool InPackBundleNoCompressed(string bundleName, out UnityEngine.BuildCompression compression)
			{
				if (bundleName.StartsWith(AssetBundleBuildGenerator.InPackPreFix))
				{
					compression = UnityEngine.BuildCompression.Uncompressed;
					return true;
				}
				if (string.CompareOrdinal(bundleName, "art@video") == 0)
				{
					compression = UnityEngine.BuildCompression.Uncompressed;
					return true;
				}
				compression = default;
				return false;
			}

			public void ModifyAsDryRun()
			{
				BuildTaskHelper.ModifyBuildTaskToDryRun(_taskList);
			}

			private class ShaderFinalProcessorLogger : IShaderFinalProcessorLogger, IDisposable
			{
				private readonly StringBuilder _logRecord = new();

				public ShaderFinalProcessorLogger()
				{
					ShaderFinalProcessor.RedirectLogger = this;
				}

				public void AppendLog(string logInfo)
				{
					_logRecord.AppendLine(logInfo);
				}

				public void Dispose()
				{
					ShaderFinalProcessor.RedirectLogger = null;
				}
			}

			public void DoBuildOperation()
			{
				_startTime = DateTime.Now;
				using (new ShaderFinalProcessorLogger())
				{
					_exitCode = ContentPipeline.BuildAssetBundles(_buildParams, _buildContent, out _results, _taskList, _injectUserDefineContext ?? Array.Empty<IContextObject>());
				}
			}

			public ReturnCode PostBuildOperation()
			{
				if (_exitCode < ReturnCode.Success)
				{
					Debug.LogError($"Build Bundle Failed, error {_exitCode}");
					return _exitCode;
				}
			
				var buildLog = Path.Combine(AssetBundleOutputPath, "buildlogtep.json");
				if (File.Exists(buildLog))
				{
					var dst = Path.Combine(Application.dataPath, "../Logs", "bundle_buildlogtep.json");
					if (File.Exists(dst)) File.Delete(dst);
					File.Move(buildLog, dst);
					// File.Delete(buildLog);
				}
			
				_manifest = ScriptableObject.CreateInstance<CompatibilityAssetBundleManifest>();
				var patchedBundleInfos = _detailManifest.Result.PatchForManifest(_results.BundleInfos);
				_manifest.SetResults(patchedBundleInfos);

				// save _manifest content for record
				var bundleFolderPath = AssetBundleOutputPath;
				var writeManifestPath = Path.Combine(Application.dataPath, "../Logs", Path.GetFileName(bundleFolderPath) + _startTime.ToString("_yyyy_MM_dd_HH_mm_ss") + ".manifest");
				File.WriteAllText(writeManifestPath, _manifest.ToString());

				//var reportXlsxPath = Path.Combine(Application.dataPath, "../Logs", "bundleReport.xlsx");
				//var folder = Path.GetDirectoryName(reportXlsxPath);
				//if (!string.IsNullOrWhiteSpace(folder) && !Directory.Exists(folder))
				//{
				//	Directory.CreateDirectory(folder);
				//}
				//WriteBundleReportToExcel.WriteExcelReport(reportXlsxPath, _detailManifest.Result);

				//var reportImplicitDependencies = Path.Combine(Application.dataPath, "../Logs", "ImplicitDependenciesAssets.json");
				//_implicitDependenciesAssets.Result.WriteToFile(reportImplicitDependencies);
				var spriteTextureReferences = Path.Combine(Application.dataPath, "../Logs", "SpriteTextureReferences.json");
				_spriteTextureReferences.Result.WriteToFile(spriteTextureReferences);
				if (null != _inValidAssetReferenceRecord.Result)
				{
					var inValidAssetReferenceRecord = Path.Combine(Application.dataPath, "../Logs", "InValidAssetReferenceRecord.json");
					if (File.Exists(inValidAssetReferenceRecord)) File.Delete(inValidAssetReferenceRecord);
					_inValidAssetReferenceRecord.Result.WriteToFile(inValidAssetReferenceRecord);
				}
				if (null != _markStaticBundleProcessRule.Result)
				{
					var staticBundleRefAndNoRefDetail = Path.Combine(Application.dataPath, "../Logs", "StaticBundleRefAndNoRefDetail.json");
					var staticBundleRefAndNoRefDetailCsv = Path.Combine(Application.dataPath, "../Logs", "StaticBundleRefAndNoRefDetail.csv");
					if (File.Exists(staticBundleRefAndNoRefDetail)) File.Delete(staticBundleRefAndNoRefDetail);
					if (File.Exists(staticBundleRefAndNoRefDetailCsv)) File.Delete(staticBundleRefAndNoRefDetailCsv);
					_markStaticBundleProcessRule.Result.WriteToFile(staticBundleRefAndNoRefDetail, staticBundleRefAndNoRefDetailCsv);
				}

				return _exitCode;
			}

			private class InValidAssetCheckRule : IInValidAssetCheckRule
			{
				private static readonly Type MaterialType = typeof(Material);
				private static readonly Type ShaderType = typeof(Shader);
				private static readonly Type ShaderCollectionType = typeof(ShaderVariantCollection);
				
				private readonly bool _failBuildIfNotPass;
				private readonly ISet<GUID> _ignoreGuids;
				bool IInValidAssetCheckRule.FailBuildIfNotPass => _failBuildIfNotPass;
				ISet<GUID> IInValidAssetCheckRule.IgnoreGuids => _ignoreGuids;
				private readonly IReadOnlyList<string> _materialAllowedPath;
				private readonly IReadOnlyList<string> _shaderAllowedPath;

				private static readonly GUID UnityBuiltInExtraGuid = BuildTaskHelper.GetUnityBuiltInExtraGuid();
				private static readonly GUID UnityDefaultResourceGuid = BuildTaskHelper.GetUnityDefaultResourceGuid();
				private static readonly HashSet<long> AllowedUnityDefaultResourceLocalId = new()
				{
					17,// shader fullback
					10001, // Spot Texture
					10101, // font shader
					//10102, // Arial Font
					//10103, // Arial Font Texture
					10200, // Mesh pSphere1
					10201, // Mesh pCube1
					10202, // Mesh Cube
					10203, // Mesh pCylinder1
					10204, // Mesh pPlane1
					10205, // Mesh polySurface2
					10206, // Mesh Cylinder
					10207, // Mesh Sphere
					10208, // Mesh Capsule,
					10209, // Mesh Plane,
					10210, // Mesh Quad,
					10211, // Mesh Icosphere,
					10212, // Mesh icosahedron,
					10213, // Mesh pyramid,
				};

				public InValidAssetCheckRule(bool failBuildIfNotPass, ISet<GUID> ignoreGuids)
				{
					_failBuildIfNotPass = failBuildIfNotPass;
					_ignoreGuids = ignoreGuids;
					_materialAllowedPath = MaterialTools.AllowedMaterialPaths
						.Select(t => t.EndsWith('/') ? t : t + '/').Distinct().ToArray();
					_shaderAllowedPath = MaterialTools.AllowedShaderPathArray
						.Select(t => t.EndsWith('/') ? t : t + '/').Distinct().ToArray();
				}

				bool IInValidAssetCheckRule.IsAssetPathValid(in ObjectIdentifier objectIdentifier, out string assetPath)
				{
					assetPath = AssetDatabase.GUIDToAssetPath(objectIdentifier.guid);
					do
					{
						if (string.IsNullOrWhiteSpace(assetPath)) break;
						if (objectIdentifier.guid == UnityBuiltInExtraGuid) return true;
						if (objectIdentifier.guid == UnityDefaultResourceGuid && AllowedUnityDefaultResourceLocalId.Contains(objectIdentifier.localIdentifierInFile))
						{
							return true;
						}
						var assetTypes = BuildTaskHelper.GetCachedTypesForObject(in objectIdentifier);
						var assetType = assetTypes is { Length: > 0 } ? assetTypes[0] : null;
						if (null != assetType && SkipCheckType.Contains(assetType)) return true;
						var p = assetPath;
						if (AllowedPathStart.Any(t => p.StartsWith(t, StringComparison.OrdinalIgnoreCase))) return true;
						if (assetPath.EndsWith(".dll", StringComparison.OrdinalIgnoreCase)) return true;
						switch (assetType)
						{
							case not null when MaterialType.IsAssignableFrom(assetType):
								if (_materialAllowedPath.Any(t => p.StartsWith(t, StringComparison.OrdinalIgnoreCase)))
									return true;
								break;
							case not null when ShaderType.IsAssignableFrom(assetType):
							case not null when ShaderCollectionType.IsAssignableFrom(assetType):
								if (_shaderAllowedPath.Any(t => p.StartsWith(t, StringComparison.OrdinalIgnoreCase)))
									return true;
								break;
						}
					} while (false);
					return false;
				}

				private static readonly Type[] SkipCheckType =
				{
					typeof(MonoScript),
				};

				private static readonly string[] AllowedPathStart =
				{
					"Assets/__Art/Resources/",
					"Assets/__Art/StaticResources/",
					"Assets/__Art/_Resources/",
					"Assets/__Scene/StaticResources/",
					"Assets/__Scene/_Resources/",
					"Assets/__UI/StaticResources/",
					"Assets/__UI/_Resources/",
					"Assets/__UI/Resources/",
					"Packages/com.esotericsoftware.spine.spine-unity",
					"Assets/ThirdParty/PowerUtilities",
					"Packages/com.unity.cinemachine",
				};
			}

			private class MarkStaticBundleProcessRule : IMarkStaticBundleProcessRule
			{
				private const string StaticBundleProcessRule = "StaticBundleProcessRule";
				
				public BundleProcessRule UseRule { get; }
				public Dictionary<string, StaticBundleIncludedDetail> RefDetail { get; }

				public static MarkStaticBundleProcessRule BuildFromContextDic(
					IReadOnlyDictionary<string, object> contextDic)
				{
					if (null == contextDic 
					    || !contextDic.TryGetValue(StaticBundleProcessRule, out var rule) 
					    || rule is not int enumValue 
					    || !Enum.IsDefined(typeof(BundleProcessRule), enumValue))
					{
						return new MarkStaticBundleProcessRule(BundleProcessRule.ReferencedAssetGenerateBundleByFolderAndIncludeSameFolderAsset);
					}
					return new MarkStaticBundleProcessRule((BundleProcessRule)enumValue);
				}

				public MarkStaticBundleProcessRule(BundleProcessRule useRule)
				{
					UseRule = useRule;
					RefDetail = new Dictionary<string, StaticBundleIncludedDetail>();
				}

				private class BundleRecord
				{
					public string BundleName;
					public int RefAssetCount;
					public int NoRefAssetCount;
					public int RefByRefAssetCount;
					public int TotalCount;
					public float Percent;

					public BundleRecord(string bundleName, StaticBundleIncludedDetail detail)
					{
						BundleName = bundleName;
						RefAssetCount = detail.ReferencedAssets.Count;
						NoRefAssetCount = detail.NotReferencedAssets.Count;
						RefByRefAssetCount = detail.ReferencedByAssets.Count;
						TotalCount = RefAssetCount + NoRefAssetCount + RefByRefAssetCount;
						Percent = TotalCount > 0 ? (NoRefAssetCount * 1f / TotalCount) : 0f;
					}
				}

				public void WriteToFile(string jsonOutput, string csvOutput)
				{
					using var sw = new StreamWriter(jsonOutput, false, Encoding.UTF8);
					using JsonWriter writer = new JsonTextWriter(sw);
					writer.Formatting = Formatting.Indented;
					var bundleNames = RefDetail.Keys.ToList();
					var detailList = new List<BundleRecord>();
					bundleNames.Sort(StringComparer.Ordinal);
					writer.WriteStartObject();
					foreach (var bundleName in bundleNames)
					{
						var detail = RefDetail[bundleName];
						var record = new BundleRecord(bundleName, detail);
						detailList.Add(record);
						writer.WritePropertyName(bundleName);
						writer.WriteStartObject();
						{
							writer.WritePropertyName("NoRefCount:");
							writer.WriteValue($"{record.NoRefAssetCount}/{record.TotalCount}");
							writer.WritePropertyName("NoRefPercent:");
							writer.WriteValue($"{record.Percent*100:f3}%");
							writer.WritePropertyName("HasRefAssets:");
							writer.WriteStartArray();
							{
								var refList = detail.ReferencedAssets.ToArray();
								Array.Sort(refList, (a, b) => string.CompareOrdinal(a.Key, b.Key));
								foreach (var kv in refList)
								{
									writer.WriteStartObject();
									{
										writer.WritePropertyName("asset");
										writer.WriteValue(kv.Key);
										writer.WritePropertyName("RefCount");
										writer.WriteValue(kv.Value);
									}
									writer.WriteEndObject();
								}
							}
							writer.WriteEndArray();
							writer.WritePropertyName("NoRefAssets:");
							writer.WriteStartArray();
							{
								var noRefList = detail.NotReferencedAssets.ToArray();
								Array.Sort(noRefList, string.CompareOrdinal);
								foreach (var kv in noRefList)
								{
									writer.WriteValue(kv);
								}
							}
							writer.WriteEndArray();
							writer.WritePropertyName("RefByRefAssets:");
							writer.WriteStartArray();
							{
								var noRefList = detail.ReferencedByAssets.ToArray();
								Array.Sort(noRefList, string.CompareOrdinal);
								foreach (var kv in noRefList)
								{
									writer.WriteValue(kv);
								}
							}
							writer.WriteEndArray();
						}
						writer.WriteEndObject();
					}
					writer.WriteEndObject();
					using var csvWrite = new StreamWriter(csvOutput);
					detailList.Sort((a, b) =>
					{
						var ret = b.Percent.CompareTo(a.Percent);
						if (ret == 0)
						{
							ret = b.TotalCount.CompareTo(a.TotalCount);
						}
						if (ret == 0)
						{
							ret = b.NoRefAssetCount.CompareTo(a.NoRefAssetCount);
						}
						return ret;
					});
                    csvWrite.Write("BundleName,AssetCount,RefAssetCount,NoRefAssetCount,RefByRefAssetCount,NoRefPercent");
                    foreach (var bundleRecord in detailList)
                    {
	                    csvWrite.WriteLine(string.Empty);
	                    csvWrite.Write(bundleRecord.BundleName);
	                    csvWrite.Write(',');
	                    csvWrite.Write(bundleRecord.TotalCount);
	                    csvWrite.Write(',');
	                    csvWrite.Write(bundleRecord.RefAssetCount);
	                    csvWrite.Write(',');
	                    csvWrite.Write(bundleRecord.NoRefAssetCount);
	                    csvWrite.Write(',');
	                    csvWrite.Write(bundleRecord.RefByRefAssetCount);
	                    csvWrite.Write(',');
	                    csvWrite.Write(bundleRecord.Percent);
                    }
				}
			}
			
			public delegate bool BundleCompressionFormatProvider(string identifier,
				out UnityEngine.BuildCompression buildCompression);

			private class CustomBundleBuildParameter : BundleBuildParameters
			{
				private BundleCompressionFormatProvider _overrideCompressions;

				public CustomBundleBuildParameter(BuildTarget target, BuildTargetGroup group, string outputFolder) : base(target, group, outputFolder)
				{}

				public void SetBundleCompressionFormatProvider(BundleCompressionFormatProvider provider)
				{
					_overrideCompressions = provider;
				}

				public override UnityEngine.BuildCompression GetCompressionForIdentifier(string identifier)
				{
					if (null == _overrideCompressions) return base.GetCompressionForIdentifier(identifier);
					return _overrideCompressions(identifier, out var ret) ? ret : base.GetCompressionForIdentifier(identifier);
				}
			}
		}
    }
}
