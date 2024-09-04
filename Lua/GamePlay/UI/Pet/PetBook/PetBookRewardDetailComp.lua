local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

local PetBookRewardDetailComp = class('PetBookRewardDetailComp', BaseTableViewProCell)

function PetBookRewardDetailComp:OnCreate()
    self.p_text_level = self:Text('p_text_level')
    self.p_table_rewards = self:TableViewPro('p_table_rewards')
end

function PetBookRewardDetailComp:OnShow()
end

function PetBookRewardDetailComp:OnHide()
end

function PetBookRewardDetailComp:OnFeedData(param)
    self.param = param
    self.p_text_level.text = I18N.GetWithParams("petguide_research_claimreward_preview", param.index)

    local itemGroup = param.itemGroup
    self.p_table_rewards:Clear()
    for j = 1, itemGroup:ItemGroupInfoListLength() do
        local itemGroupInfo = itemGroup:ItemGroupInfoList(j)
        ---@type ItemIconData
        local iconData = {configCell = ConfigRefer.Item:Find(itemGroupInfo:Items()), setTipsPos = true, received = param.received, showCount = true, count = itemGroupInfo:Nums()}
        self.p_table_rewards:AppendData(iconData)
    end

end

return PetBookRewardDetailComp
