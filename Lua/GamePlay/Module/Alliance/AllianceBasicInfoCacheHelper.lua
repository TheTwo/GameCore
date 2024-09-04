local Delegate = require("Delegate")
local EventConst = require("EventConst")
local LRUList = require("LRUList")

local AllianceParameters = require("AllianceParameters")

---@class AllianceBasicInfoCache
---@field info wrpc.AllianceBriefInfo
---@field expireTime number

---@class AllianceBasicInfoCacheHelper
---@field new fun(expireTimeSec:number, cacheLimit:number):AllianceBasicInfoCacheHelper
local AllianceBasicInfoCacheHelper = class('AllianceBasicInfoCacheHelper')

AllianceBasicInfoCacheHelper.PreFrameLimitCount = 5

---@param expireTimeSec number
---@param cacheLimit number
function AllianceBasicInfoCacheHelper:ctor(expireTimeSec, cacheLimit)
    ---@type number
    self._expireTimeSec = expireTimeSec
    ---@private
    self._cacheInfos = LRUList.new(cacheLimit or 32)
    ---@type number[]
    self._allianceInfoQueue = {}
end

function AllianceBasicInfoCacheHelper:AddEvents()
    g_Game.ServiceManager:AddResponseCallback(AllianceParameters.GetAllianceBasicInfoParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetAllianceBasicInfoReply))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickSendQueueRequest))
end

function AllianceBasicInfoCacheHelper:RemoveEvents()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickSendQueueRequest))
    g_Game.ServiceManager:RemoveResponseCallback(AllianceParameters.GetAllianceBasicInfoParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetAllianceBasicInfoReply))
end

---@private
function AllianceBasicInfoCacheHelper:DoRequestAllianceBasicInfo(allianceIds)
    local sendCmd = AllianceParameters.GetAllianceBasicInfoParameter.new()
    sendCmd.args.AllianceIDs:AddRange(allianceIds)
    sendCmd:Send()
end

function AllianceBasicInfoCacheHelper:DoRequestAllianceBasicInfoInQueue(allianceId)
    for i = #self._allianceInfoQueue, 1, -1 do
        if self._allianceInfoQueue[i] == allianceId then return end
    end
    self._allianceInfoQueue[#self._allianceInfoQueue+1] = allianceId
end

function AllianceBasicInfoCacheHelper:TickSendQueueRequest(dt)
    local limitProcessCountPreFrame = AllianceBasicInfoCacheHelper.PreFrameLimitCount
    while limitProcessCountPreFrame > 0 and #self._allianceInfoQueue > 0 do
        limitProcessCountPreFrame = limitProcessCountPreFrame - 1
        local sendMax = 10
        local allianceIdsBatch = {}
        while sendMax > 0 do
            sendMax = sendMax - 1
            allianceIdsBatch[#allianceIdsBatch + 1] = table.remove(self._allianceInfoQueue, 1)
            if #self._allianceInfoQueue <= 0 then
                break
            end
        end
        self:DoRequestAllianceBasicInfo(allianceIdsBatch)
    end
end

---@param allianceId number
---@return wrpc.AllianceBriefInfo
function AllianceBasicInfoCacheHelper:RequestAllianceBriefInfo(allianceId, forceUpdate)
    if forceUpdate then
        self:DoRequestAllianceBasicInfo({allianceId})
        return nil
    end
    ---@type AllianceBasicInfoCache
    local inCacheInfo = self._cacheInfos:Get(allianceId)
    if not inCacheInfo then
        self:DoRequestAllianceBasicInfoInQueue(allianceId)
        return nil
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if inCacheInfo.expireTime <= nowTime then
        self._cacheInfos:Remove(allianceId)
        self:DoRequestAllianceBasicInfoInQueue(allianceId)
        return nil
    end
    return inCacheInfo.info
end

function AllianceBasicInfoCacheHelper:RemoveCache(allianceId)
    self._cacheInfos:Remove(allianceId)
end

function AllianceBasicInfoCacheHelper:ClearAll()
    table.clear(self._allianceInfoQueue)
    table.clear(self._inWaitingallianceInfo)
    self._cacheInfos:Clear()
end

local function CopyTable(src, dst)
    for i, v in pairs(src) do
        if type(v) == 'table' then
            if not dst[i] or type(dst[i]) ~= 'table' then
                dst[i] = {}
            end
            CopyTable(v, dst[i])
        else
            dst[i] = v
        end
    end
end

---@private
---@param isSuccess boolean
---@param rsp wrpc.GetAllianceBasicInfoReply
function AllianceBasicInfoCacheHelper:OnGetAllianceBasicInfoReply(isSuccess, rsp)
    if not isSuccess then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    for _, value in ipairs(rsp.Infos) do
        local allianceId = value.ID
        ---@type AllianceBasicInfoCache
        local cache = self._cacheInfos:Get(allianceId)
        if cache then
            cache.expireTime = nowTime + self._expireTimeSec
            CopyTable(value, cache.info)
        else
            cache = {
                expireTime = nowTime + self._expireTimeSec,
                info = value,
            }
            self._cacheInfos:Add(allianceId, cache)
        end
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, allianceId, cache.info)
    end
end

return AllianceBasicInfoCacheHelper