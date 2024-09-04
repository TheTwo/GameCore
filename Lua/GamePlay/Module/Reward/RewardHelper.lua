local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
---@class RewardHelper
local RewardHelper = {}

---@param rankRewardCfgId number @RankReward Config Id
---@param rank number | nil
---@return table<number, ItemIconData[]> | ItemIconData[]
function RewardHelper.GetRankRewardInItemIconDatas(rankRewardCfgId, rank)
    local rewards = {}
    local cfg = ConfigRefer.RankReward:Find(rankRewardCfgId)
    if not cfg then return rewards end
    local rankKeys = {}
    for i = 1, cfg:TopRewardLength() do
        local thisRank = cfg:TopReward(i):Top()
        rewards[thisRank] = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:TopReward(i):Reward())
        table.insert(rankKeys, thisRank)
    end
    table.sort(rankKeys)
    if rank then
        for _, key in ipairs(rankKeys) do
            if rank <= key then
                return rewards[key]
            end
        end
    else
        return rewards
    end
end

---@param mailCfgId number
---@return ItemIconData[]
function RewardHelper.GetMailRewardInItemIconDatas(mailCfgId)
    local mail = ConfigRefer.Mail:Find(mailCfgId)
    if not mail then return {} end
    local rewardGroupId = mail:Attachment()
    return ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardGroupId)
end

return RewardHelper