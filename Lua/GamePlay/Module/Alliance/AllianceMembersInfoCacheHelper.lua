local Delegate = require("Delegate")
local EventConst = require("EventConst")
local LRUList = require("LRUList")
local AllianceModuleDefine = require("AllianceModuleDefine")

local AllianceParameters = require("AllianceParameters")

---@class AllianceMembersInfoCache
---@field leader wrpc.AllianceMemberInfo
---@field members wrpc.AllianceMemberInfo[]
---@field expireTime number

---@class AllianceMembersInfoCacheHelper
---@field new fun(expireTimeSec:number, cacheLimit:number):AllianceMembersInfoCacheHelper
local AllianceMembersInfoCacheHelper = class('AllianceMembersInfoCacheHelper')

---@param expireTimeSec number
---@param cacheLimit number
function AllianceMembersInfoCacheHelper:ctor(expireTimeSec, cacheLimit)
    ---@type number
    self._expireTimeSec = expireTimeSec
    ---@private
    self._cacheInfos = LRUList.new(cacheLimit or 32)
end

function AllianceMembersInfoCacheHelper:AddEvents()
    g_Game.ServiceManager:AddResponseCallback(AllianceParameters.GetAllianceMembersParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetAllianceMembersInfoReply))
end

function AllianceMembersInfoCacheHelper:RemoveEvents()
    g_Game.ServiceManager:RemoveResponseCallback(AllianceParameters.GetAllianceMembersParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetAllianceMembersInfoReply))
end

---@private
function AllianceMembersInfoCacheHelper:DoRequestAllianceMemberInfo(allianceId)
    local sendCmd = AllianceParameters.GetAllianceMembersParameter.new()
    sendCmd.args.AllianceID = allianceId
    sendCmd:Send(nil, allianceId)
end

---@param allianceId number
---@return AllianceMembersInfoCache
function AllianceMembersInfoCacheHelper:RequestAllianceMemberInfo(allianceId, forceUpdate)
    if forceUpdate then
        self:DoRequestAllianceMemberInfo(allianceId)
        return nil
    end
    ---@type AllianceMembersInfoCache
    local inCacheInfo = self._cacheInfos:Get(allianceId)
    if not inCacheInfo then
        self:DoRequestAllianceMemberInfo(allianceId)
        return nil
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if inCacheInfo.expireTime <= nowTime then
        self._cacheInfos:Remove(allianceId)
        self:DoRequestAllianceMemberInfo(allianceId)
        return nil
    end
    return inCacheInfo
end

function AllianceMembersInfoCacheHelper:RemoveCache(allianceId)
    self._cacheInfos:Remove(allianceId)
end

function AllianceMembersInfoCacheHelper:ClearAll()
    self._cacheInfos:Clear()
end

---@private
---@param isSuccess boolean
---@param rsp wrpc.GetAllianceMembersReply
---@param req GetAllianceMembersParameter
function AllianceMembersInfoCacheHelper:OnGetAllianceMembersInfoReply(isSuccess, rsp, req)
    if not isSuccess then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local allianceId = req.userdata
    if not allianceId then
        return
    end
    ---@type AllianceMembersInfoCache
    local cache = self._cacheInfos:Get(allianceId)
    if cache then
        cache.expireTime = nowTime + self._expireTimeSec
        if not cache.members then
            cache.members = {}
        end
        cache.leader = nil
        table.clear(cache.members)
        for i, v in ipairs(rsp.Members) do
            cache.members[i] = v
            if v.Rank == AllianceModuleDefine.LeaderRank then
                cache.leader = v
            end
        end
    else
        cache = {
            expireTime = nowTime + self._expireTimeSec,
            members = {},
            leader = nil,
        }
        for i, v in ipairs(rsp.Members) do
            cache.members[i] = v
            if v.Rank == AllianceModuleDefine.LeaderRank then
                cache.leader = v
            end
        end
        self._cacheInfos:Add(allianceId, cache)
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_MEMBERS_INFO_CACHE_UPDATE, allianceId, cache)
end

return AllianceMembersInfoCacheHelper