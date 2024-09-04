local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

local PetStoryMediator = class('PetStoryMediator', BaseUIMediator)
function PetStoryMediator:ctor()
    self._rewardList = {}
end

function PetStoryMediator:OnCreate()
    self.p_text_title = self:Text('p_text_title')
    self.p_table_info = self:TableViewPro('p_table_info')
    self.child_popup_base_l = self:LuaObject('child_popup_base_l')
end

function PetStoryMediator:OnOpened(param)
    local cfg = ModuleRefer.PetModule:GetTypeCfg(param.cfgId)
    ---@type CommonBackButtonData
    local backData = {}
    backData.title = I18N.Get("petguide_report_subtitle")
    self.child_popup_base_l:FeedData(backData)

    local petCfg = ModuleRefer.PetModule:GetPetCfg(cfg:SamplePetCfg())
    local name = I18N.Get(petCfg:Name())
    self.p_text_title.text = I18N.GetWithParams("petguide_title_report", name)

    local researchData = ModuleRefer.PetCollectionModule:GetResearchData(param.cfgId)
    local curResearchLevel = researchData and researchData.Level or 0
    local story = researchData and researchData.StoryUnlock or {}
    local storyCfg = ConfigRefer.PetStory:Find(cfg:PetStoryId())
    -- local unlock = story[i]

    if storyCfg then
        for i = 2, storyCfg:UnlockInfoLength() do
            local info = storyCfg:UnlockInfo(i)
            local storyId = info:PetStoryItemId(i)
            local level = info:NeedLevel(i)
            ---@type PetStoryComp
            self.p_table_info:AppendData({index = i, unlock = curResearchLevel >= i, storyId = storyId, level = level, reward = info:Reward(i), curResearchLevel = curResearchLevel})
        end
    end
end

function PetStoryMediator:OnClose()
end
function PetStoryMediator:OnShow(param)

end

function PetStoryMediator:OnHide(param)
end

return PetStoryMediator
