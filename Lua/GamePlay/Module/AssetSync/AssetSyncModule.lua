local BaseModule = require('BaseModule')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local TimerUtility = require("TimerUtility")

---@class AssetSyncModule
local AssetSyncModule = class('AssetSyncModule',BaseModule)

function AssetSyncModule:ctor()

end

function AssetSyncModule:OnRegister()   
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function AssetSyncModule:OnRemove()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self.cfgRemoteVersion = nil
    self.cfgCdn = nil
end

---@param remoteVersionDict CS.System.Collections.Generic.Dictionary<string, DragonReborn.VersionDefine.VersionCell>
---@param onDownloadFinish function
---@param onDownloadProgress function
---@param restartOnError boolean
---@param orderList CS.System.Collections.Generic.List<string>
function AssetSyncModule:SyncFiles(remoteVersionDict, onDownloadFinish, onDownloadProgress, restartOnError, orderList)
    local finishAssetCount = 0
    local checkingAssetCount = remoteVersionDict.Count
    local finishedDownloadBytes = 0
    local totalDownloadBytes = self:GetUpdateBytes(remoteVersionDict)

    if checkingAssetCount == 0 then
        if onDownloadFinish then
            onDownloadFinish()
        end

        g_Logger.Log('SyncFiles skip, nothing need sync')
        return
    end

    CS.DragonReborn.VersionControl.SyncFiles(remoteVersionDict, 
        function(result, file)
            finishAssetCount = finishAssetCount + 1
            
            if result == CS.DragonReborn.VersionControl.Result.Success then
                local downloadVersion = CS.DragonReborn.VersionControl.remoteVersion:GetVersion(file)
                finishedDownloadBytes = finishedDownloadBytes + downloadVersion.ZipBytes
                if onDownloadProgress then
                    onDownloadProgress(finishAssetCount, checkingAssetCount, finishedDownloadBytes, totalDownloadBytes)
                end
            end

            if finishAssetCount == checkingAssetCount then
                if onDownloadFinish then
                    onDownloadFinish()
                end
            end
        end, 
        nil, 0, restartOnError, orderList)
end

---@return number @下载总量
function AssetSyncModule:SyncAssetBundles(bundleList, onProgress, onFinish, restartOnError)
    local remoteVersionDict = self:FilterVersionCellsByBundleCollection(bundleList)
    local totalDownloadBytes = self:GetUpdateBytes(remoteVersionDict)
    local finishAssetCount = 0
    local checkingAssetCount = remoteVersionDict.Count
    local finishedDownloadBytes = 0

    if checkingAssetCount == 0 then
        if onFinish then
            onFinish()
        end

        g_Logger.Log('SyncAssetBundles skip, nothing need sync')
        return 0
    end

    CS.DragonReborn.VersionControl.SyncFiles(remoteVersionDict, 
        function(result, file)
            finishAssetCount = finishAssetCount + 1

            if result == CS.DragonReborn.VersionControl.Result.Success then
                local downloadVersion = CS.DragonReborn.VersionControl.remoteVersion:GetVersion(file)
                finishedDownloadBytes = finishedDownloadBytes + downloadVersion.ZipBytes
                if onProgress then
                    onProgress(finishAssetCount, checkingAssetCount, finishedDownloadBytes, totalDownloadBytes)
                end
            end

            if finishAssetCount == checkingAssetCount then
                if onFinish then
                    onFinish()
                end
            end
        end
    ,nil, 0, restartOnError)

    return totalDownloadBytes or 0
end

--为了测试功能方便模拟同步资源的回调
function AssetSyncModule:FakeSyncAssetBundles(csList, onProgress, onFinish)
    if csList == nil or csList.Count <= 0 then
        return 0
    end

    local count = csList.Count
    local quantity = 1000
    local bytes = 0
    local total = quantity * count
    local counter = 0

    local function Tick()
        counter = counter + 1
        bytes = bytes + quantity

        if onProgress then
            onProgress(counter, count, bytes, total)
        end

        if counter == count then
            if onFinish then
                onFinish()
            end
            return
        end
    end

    TimerUtility.IntervalRepeat(Tick, 0.1, count, false)

    return total or 0
end

--- 从VersionDefine中过滤
---@param bundleName string[] @参数为完整的AssetBundle名字(无后缀)
function AssetSyncModule:FilterVersionCellsByBundleParams(...)
    local remoteVersionDict = CS.DragonReborn.VersionControl.remoteVersion:FilterVersionCellsByBundleParams(...)
    local cells = CS.DragonReborn.VersionControl.GetUpdateCells(remoteVersionDict)
    return cells
end

--- 从VersionDefine中过滤
---@param csList CS.System.Collections.Generic.List<string> @参数为完整的AssetBundle名字(无后缀)
function AssetSyncModule:FilterVersionCellsByBundleCollection(csList)
    local remoteVersionDict = CS.DragonReborn.VersionControl.remoteVersion:FilterVersionCellsByBundleCollection(csList)
    local cells = CS.DragonReborn.VersionControl.GetUpdateCells(remoteVersionDict)
    return cells
end

--- 从VersionDefine中过滤
---@param folderPath string @参数为完整的资源所在目录，如: GameAssets/Languages
function AssetSyncModule:FilterVersionCellsByFolderPath(folderPath)
    local remoteVersionDict = CS.DragonReborn.VersionControl.remoteVersion:FilterVersionCellsByFolderPath(folderPath)
    local cells = CS.DragonReborn.VersionControl.GetUpdateCells(remoteVersionDict)
    return cells
end

function AssetSyncModule:GetUpdateBytes(remoteVersionDict)
    return CS.DragonReborn.VersionControl.GetUpdateBytes(remoteVersionDict)
end

--- 从allBundleDict中剔除bundleDict
function AssetSyncModule:GetExcludeBundles(allBundleDict, bundleDict)
    g_Logger.Log('allBundleDict %s', allBundleDict)
    g_Logger.Log('bundleDict %s', bundleDict)
    return CS.DragonReborn.VersionControl.remoteVersion:Excludes(allBundleDict, bundleDict)
end

function AssetSyncModule:FindAsset(filterStr, versionDict)
    for file, cell in pairs(versionDict) do
        if string.find(file, filterStr) then
            return file, cell
        end
    end
end

function AssetSyncModule:FindBundleFolderAsset(filterStr, versionDict)
	local path = self:GetBundleFolderAssetPath(filterStr)
	return path, versionDict[path]
end

function AssetSyncModule:GetBundleFolderAssetPath(fileName)
	local bundlePlateformFolderName = CS.DragonReborn.VersionDefine.GetBundlePlatformFolderName()
	return "GameAssets/AssetBundle/" .. bundlePlateformFolderName .. "/" .. fileName;
end

function AssetSyncModule:NeedSkipSyncState()
    if ModuleRefer.AppInfoModule:RuntimeLocalAssetOnly() then
        return true
    end

    return false
end

return AssetSyncModule
