local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ActivityRewardType = require("ActivityRewardType")
local PlayerGetAutoRewardParameter = require("PlayerGetAutoRewardParameter")
local EventConst = require("EventConst")
---@class ActivityLandformModule : BaseModule
local ActivityLandformModule = class("ActivityLandformModule", BaseModule)

function ActivityLandformModule:ctor()
    ---@type table<number, wds.LandExploreParam>
    self.serverDatas = {} -- readonly
end

function ActivityLandformModule:OnRegister()
    for _, cfg in ConfigRefer.ActivityRewardTable:ipairs() do
        if cfg:Type() == ActivityRewardType.LandExplore then
            local player = ModuleRefer.PlayerModule:GetPlayer()
            for id, reward in pairs(player.PlayerWrapper2.PlayerAutoReward.Rewards) do
                if reward.ConfigId == cfg:Id() then
                    self.serverDatas[cfg:Id()] = {}
                    self.serverDatas[cfg:Id()].dataId = id
                end
            end
        end
    end
end

---@private
---@param cfgId number
---@param key string
---@return any
function ActivityLandformModule:GetData(cfgId, key)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local dataId = self.serverDatas[cfgId].dataId
    return (player.PlayerWrapper2.PlayerAutoReward.Rewards[dataId].LandExploreParam or {})[key]
end

---@param cfgId number
---@return number
function ActivityLandformModule:GetCurScore(cfgId)
    local ret = 0
    local curScores = self:GetData(cfgId, "CurScore")
    for _, score in pairs(curScores) do
        ret = ret + score
    end
    return ret
end

---@param cfgId number
---@return table<number, number>
function ActivityLandformModule:GetCurScoreSplitBySourceId(cfgId)
    return self:GetData(cfgId, "CurScore")
end

---@param cfgId number
---@param index number
---@return number
function ActivityLandformModule:GetRewardScore(cfgId, index)
    local cfg = ConfigRefer.LandExplore:Find(cfgId)
    if not cfg then return 0 end
    return cfg:RewardScoreList(index)
end

---@param cfgId number
---@param index number
---@return number
function ActivityLandformModule:GetRewardItemGroupId(cfgId, index)
    local cfg = ConfigRefer.LandExplore:Find(cfgId)
    if not cfg then return 0 end
    return cfg:RewardItemGroupList(index)
end

---@param cfgId number
---@return LandConfigCell
function ActivityLandformModule:GetLandformCfg(cfgId)
    local cfg = ConfigRefer.LandExplore:Find(cfgId)
    if not cfg then return nil end
    return ConfigRefer.Land:Find(cfg:LandType())
end

---@param cfgId number
---@param index number
---@return boolean
function ActivityLandformModule:IsRewardReceived(cfgId, index)
    local receiveRewardIndex = self:GetData(cfgId, "ReceiveRewardIndex")
    return table.ContainsKey(receiveRewardIndex, index - 1)
end

---@param cfgId number
---@param index number
---@return boolean
function ActivityLandformModule:IsRewardCanReceive(cfgId, index)
    local curScore = self:GetCurScore(cfgId)
    local rewardScore = self:GetRewardScore(cfgId, index)
    return curScore >= rewardScore and not self:IsRewardReceived(cfgId, index)
end

---@param cfgId number
---@return boolean
function ActivityLandformModule:IsAnyRewardCanReceive(cfgId)
    local cfg = ConfigRefer.LandExplore:Find(cfgId)
    if not cfg then return false end
    for i = 1, cfg:RewardItemGroupListLength() do
        if self:IsRewardCanReceive(cfgId, i) then
            return true
        end
    end
    return false
end

function ActivityLandformModule:ReceiveReward(activityRewardId, index, transform, callback)
    local op = wrpc.PlayerGetAutoReward()
    op.ConfigId = activityRewardId
    op.Arg1 = index - 1
    local msg = PlayerGetAutoRewardParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(transform, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
            g_Game.EventManager:TriggerEvent(EventConst.LAND_EXPLORE_REWARD_CLAIM)
        end
    end)
end

return ActivityLandformModule