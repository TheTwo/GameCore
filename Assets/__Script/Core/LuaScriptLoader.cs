using System;
using System.Collections.Generic;
using System.IO;
using DragonReborn;
using DragonReborn.AssetTool;
using UnityEngine;
using FileMode = System.IO.FileMode;

// ReSharper disable once CheckNamespace
public static class LuaScriptLoader
{
    public static string LuacFolderRelativePath = AssetPath.Combine("GameAssets", "Luac");
    public static string LuacPackPreFix = "Luac_";
    public static string LuacPackRelativePath = AssetPath.Combine("GameAssets", "Luac.pack");
    public static string ConfigsFolderRelativePath = AssetPath.Combine("GameConfigs", "Configs");
    public static string ConfigsPackRelativePath = AssetPath.Combine("GameConfigs", "Configs.pack");
    public static int MaxFilesCount = 4096;
    public static int BUDGET_SIZE = 8;
    public static HashSet<string> SpecialFileNames = new() { "LogicVersion" }; 

    internal static uint GetHashCode_djb2(string fileName)
    {
	    uint hash = 5381;
	    foreach (char c in fileName)
	    {
		    hash = ((hash << 5) + hash) + c; // hash * 33 + c
	    }
	    return hash;
    }

    private static string GetFinalName(string originName)
    {
        var dot = originName.LastIndexOf(".", StringComparison.Ordinal);
        return dot < 0 ? originName : originName[(dot + 1)..];
    }

    public static byte[] LoadLuacFromPack(ref string relativePath)
    {
#if UNITY_EDITOR
        if (relativePath == "emmy_core") //for emmylua debuger
        {
            return null;
        }
#endif
		// 本地热修复加载
		if (LoadLocalHotfixLua(ref relativePath, out var data))
		{
			return data;
		}

        // 从Luac.ssr中读
        string splitPackName;
        var filename = GetFinalName(relativePath);
        if (SpecialFileNames.Contains(filename))
        {
	        splitPackName = $"{LuacPackPreFix}Special.pack";
        }
        else
        {
	        var hashCode = GetHashCode_djb2(filename) % BUDGET_SIZE;
	        splitPackName = $"{LuacPackPreFix}{hashCode}.pack";
        }
        if (!FileSystemManager.Instance.HasFileSystem(splitPackName))
        {
	        splitPackName = LuacPackRelativePath;
        }
        var bytes = FileSystemManager.Instance.ReadFile(AssetPath.Combine("GameAssets", splitPackName), filename, false);
        return bytes;
    }

    public static ReadOnlySpan<byte> LoadLuacFromPack2(ref string relativePath)
    {
#if UNITY_EDITOR
	    if (relativePath == "emmy_core") //for emmylua debuger
	    {
		    return default;
	    }
#endif
	    // 本地热修复加载
	    if (LoadLocalHotfixLua2(ref relativePath, out var data))
	    {
		    return data;
	    }

	    // 从Luac.ssr中读
	    string splitPackName;
	    var filename = GetFinalName(relativePath);
	    if (SpecialFileNames.Contains(filename))
	    {
		    splitPackName = AssetPath.Combine("GameAssets", $"{LuacPackPreFix}Special.pack");    
	    }
	    else
	    {
		    var hashCode = GetHashCode_djb2(filename) % BUDGET_SIZE;
		    splitPackName = AssetPath.Combine("GameAssets", $"{LuacPackPreFix}{hashCode}.pack");
	    }
	    if (FileSystemManager.Instance.HasFileSystem(splitPackName))
			return !FileSystemManager.Instance.ReadFile(LuaScriptReadBuffer, splitPackName, filename,  out var ret1,false) ? default : ret1;
	    return !FileSystemManager.Instance.ReadFile(LuaScriptReadBuffer, LuacPackRelativePath, filename,  out var ret,false) ? default : ret;
    }
    
    public static byte[] LoadLuacFromGameAssets(ref string relativePath)
    {
#if UNITY_EDITOR
        if (relativePath == "emmy_core") //for emmylua debuger
        {
            return null;
        }
#endif

        // IOUtils需要资源后缀名
        string splitFileName;
        var fileName = GetFinalName(relativePath);
        if (SpecialFileNames.Contains(fileName))
        {
	        splitFileName = AssetPath.Combine($"GameAssets/Luac/Special", fileName + ".txt"); 
        }
        else
        {
	        var hashCode = GetHashCode_djb2(fileName) % BUDGET_SIZE;
	        splitFileName = AssetPath.Combine($"GameAssets/Luac/{hashCode}", fileName + ".txt");
        }
        if (!IOUtils.HaveGameAsset(splitFileName))
        {
	        splitFileName = AssetPath.Combine("GameAssets/Luac", fileName + ".txt");
        }
        var bytes = DragonReborn.IOUtils.ReadGameAsset(splitFileName);
        return bytes;
    }

    public static byte[] LoadLuacFromProjFolder(ref string relativePath)
    {
#if UNITY_EDITOR
	    if (relativePath == "emmy_core") //for emmylua debuger
	    {
		    return null;
	    }
#endif
		// 本地热修复加载
		if (LoadLocalHotfixLua(ref relativePath, out var data))
		{
			return data;
		}

		string splitFileName;
		var fileName = GetFinalName(relativePath);
		if (SpecialFileNames.Contains(fileName))
		{
			splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac/Special", fileName + ".txt");
		}
		else
		{
			var hashCode = GetHashCode_djb2(fileName) % BUDGET_SIZE;
			splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac/{hashCode}", fileName + ".txt");
		}
	    try
	    {
		    if (!File.Exists(splitFileName))
			    splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac", fileName + ".txt");
		    
		    using var fileStream = new FileStream(splitFileName, FileMode.Open);
		    if (fileStream.CanRead)
		    {
			    using var binaryReader = new BinaryReader(fileStream);
			    return binaryReader.ReadBytes((int)fileStream.Length);
		    }

		    return null;
	    }
	    catch (IOException)
	    {
		    return null;
	    }
    }
    
    public static ReadOnlySpan<byte> LoadLuacFromProjFolder2(ref string relativePath)
    {
#if UNITY_EDITOR
	    if (relativePath == "emmy_core") //for emmylua debuger
	    {
		    return default;
	    }
#endif
	    // 本地热修复加载
	    if (LoadLocalHotfixLua2(ref relativePath, out var data))
	    {
		    return data;
	    }

	    string splitFileName;
	    var fileName = GetFinalName(relativePath);
	    if (SpecialFileNames.Contains(fileName))
	    {
		    splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac/Special", fileName + ".txt");
	    }
	    else
	    {
		    var hashCode = GetHashCode_djb2(fileName) % BUDGET_SIZE;
		    splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac/{hashCode}", fileName + ".txt");
	    }
	    try
	    {
		    if (!File.Exists(splitFileName))
		    {
			    splitFileName = AssetPath.Combine(Application.dataPath, $"../Luac", fileName + ".txt");
		    }
		    
		    using var fileStream = new FileStream(splitFileName, FileMode.Open);
		    if (fileStream.CanRead)
		    {
			    using var binaryReader = new BinaryReader(fileStream);
			    var span = LuaScriptReadBuffer.BeginReadSpan((int)fileStream.Length);
			    ReadOnlySpan<byte> ret;
			    var readSize = 0;
			    try
			    { 
				    readSize = binaryReader.Read(span);
			    }
			    finally
			    {
				    ret = LuaScriptReadBuffer.EndReadSpan(in span, readSize);
			    }
			    return ret;
		    }

		    return default;
	    }
	    catch (IOException)
	    {
		    return default;
	    }
    }

    public static void OnLowMemory()
    {
	    LuaScriptReadBuffer.ClearBuffer();
    }

    private static readonly IReadBuffer LuaScriptReadBuffer = new ReadBuffer();

    private sealed unsafe class ReadBuffer : IReadBuffer, IDisposable
    {
	    private const int BufferLimit = 20 * 1024 * 1024;
	    private byte[] _loadLuacBuffer;
	    private System.Runtime.InteropServices.GCHandle _gcHandle;
	    private int _readLength;
	    private IntPtr _readPtr;
	    private bool _markReleaseBuffer;

	    void IReadBuffer.ClearBuffer()
	    {
		    // clear ref, wait gc
		    if (null == _loadLuacBuffer) return;
		    if (_gcHandle.IsAllocated)
		    {
			    _markReleaseBuffer = true;
		    }
		    else
		    {
			    _loadLuacBuffer = null;
		    }
	    }

	    IntPtr IReadBuffer.BeginReadPtr(int size)
	    {
		    CleanupLastRead();
		    EnsureCapacity(size);
		    RecordRead(size);
		    return _readPtr;
	    }

	    ReadOnlySpan<byte> IReadBuffer.EndReadPtr(IntPtr ptr)
	    {
		    if (!_gcHandle.IsAllocated || _readPtr != ptr) return default;
		    ReadOnlySpan<byte> ret = _loadLuacBuffer.AsSpan(0, _readLength);
		    CleanupLastRead();
		    return ret;
	    }

	    Span<byte> IReadBuffer.BeginReadSpan(int size)
	    {
		    CleanupLastRead();
		    EnsureCapacity(size);
		    RecordRead(size);
		    var ret = _loadLuacBuffer.AsSpan(0, size);
		    return ret;
	    }

	    ReadOnlySpan<byte> IReadBuffer.EndReadSpan(in Span<byte> origin, int readSize)
	    {
		    if (!_gcHandle.IsAllocated || _readLength != readSize || readSize > origin.Length) return default;
		    fixed (void* p = origin)
		    {
			    if (new IntPtr(p) != _readPtr) return default;
		    }
		    ReadOnlySpan<byte> ret = origin[..readSize];
		    CleanupLastRead();
		    return ret;
	    }

	    private void RecordRead(int size)
	    {
		    _readLength = size;
		    _gcHandle = System.Runtime.InteropServices.GCHandle.Alloc(_loadLuacBuffer, System.Runtime.InteropServices.GCHandleType.Pinned);
		    _readPtr = _gcHandle.AddrOfPinnedObject();
	    }

#if UNITY_DEBUG
	    private void CleanupLastRead([System.Runtime.CompilerServices.CallerMemberName] string caller = null)
#else
	    private void CleanupLastRead()
#endif
	    {
		    if (_gcHandle.IsAllocated)
		    {
#if UNITY_DEBUG
			    if (caller is nameof(IReadBuffer.BeginReadSpan) or nameof(IReadBuffer.BeginReadPtr))
			    {
				    throw new InvalidOperationException(
					    $"{nameof(CleanupLastRead)} called before {nameof(IReadBuffer.BeginReadSpan)}/{nameof(IReadBuffer.BeginReadPtr)} but {nameof(_gcHandle)} not freed, this may caused by more than one calling buffer at same time");
			    }
#endif
			    _gcHandle.Free();
		    }
		    _gcHandle = default;
		    _readPtr = IntPtr.Zero;
		    _readLength = 0;
		    if (!_markReleaseBuffer) return;
		    _markReleaseBuffer = false;
		    _loadLuacBuffer = null;
	    }

	    private void EnsureCapacity(int size)
	    {
		    if (size > BufferLimit)
		    {
			    throw new ArgumentOutOfRangeException($"{nameof(size)} must less than {nameof(BufferLimit)}({BufferLimit})");
		    }
		    if (_loadLuacBuffer == null)
		    {
			    _loadLuacBuffer = new byte[size];
		    }
		    else if (_loadLuacBuffer.Length < size)
		    {
			    var nextSize = Math.Min(BufferLimit, Mathf.NextPowerOfTwo(_loadLuacBuffer.Length));
			    if (nextSize < size) nextSize = size;
			    Array.Resize(ref _loadLuacBuffer, nextSize);
		    }
	    }

	    public void Dispose()
	    {
		    CleanupLastRead();
		    _loadLuacBuffer = default;
	    }
    }
    
#if UNITY_EDITOR
    private static readonly System.Collections.Generic.Dictionary<string, string> CachedLuaPath = new();
    private static readonly string LuaScriptRootPathEditor =
	    AssetPath.Combine(Application.dataPath, "../Lua/");
    static void FindChildLuaFile(DirectoryInfo directoryInfo)
    {
        if (!directoryInfo.Exists)
        {
            NLogger.Error("ssr-logic目录下找不到Lua文件夹");
            return;
        }
            
        foreach (var fileInfo in directoryInfo.GetFiles("*.lua" ,SearchOption.AllDirectories))
        {
            // remove ".lua" extension
            CachedLuaPath.Add(fileInfo.Name[..^4], fileInfo.FullName);
        }
    }

    static void InitCachedLuaPath(string rootPath)
    {
        if (CachedLuaPath.Count != 0)
        {
            return;
        }

        // if (LogicRepoUtils.IsSsrLogicRepoExist())
            FindChildLuaFile(new DirectoryInfo(rootPath));
    }

    internal static void ClearCache()
    {
        CachedLuaPath.Clear();
    }
    
    public static byte[] LoadFromAssetManagerEditor(ref string relativePath)
    {
        if (relativePath == "emmy_core") //for emmylua debuger
        {
            return null;
        }

        var finalPath = GetFinalName(relativePath);
        InitCachedLuaPath(LuaScriptRootPathEditor);
        if (CachedLuaPath.TryGetValue(finalPath, out var path))
        {
            relativePath = path;
            return File.ReadAllBytes(relativePath);
        }

        return null;
    }
    
    public static ReadOnlySpan<byte> LoadFromAssetManagerEditor2(ref string relativePath)
    {
	    if (relativePath == "emmy_core") //for emmylua debuger
	    {
		    return default;
	    }

	    var finalPath = GetFinalName(relativePath);
	    InitCachedLuaPath(LuaScriptRootPathEditor);
	    if (CachedLuaPath.TryGetValue(finalPath, out var path))
	    {
		    relativePath = path;
		    using var fs = File.OpenRead(relativePath);
		    var span = LuaScriptReadBuffer.BeginReadSpan((int)fs.Length);
		    ReadOnlySpan<byte> ret;
		    var readSize = 0;
		    try
		    {
			    readSize = fs.Read(span);
		    }
		    finally
		    {
			    ret = LuaScriptReadBuffer.EndReadSpan(in span, readSize);
		    }
		    return ret;
	    }
	    return default;
    }
#endif
    public static void GenerateLuacPack(bool deleteSrc = false)
    {
        var luacFolderFullPath = AssetPath.Combine(Application.streamingAssetsPath, LuacFolderRelativePath);
        var luacPackFullPath = AssetPath.Combine(Application.streamingAssetsPath, LuacPackRelativePath);

        if (File.Exists(luacPackFullPath))
        {
            File.Delete(luacPackFullPath);
        }

        string[] filenames = Directory.GetFiles(luacFolderFullPath, "*.txt", SearchOption.AllDirectories);
        var packFileStream = new CommonFileSystemStream(luacPackFullPath, FileSystemAccess.ReadWrite, true);
        var vfs = FileSystem.Create(luacPackFullPath, FileSystemAccess.ReadWrite, packFileStream, MaxFilesCount, MaxFilesCount);
        foreach (var assetPath in filenames)
        {
            var assetFileStream = new FileStream(assetPath, FileMode.Open, FileAccess.Read, FileShare.Read);
            var fileName = Path.GetFileNameWithoutExtension(assetPath);
            vfs.WriteFile(fileName, assetFileStream);
            NLogger.Log($"Write {fileName} into {luacPackFullPath}");
            assetFileStream.Close();
        }

        var blockCount = vfs.BlockCount;
        var maxBlockCount = vfs.MaxBlockCount;
        NLogger.Warn($"Pack {LuacPackRelativePath}, block {blockCount}, max block {maxBlockCount}, used {blockCount * 100 / (float)maxBlockCount}%");

        vfs.Shutdown();

        if (deleteSrc)
        {
            Directory.Delete(luacFolderFullPath, true);
        }
    }

    public static void GenerateConfigsPack(bool deleteSrc = false)
    {
        var configsFolderFullpath = AssetPath.Combine(Application.streamingAssetsPath, ConfigsFolderRelativePath);
        var configsPackFullpath = AssetPath.Combine(Application.streamingAssetsPath, ConfigsPackRelativePath);

        if (File.Exists(configsPackFullpath))
        {
            File.Delete(configsPackFullpath);
        }

        string[] filenames = Directory.GetFiles(configsFolderFullpath, "*.bin", SearchOption.AllDirectories);
        var packFileStream = new CommonFileSystemStream(configsPackFullpath, FileSystemAccess.ReadWrite, true);
        var vfs = FileSystem.Create(configsPackFullpath, FileSystemAccess.ReadWrite, packFileStream, MaxFilesCount, MaxFilesCount);
        foreach (var assetPath in filenames)
        {
            var assetFileStream = new FileStream(assetPath, FileMode.Open, FileAccess.Read, FileShare.Read);
            var fileName = Path.GetFileNameWithoutExtension(assetPath);
            vfs.WriteFile(fileName, assetFileStream);
            NLogger.Log($"Write {fileName} into {configsPackFullpath}");
            assetFileStream.Close();
        }

        var blockCount = vfs.BlockCount;
        var maxBlockCount = vfs.MaxBlockCount;
        NLogger.Warn($"Pack {ConfigsPackRelativePath}, block {blockCount}, max block {maxBlockCount}, used {blockCount * 100 / (float)maxBlockCount}%");

        vfs.Shutdown();

        if (deleteSrc)
        {
            Directory.Delete(configsFolderFullpath, true);
        }
    }

    // ReSharper disable once InconsistentNaming
    private const string LOCAL_HOTFIX_LUA_FOLDER_NAME = "_hotfix";
    // ReSharper disable once InconsistentNaming
    public const string LOCAL_HOTFIX_LUA_EXT = ".lua";

	public static string GetLocalHotfixFolder()
	{
		return AssetPath.Combine(PathHelper.PersistentDataPath, LOCAL_HOTFIX_LUA_FOLDER_NAME);
	}
	
	/// <summary>
	/// 加载本地热修复Lua文件
	/// </summary>
	/// <param name="relativePath"></param>
	/// <param name="data"></param>
	/// <returns></returns>
	public static bool LoadLocalHotfixLua(ref string relativePath, out byte[] data)
	{
		data = null;
//#if USE_LOCAL_HOTFIX
		if (string.IsNullOrEmpty(relativePath)) return false;
		var filename = GetFinalName(relativePath);
		var path = AssetPath.Combine(GetLocalHotfixFolder(), $"{filename}{LOCAL_HOTFIX_LUA_EXT}");
		if (File.Exists(path))
		{
			Debug.LogWarning($"从本地热修复路径加载Lua: {path}");
			data = File.ReadAllBytes(path);
			return true;
		}
//#endif
		return false;
	}
	
	public static bool LoadLocalHotfixLua2(ref string relativePath, out ReadOnlySpan<byte> data)
	{
		data = default;
//#if USE_LOCAL_HOTFIX
		if (string.IsNullOrEmpty(relativePath)) return false;
		var filename = GetFinalName(relativePath);
		var path = Path.Combine(GetLocalHotfixFolder(), $"{filename}{LOCAL_HOTFIX_LUA_EXT}");
		if (File.Exists(path))
		{
			Debug.LogWarning($"从本地热修复路径加载Lua: {path}");
			data = File.ReadAllBytes(path);
			return true;
		}
//#endif
		return false;
	}

	public static bool ClearHotfixFolder()
	{
		var folder = GetLocalHotfixFolder();
		if (Directory.Exists(folder))
		{
			Directory.Delete(folder, true);
			return true;
		}

		return false;
	}
}
