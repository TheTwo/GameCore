local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local UIMediatorNames = require('UIMediatorNames')

local PetBookStageRewardMediator = class('PetBookStageRewardMediator', BaseUIMediator)
function PetBookStageRewardMediator:ctor()
    self._rewardList = {}
end

function PetBookStageRewardMediator:OnCreate()
    self.p_text_stage = self:Text('p_text_stage')
    self.p_text_title = self:Text('p_text_title', "petguide_research_complete")
    self.p_text_title_skill = self:Text('p_text_title_skill', "petguide_subtitle_skill_unlock")
    self.p_text_skill = self:Text('p_text_skill', "petguide_skill_unlock_desc")
    self.p_text_title_clue = self:Text('p_text_title_clue', "petguide_report_subtitle")
    self.p_text_clue = self:Text('p_text_clue')
    self.p_text_continue = self:Text('p_text_continue', 'village_info_Click_to_close')
    ---@type BaseSkillIcon
    self.child_item_skill = self:LuaObject('child_item_skill')
    self.p_table_reward = self:TableViewPro('p_table_reward')
end

function PetBookStageRewardMediator:OnOpened(param)
    self.p_table_reward:Clear()
    for _, item in ipairs(param.itemInfo) do
        local itemCfg = ConfigRefer.Item:Find(item.id)
        if (itemCfg) then
            local itemData = {configCell = itemCfg, count = item.count, customData = item.id, onClick = Delegate.GetOrCreate(self, self.OnItemClick)}
            self.p_table_reward:AppendData(itemData)
        end
    end
    local cfg = ModuleRefer.PetModule:GetTypeCfg(param.petCfgId)
    local petCfg = ConfigRefer.Pet:Find(cfg:SamplePetCfg())

    -- if param.level == 2 then

    -- else

    -- end

    -- 技能
    local dropSkill = ConfigRefer.PetSkillBase:Find(petCfg:RefSkillTemplate()):DropSkill()
    local slgSkillId = ConfigRefer.PetLearnableSkill:Find(dropSkill):SlgSkill()
    self.child_item_skill:FeedData({
        index = dropSkill,
        skillLevel = 1,
        quality = petCfg:Quality(),
        isPet = true,
        clickCallBack = function()
            g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 6, cfgId = dropSkill})
        end,
    })

    local storyCfg = ConfigRefer.PetStory:Find(cfg:PetStoryId())
    local info = storyCfg:UnlockInfo(param.level)
    local storyId = info:PetStoryItemId()
    self.p_text_clue.text = I18N.Get(ConfigRefer.PetStoryItem:Find(storyId):Content())
    self.p_text_stage.text = I18N.GetWithParams("petguide_finish_subtitle", (param.level - 1))
end

function PetBookStageRewardMediator:OnClose()
end
function PetBookStageRewardMediator:OnShow(param)

end

function PetBookStageRewardMediator:OnHide(param)
end

function PetBookStageRewardMediator:OnItemClick(_, customData, itemBase)
    ---@type CommonItemDetailsParameter
    local param = {}
    param.clickTransform = itemBase.transform
    param.itemId = customData
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

return PetBookStageRewardMediator
