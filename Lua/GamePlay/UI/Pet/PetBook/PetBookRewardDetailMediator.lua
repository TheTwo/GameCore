local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

local PetBookRewardDetailMediator = class('PetBookRewardDetailMediator', BaseUIMediator)
function PetBookRewardDetailMediator:ctor()
    self._rewardList = {}
end

function PetBookRewardDetailMediator:OnCreate()
    self.p_text_condition = self:Text('p_text_condition',"petguide_reward_preview_title")
    self.p_table_reward = self:TableViewPro('p_table_reward')
end

function PetBookRewardDetailMediator:OnOpened(param)
    local researchData = ModuleRefer.PetCollectionModule:GetResearchData(param.cfgId)
    local cfg = ConfigRefer.PetType:Find(param.cfgId)
    local petStoryId = cfg:PetStoryId()
    local petStory = ConfigRefer.PetStory:Find(petStoryId)
    local claimed = 1
    for k, v in pairs(researchData.StoryUnlock) do
        if v then
            claimed = claimed + 1
        end
    end

    self.p_table_reward:Clear()
    -- i = 1时为特殊奖励
    for i = 2, petStory:UnlockInfoLength() do
        local reward = petStory:UnlockInfo(i):Reward()
        local itemGroup = ConfigRefer.ItemGroup:Find(reward)
        self.p_table_reward:AppendData({itemGroup = itemGroup, index = i - 1, received = i < claimed})
    end    
end

function PetBookRewardDetailMediator:OnClose()
end
function PetBookRewardDetailMediator:OnShow(param)

end

function PetBookRewardDetailMediator:OnHide(param)
end

return PetBookRewardDetailMediator
