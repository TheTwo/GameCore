local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local ActivityRewardType = require('ActivityRewardType')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
---@class GrowthFundModule : BaseModule
local GrowthFundModule = class('GrowthFundModule', BaseModule)

---@class GrowthFundData
---@field cfg ProgressFundConfigCell
---@field dataId number
---@field nodeInfos table<number, GrowthFundNodeInfo>

---@class GrowthFundNodeInfo
---@field normal number @ItemGroupId
---@field adv number @ItemGroupId
---@field neededProgress number

function GrowthFundModule:OnRegister()
    self.lookupTable = {}
    self:InitLookupTable()
end

function GrowthFundModule:OnRemove()
end

function GrowthFundModule:InitLookupTable()
    self.lookupTable = {}
    for _, cfg in ConfigRefer.ActivityRewardTable:ipairs() do
        if cfg:Type() == ActivityRewardType.ProgressFund then
            local growthFundCfgId = cfg:RefConfig()
            local growthFundCfg = ConfigRefer.ProgressFund:Find(growthFundCfgId)
            self.lookupTable[growthFundCfgId] = {}
            self.lookupTable[growthFundCfgId].cfg = growthFundCfg
            local player = ModuleRefer.PlayerModule:GetPlayer()
            for i, reward in pairs(player.PlayerWrapper2.PlayerAutoReward.Rewards) do
                if reward.ConfigId == cfg:Id() then
                    self.lookupTable[growthFundCfgId].dataId = i
                end
            end
            local spRewardIndices = {}
            local spRewardIconIndex = {}
            for i = 1, growthFundCfg:SpRewardIndexLength() do
                spRewardIndices[growthFundCfg:SpRewardIndex(i)] = true
                spRewardIconIndex[growthFundCfg:SpRewardIndex(i)] = i
            end
            self.lookupTable[growthFundCfgId].spRewardIndices = spRewardIndices
            self.lookupTable[growthFundCfgId].spRewardIconIndex = spRewardIconIndex
            self:SpeciesPrefixSum(growthFundCfgId)
        end
    end
end

function GrowthFundModule:SpeciesPrefixSum(cfgId)
    self.lookupTable[cfgId].speciesPrefixSum = {}
    self.lookupTable[cfgId].normalSpeciesPrefixSum = {}
    for i, nodeInfo in ipairs(self:GetRewardInfosByCfgId(cfgId)) do
        local advRewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(nodeInfo.adv)
        local normalRewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(nodeInfo.normal)
        local sum = 0
        local normalSum = 0
        for _, item in ipairs(advRewardItems or {}) do
            if item.configCell:Id() == GrowthFundConst.SPECIE_ID then
                sum = sum + item.count
            end
        end
        for _, item in ipairs(normalRewardItems or {}) do
            if item.configCell:Id() == GrowthFundConst.SPECIE_ID then
                normalSum = normalSum + item.count
            end
        end
        if i == 1 then
            self.lookupTable[cfgId].speciesPrefixSum[i] = sum
            self.lookupTable[cfgId].normalSpeciesPrefixSum[i] = normalSum
        else
            self.lookupTable[cfgId].speciesPrefixSum[i] = self.lookupTable[cfgId].speciesPrefixSum[i - 1] + sum
            self.lookupTable[cfgId].normalSpeciesPrefixSum[i] = self.lookupTable[cfgId].normalSpeciesPrefixSum[i - 1] + normalSum
        end
    end
end

---@private
function GrowthFundModule:GetData(cfgId, key)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local dataId = self.lookupTable[cfgId].dataId
    if not dataId then return nil end
    return ((player.PlayerWrapper2.PlayerAutoReward.Rewards[dataId] or {}).ProgressFundParam or {})[key]
end

--- Interfaces ---

---@param cfgId number
---@return number
function GrowthFundModule:GetProgressByCfgId(cfgId)
    return self:GetData(cfgId, 'Progress') or 0
end

---@param cfgId number
---@return table<number, number>
function GrowthFundModule:GetReceivedNormalLevelByCfgId(cfgId)
    return self:GetData(cfgId, 'ReceivedNormalIndex') or {}
end

---@param cfgId number
---@return table<number, number>
function GrowthFundModule:GetReceivedAdvLevelByCfgId(cfgId)
    return self:GetData(cfgId, 'ReceivedVIPIndex') or {}
end

---@param cfgId number
---@return boolean
function GrowthFundModule:IsVIP(cfgId)
    return self:GetData(cfgId, 'VIP') or false
end

---@param cfgId number
---@return boolean
function GrowthFundModule:IsNormal(cfgId)
    return (self:GetData(cfgId, 'Normal') or false) or self:GetNormalGoodsByCfgId(cfgId) == 0 -- 2024.01 免费奖励回归。Normal商品没填时视为免费奖励
end

function GrowthFundModule:GetVIPGoodsByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:VIPGood()
end

function GrowthFundModule:GetRebatePercentageByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:RebatePercentage()
end

function GrowthFundModule:GetNormalGoodsByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:NormalGood()
end

---@param cfgId number
---@return table<number, GrowthFundNodeInfo>
function GrowthFundModule:GetRewardInfosByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return {} end
    local cfg = self.lookupTable[cfgId].cfg
    local nodeInfos = self.lookupTable[cfgId].nodeInfos
    if nodeInfos then
        return nodeInfos
    end
    nodeInfos = {}
    for i = 1, cfg:NodesLength() do
        local node = cfg:Nodes(i)
        local normalRewards = node:Normal() --node:Free() 2023.12 取消免费奖励
        local advRewards = node:VIP()
        local neededProgress = node:Value()
        if not normalRewards or not advRewards then
            break
        end
        nodeInfos[i] = {
            normal = normalRewards,
            adv = advRewards,
            neededProgress = neededProgress,
        }
    end
    self.lookupTable[cfgId].nodeInfos = nodeInfos
    return nodeInfos
end

function GrowthFundModule:GetSpRewardIconIndex(cfgId, level)
    if not self.lookupTable[cfgId] then return nil end
    local i = self.lookupTable[cfgId].spRewardIconIndex[level]
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:SpRewardIconIndex(i)
end

--- end of Interfaces ---

--- Warps ---

---@param cfgId number
---@param lvl number
---@return number, number
function GrowthFundModule:GetRewardStatus(cfgId, lvl)
    local normalRewardStatus = GrowthFundConst.REWARD_STATUS.LOCKED
    local advRewardStatus = GrowthFundConst.REWARD_STATUS.LOCKED
    local isVIP = self:IsVIP(cfgId)
    local isNormal = self:IsNormal(cfgId)
    local receivedNormalLevel = self:GetReceivedNormalLevelByCfgId(cfgId)
    local receivedAdvLevel = self:GetReceivedAdvLevelByCfgId(cfgId)
    if self:GetProgressByCfgId(cfgId) >= lvl then
        if isNormal then
            if table.ContainsKey(receivedNormalLevel, lvl - 1) then -- 后端下标从0开始，下同
                normalRewardStatus = GrowthFundConst.REWARD_STATUS.CLAIMED
            else
                normalRewardStatus = GrowthFundConst.REWARD_STATUS.CLAIMABLE
            end
        end
        if isVIP then
            if table.ContainsKey(receivedAdvLevel, lvl - 1) then
                advRewardStatus = GrowthFundConst.REWARD_STATUS.CLAIMED
            else
                advRewardStatus = GrowthFundConst.REWARD_STATUS.CLAIMABLE
            end
        end
    else
        return GrowthFundConst.REWARD_STATUS.UNCLAIMABLE, GrowthFundConst.REWARD_STATUS.UNCLAIMABLE
    end
    return normalRewardStatus, advRewardStatus
end

---@param cfgId number
---@param nodeIndex number
---@return boolean
function GrowthFundModule:IsSpecialReward(cfgId, nodeIndex)
    return ((self.lookupTable[cfgId] or {}).spRewardIndices or {})[nodeIndex] or false
end

---@param cfgId number
---@param lvl number
---@param isVip boolean
---@return number
function GrowthFundModule:GetTotalSpeciesByLevel(cfgId, lvl, isVip)
    local speciesPrefixSum
    if isVip then
        speciesPrefixSum = self.lookupTable[cfgId].speciesPrefixSum
    else
        speciesPrefixSum = self.lookupTable[cfgId].normalSpeciesPrefixSum
    end
    if not speciesPrefixSum then return 0 end
    if lvl > #speciesPrefixSum then
        return speciesPrefixSum[#speciesPrefixSum] or 0
    end
    return speciesPrefixSum[lvl] or 0
end

function GrowthFundModule:GetMaxLevelByCfgId(cfgId)
    return #self:GetRewardInfosByCfgId(cfgId)
end

---@param cfgId number
---@return boolean
function GrowthFundModule:IsAnyRewardCanClaim(cfgId)
    for i = 1, #self:GetRewardInfosByCfgId(cfgId) do
        local normalRewardStatus, advRewardStatus = self:GetRewardStatus(cfgId, i)
        if normalRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE
            or advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE then
            return true
        end
    end
    return false
end

---@param cfgId number
---@return number | nil
function GrowthFundModule:GetFirstClaimableNodeIndex(cfgId)
    for i = 1, #self:GetRewardInfosByCfgId(cfgId) do
        local normalRewardStatus, advRewardStatus = self:GetRewardStatus(cfgId, i)
        if normalRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE
            or advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE then
            return i
        end
    end
    return nil
end

function GrowthFundModule:GetCurOpeningGrowthFundCfgId()
    local actId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.ProgressFund)
    if actId == 0 then return 0 end
    return ConfigRefer.ActivityRewardTable:Find(actId):RefConfig()
end

--- end of Warps ---

return GrowthFundModule