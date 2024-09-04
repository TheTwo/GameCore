local Delegate = require("Delegate")
local JoinTeamTrusteeshipTargetInfoParameter = require("JoinTeamTrusteeshipTargetInfoParameter")
local ProtocolId = require("ProtocolId")
local EventConst = require("EventConst")

---@class HUDSelectTroopAssembleTimePreFetch
---@field new fun():HUDSelectTroopAssembleTimePreFetch
local HUDSelectTroopAssembleTimePreFetch = sealedClass('HUDSelectTroopAssembleTimePreFetch')

function HUDSelectTroopAssembleTimePreFetch:ctor()
    ---@type table<string, wrpc.TeamTrusteeshipTargetInfo>
    self._cache = {}
    self._isInit = false
end

function HUDSelectTroopAssembleTimePreFetch:Init()
    if self._isInit then
        return
    end
    self._isInit = true
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.JoinTeamTrusteeshipTargetInfo, Delegate.GetOrCreate(self, self.OnServerResponse))
end

function HUDSelectTroopAssembleTimePreFetch:MakeKey(captainId, targetId, troopPresetQueueIndex)
   return ("%s_%s_%s"):format(captainId,targetId,troopPresetQueueIndex)
end

function HUDSelectTroopAssembleTimePreFetch:ClearCache()
    table.clear(self._cache)
end

function HUDSelectTroopAssembleTimePreFetch:Release()
    if not self._isInit then
        return
    end
    self._isInit = false
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.JoinTeamTrusteeshipTargetInfo, Delegate.GetOrCreate(self, self.OnServerResponse))
end

---@return wrpc.TeamTrusteeshipTargetInfo|nil
function HUDSelectTroopAssembleTimePreFetch:FetchOrGetCache(captainId, targetId, troopPresetQueueIndex)
    local key = self:MakeKey(captainId, targetId, troopPresetQueueIndex)
    local cache = self._cache[key]
    if cache then
        return cache
    end
    local sendCmd = JoinTeamTrusteeshipTargetInfoParameter.new()
    sendCmd.args.CaptainId = captainId
    sendCmd.args.TargetId = targetId
    sendCmd.args.JoinQueueIndex = troopPresetQueueIndex - 1
    sendCmd:SendOnceCallback(nil, key, nil, nil, function(msgId, errorCode, jsonTable)
        g_Game.EventManager:TriggerEvent(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE_FAILED, key, errorCode)
        return errorCode == 28001
    end)
    return nil
end

---@param isSuccess boolean
---@param rsp wrpc.JoinTeamTrusteeshipTargetInfoReply
---@param req rpc.JoinTeamTrusteeshipTargetInfo
function HUDSelectTroopAssembleTimePreFetch:OnServerResponse(isSuccess, rsp, req)
    if isSuccess and rsp and req and req.userdata and type(req.userdata) == 'string' then
        self._cache[req.userdata] = rsp.Info
        g_Game.EventManager:TriggerEvent(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE, req.userdata, rsp.Info)
    end
end

return HUDSelectTroopAssembleTimePreFetch