local EventConst = require("EventConst")
local Delegate = require("Delegate")

local BaseModule = require("BaseModule")

---@class PlayerCustomIconModule:BaseModule
---@field new fun():BaseModule
---@field super BaseModule
local PlayerCustomIconModule = class('PlayerCustomIconModule', BaseModule)

PlayerCustomIconModule.CacheFileLimit = 100
PlayerCustomIconModule.UseMd5FileName = true
PlayerCustomIconModule.CacheFolderName = 'avatar'
PlayerCustomIconModule.NotifyIdx = 1

function PlayerCustomIconModule:ctor()
    PlayerCustomIconModule.super.ctor(self)
    ---@type table<string, {reqIds:number[], avatar:string}>
    self._downloadingMap = {}
    self._inNotify = false
end

function PlayerCustomIconModule:OnRegister()
    local folderFullPath = CS.System.IO.Path.Combine(CS.UnityEngine.Application.persistentDataPath, PlayerCustomIconModule.CacheFolderName)
    ---@private
    self._fileCache = CS.DragonReborn.Utilities.ExternalImageCache(folderFullPath, PlayerCustomIconModule.CacheFileLimit, PlayerCustomIconModule.UseMd5FileName)
    self._fileCache:TryClearCache()
    self._spriteCache = CS.DragonReborn.Utilities.RuntimeSpriteCache(self._fileCache)
end

function PlayerCustomIconModule:OnRemove()
    self._spriteCache:Reset()
end

---@param customAvatar string
---@param image CS.UnityEngine.UI.Image
---@return boolean,number
function PlayerCustomIconModule:LoadSpite(customAvatar, image)
    if string.IsNullOrEmpty(customAvatar) then
        g_Logger.Error("PlayerCustomIconModule:LoadSpite empty customAvatar")
        return false, 0
    end
    local url = self:GetUrl(customAvatar)
    if self._spriteCache:LoadSprite(url, image) then
        return true, 0
    end
    if self._inNotify then
        g_Logger.Error("PlayerCustomIconModule:LoadSpite in download callback!!!")
        return false, 0
    end
    local reqIndex = self:NextId()
    local notifyMap = self._downloadingMap[url]
    if not notifyMap then
        notifyMap = {}
        notifyMap.reqIds = { reqIndex}
        notifyMap.avatar = customAvatar
        self._downloadingMap[url] = notifyMap
        local savePath = self._fileCache:GetIconPath(url)
        g_Game.DownloadManager.manager:DownloadAsset(url, savePath, Delegate.GetOrCreate(self, self.OnDownloadEnd))
    else
        notifyMap.reqIds[#notifyMap.reqIds + 1] = reqIndex
    end
    return true, reqIndex
end

---@param customAvatar string
---@return string
function PlayerCustomIconModule:GetUrl(customAvatar)
    return customAvatar
end

---@private
function PlayerCustomIconModule:NextId()
    local index = PlayerCustomIconModule.NotifyIdx
    if index == 2147483647 then
        PlayerCustomIconModule.NotifyIdx = 1
    else
        PlayerCustomIconModule.NotifyIdx = PlayerCustomIconModule.NotifyIdx + 1
    end
    return index
end

---@param success boolean
---@param httpData CS.DragonReborn.HttpResponseData
function PlayerCustomIconModule:OnDownloadEnd(success, httpData)
    if not success then
        if httpData then
            self._downloadingMap[httpData.Url] = nil
        end
    else
        if httpData then
            local notifyIds = self._downloadingMap[httpData.Url]
            self._downloadingMap[httpData.Url] = nil
            if notifyIds then
                local eventMgr = g_Game.EventManager
                self._inNotify = true
                for _, id in ipairs(notifyIds.reqIds) do
                    eventMgr:TriggerEvent(EventConst.PLAYER_CUSTOM_ICON_READY, id, notifyIds.avatar)
                end
                self._inNotify = false
            end
        end
    end
end

return PlayerCustomIconModule