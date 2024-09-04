---@class ConfigDownloadHolder
---@field new fun(name, onProgress, onFinish, onFailed, useLatest):ConfigDownloadHolder
local ConfigDownloadHolder = sealedClass("ConfigDownloadHolder")
local Delegate = require("Delegate")

---@param name string
---@param onProgress fun(downloadedBytes:number, allBytes:number)
---@param onFinish fun()
---@param useLatest boolean @是否使用'lastest/'路径
function ConfigDownloadHolder:ctor(name, onProgress, onFinish, onFailed, useLatest, needRestart)
    self.name = name

    self.downloadUrl = g_Game.ConfigManager:GetPackCdnPath(name, useLatest)
    self.savePath = g_Game.ConfigManager:GetPackSavePath(name)
    self.progressCallback = onProgress
    self.finishCallback = onFinish
    self.failedCallback = onFailed
    self.needRestart = needRestart
end

function ConfigDownloadHolder:StartDownload()
    if string.IsNullOrEmpty(self.downloadUrl) then
        self:OnDownloadFinished(false, nil)
        return
    end

    self.downloadStartTime = CS.UnityEngine.Time.realtimeSinceStartup
    self.downloadedBytes = 0
    self.downloaded = false

    g_Game.DownloadManager.manager:DownloadAsset(self.downloadUrl, self.savePath, Delegate.GetOrCreate(self, self.OnDownloadFinished), Delegate.GetOrCreate(self, self.OnProgress), 0, 0, self.needRestart)
end

function ConfigDownloadHolder:OnDownloadFinished(flag, httpResponseData)
    self.downloaded = flag
    CS.DragonReborn.IOUtils.UpdateDocumentBundleAssetMap(("GameConfigs/%s"):format(self.name))
    if self.downloaded and self.finishCallback then
        self.finishCallback()
    elseif not self.downloaded and self.failedCallback then
        self.failedCallback()
    end
end

function ConfigDownloadHolder:OnProgress(downloadedBytes, allBytes)
    self.downloadedBytes = downloadedBytes
    self.allBytes = allBytes
    if self.progressCallback then
        self.progressCallback(self.downloadedBytes, self.allBytes)
    end
end

return ConfigDownloadHolder