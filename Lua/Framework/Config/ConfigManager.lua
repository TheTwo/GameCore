---@class ConfigManager
---@field new fun():ConfigManager
local ConfigManager = class("ConfigManager", require("BaseManager"))
local ConfigWrapFactory = require("ConfigWrapFactory")

function ConfigManager:ctor()
    self.cacheConfigs = {}
    self.traceRetrieveCfg = false
    self.cfgName2Stacktrace = {}
end

function ConfigManager:Reset()
    table.clear(self.cacheConfigs)
end

function ConfigManager:SwitchTrace(flag)
    self.traceRetrieveCfg = flag
end

function ConfigManager:RetrieveConfig(name)
    if self.cacheConfigs[name] then
        return self.cacheConfigs[name]
    end

    if self.traceRetrieveCfg then
        self.cfgName2Stacktrace[name] = debug.traceback()
    end
    return self:CreateWrap(name)
end

function ConfigManager:CreateWrap(name)
    local ret = ConfigWrapFactory.CreateWrap(name)
    self.cacheConfigs[name] = ret
    return ret
end

function ConfigManager:CheckCachedConfig()
    for name, wrap in pairs(self.cacheConfigs) do
        if self.cfgName2Stacktrace[name] then
            g_Logger.ErrorChannel("ConfigManager", "Config [%s] is cached before SyncConfigState Finished,\n%s", name, self.cfgName2Stacktrace[name])
        else
            g_Logger.ErrorChannel("ConfigManager", "Config [%s] is cached before SyncConfigState Finished", name)
        end
    end
end

function ConfigManager:RecordRemoteConfigInfo(configBranch, configRevision, downloadCdn)
    self.remoteConfigBranch = configBranch
    self.remoteConfigRevision = configRevision
    self.remoteConfigCdnUrlBase = downloadCdn

    g_Logger.TraceChannel("ConfigManager", "Remote Config Version Info :[%s:%s]", self.remoteConfigBranch, self.remoteConfigRevision)
end

function ConfigManager:GetLastestCdnUrl()
    return ("%s/config/%s/latest"):format(self.remoteConfigCdnUrlBase, self.remoteConfigBranch)
end

function ConfigManager:GetNumberCdnUrl()
    return ("%s/config/%s/%s"):format(self.remoteConfigCdnUrlBase, self.remoteConfigBranch, self.remoteConfigRevision)
end

function ConfigManager:GetRemoteConfigVersion()
    return self.remoteConfigBranch, self.remoteConfigRevision
end

function ConfigManager:GetPackCdnPath(packName, useLatest)
    if string.IsNullOrEmpty(self.remoteConfigCdnUrlBase) then
        return string.Empty
    end
    if useLatest then
        return ("%s/%s"):format(self:GetLastestCdnUrl(), packName)
    else
        return ("%s/%s"):format(self:GetNumberCdnUrl(), packName)
    end
end

function ConfigManager:GetPackSavePath(packName)
    return CS.System.IO.Path.Combine(CS.UnityEngine.Application.persistentDataPath, ("GameConfigs/%s"):format(packName))
end

function ConfigManager:InitLocalConfigInfo()
    self.packageConfigRevision = -1
    self.documentConfigRevision = -1

    if CS.DragonReborn.IOUtils.HaveGameAssetInDocument("GameConfigs/config_vcs.bin") then
        local content = CS.DragonReborn.IOUtils.ReadGameAssetAsText("GameConfigs/config_vcs.bin")
        local _, version = string.match(content, "BranchName=([%w_%.]+),Revision=([%w_]+)")
        self.documentConfigRevision = version
    end

    if CS.DragonReborn.IOUtils.HaveGameAssetInPackage("GameConfigs/config_vcs.bin") then
        local content = CS.DragonReborn.IOUtils.ReadStreamingAssetAsText("GameConfigs/config_vcs.bin")
        local _, version = string.match(content, "BranchName=([%w_%.]+),Revision=([%w_]+)")
        self.packageConfigRevision = version
    end

    g_Logger.TraceChannel("ConfigManager", "Init Local Config Version : Document[%s]; Package[%s]", self.documentConfigRevision, self.packageConfigRevision)
end

function ConfigManager:UpdateLocalConfigSyncToRemote()
    ---NOTE: 此处取的是服务器cdn所指的最新版本, 开发期并不一定保证和服务器所用版本完全一致, 但是此处依然将服务器所用版本的号记录为配置版本号
    ---NOTE: 此配置的切实版本号在Configs.pack压缩文件中取出内嵌的config_vcs.bin文件读取即可获得精确的版本描述
    local content = ("BranchName=%s,Revision=%s"):format(self.remoteConfigBranch, self.remoteConfigRevision)
    CS.DragonReborn.IOUtils.WriteGameAsset("GameConfigs/config_vcs.bin", content)
    self.documentConfigRevision = self.remoteConfigRevision

    g_Logger.TraceChannel("ConfigManager", "Update Document Config Version to [%s]", self.documentConfigRevision)
end

function ConfigManager:HasLocalConfigPack()
    return CS.DragonReborn.IOUtils.HaveGameAsset("GameConfigs/Configs.pack")
end

function ConfigManager:IsConfigVersionMatchRemote()
    return self:IsDocumentConfigVersionMatch() or self:IsPackageConfigVersionMatch()
end

function ConfigManager:IsDocumentConfigVersionMatch()
    return self.documentConfigRevision ~= nil and self.documentConfigRevision == self.remoteConfigRevision
end

function ConfigManager:IsPackageConfigVersionMatch()
    return self.packageConfigRevision ~= nil and self.packageConfigRevision == self.remoteConfigRevision
end

return ConfigManager