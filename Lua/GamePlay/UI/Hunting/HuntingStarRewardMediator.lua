---scene: scene_climbtower_popup_reward
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
---@class HuntingStarRewardMediator : BaseUIMediator
local HuntingStarRewardMediator = class('HuntingStarRewardMediator', BaseUIMediator)

function HuntingStarRewardMediator:ctor()
    self.focusIndex = 0
end

function HuntingStarRewardMediator:OnCreate()
    self.tableReward = self:TableViewPro('p_table_reward')
end

function HuntingStarRewardMediator:OnOpened(params)
    self:UpdateTable()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerHunting.MsgPath, Delegate.GetOrCreate(self, self.UpdateTable))
end

function HuntingStarRewardMediator:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerHunting.MsgPath, Delegate.GetOrCreate(self, self.UpdateTable))
end

function HuntingStarRewardMediator:UpdateTable()
    self.tableReward:Clear()
    local isFirstNotAvailable = true
    local firstAvailableRewardIndex = 0
    local firstNotAvailableRewardIndex = 0
    for i, starRewardCfg in ConfigRefer.HuntingStarReward:ipairs() do
        local curStars = ModuleRefer.HuntingModule:GetCurStarNum()
        local starNum = starRewardCfg:StarNum()
        local rewardList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(starRewardCfg:Reward())
        local data = {
            starRewardId = starRewardCfg:Id(),
            starNum = starNum,
            rewardList = rewardList,
        }
        if curStars < starNum and isFirstNotAvailable then
            data.isFirstNotAvailable = true
            isFirstNotAvailable = false
            firstNotAvailableRewardIndex = i
        end
        if curStars >= starNum and not ModuleRefer.HuntingModule:IsStarRewardClaimed(starRewardCfg:Id()) and firstAvailableRewardIndex <= 0 then
            firstAvailableRewardIndex = i
        end
        self.tableReward:AppendData(data)
    end
    self.focusIndex = firstAvailableRewardIndex > 0 and firstAvailableRewardIndex or firstNotAvailableRewardIndex
    self.tableReward:SetDataFocus(math.max(self.focusIndex - 1, 0), 0, CS.TableViewPro.MoveSpeed.Fast)
end

return HuntingStarRewardMediator