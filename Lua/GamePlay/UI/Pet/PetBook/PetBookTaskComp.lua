local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local PetResearchTopicType = require('PetResearchTopicType')
local ConfigRefer = require('ConfigRefer')
local PetBookTaskComp = class('PetBookTaskComp', BaseTableViewProCell)
local UIMediatorNames = require('UIMediatorNames')
function PetBookTaskComp:OnCreate()
    self.p_text_task = self:Text('p_text_task')
    self.p_text_task_content = self:Text('p_text_task_content')
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.child_comp_btn_detail = self:GameObject('child_comp_btn_detail')
    self.p_task_icon = self:GameObject('p_task_icon')
    self.p_icon_lock = self:GameObject('p_icon_lock')
    ---@type BaseSkillIcon
    self.p_item_skill = self:LuaObject('p_item_skill')
    self.p_img = self:Image("p_img")
end

function PetBookTaskComp:OnShow()
end

function PetBookTaskComp:OnHide()
end

function PetBookTaskComp:OnFeedData(param)
    if not param then
        return
    end
    if not param.unlock then
        self.p_item_skill:SetVisible(false)
        self.p_task_icon:SetVisible(false)
        self.p_btn_goto:SetVisible(false)
        self.child_comp_btn_detail:SetVisible(false)

        self.p_icon_lock:SetVisible(true)
        self.p_text_task.text = I18N.GetWithParams("petguide_report_unlock_tip", param.unlockLevel)
        self.p_text_task_content:SetVisible(false)
        return
    end

    self.petCfgId = param.petCfgId
    self.onClick = param.onClick
    self.p_icon_lock:SetVisible(false)
    self.p_text_task_content:SetVisible(true)

    local curAddPoint = param:Items(1):AddPoint()
    local researchValue = param.ResearchValue
    for i = 1, param:ItemsLength() do
        local isComplete = param.ResearchProcess and param.ResearchProcess.TopicProcess[i - 1] or false
        if isComplete then
            curAddPoint = param:Items(i):AddPoint()
        end
    end

    local petCfg = ConfigRefer.Pet:Find(ConfigRefer.PetType:Find(param.petCfgId):SamplePetCfg())
    self.researchType = param:Typo()
    -- 捕捉次数
    if self.researchType == PetResearchTopicType.GetNum then
        self.p_item_skill:SetVisible(false)
        self.p_task_icon:SetVisible(true)
        self.p_btn_goto:SetVisible(true)
        self.child_comp_btn_detail:SetVisible(false)
        g_Game.SpriteManager:LoadSprite("sp_icon_item_pet_cap_lv1", self.p_img)
        -- 最高初始星级
    elseif self.researchType == PetResearchTopicType.MaxInitSkillStar then
        -- 固定技能
        local skillId = petCfg:SLGSkillID(2)
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
        self.p_item_skill:FeedData({
            skillId = slgSkillCell:SkillId(),
            index = slgSkillCell:SkillId(),
            skillLevel = researchValue,
            showLvl = true,
            isPetFix = true,
            quality = petCfg:Quality(),
            clickCallBack = Delegate.GetOrCreate(self, self.OnSlgSkillClick),
        })
        self.p_item_skill:SetVisible(true)
        self.p_task_icon:SetVisible(false)
        self.p_btn_goto:SetVisible(false)
        self.child_comp_btn_detail:SetVisible(true)
        -- 最高秘传技能星级
    elseif self.researchType == PetResearchTopicType.MaxSkillStar then
        local dropSkill = ConfigRefer.PetSkillBase:Find(petCfg:RefSkillTemplate()):DropSkill()
        self.skillId = dropSkill
        self.p_item_skill:FeedData({
            index = dropSkill,
            skillLevel = researchValue,
            showLvl = true,
            quality = petCfg:Quality(),
            isPet = true,
            clickCallBack = function()
                g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 6, cfgId = dropSkill})
            end,
        })
        self.p_item_skill:SetVisible(true)
        self.p_task_icon:SetVisible(false)
        self.p_btn_goto:SetVisible(true)
        self.child_comp_btn_detail:SetVisible(false)
    else
        -- 其他类型
        g_Logger.Error("研究类型不对，只支持三种")
        self.p_item_skill:SetVisible(false)
        self.p_task_icon:SetVisible(false)
        self.p_btn_goto:SetVisible(false)
        self.child_comp_btn_detail:SetVisible(false)
    end
    if param.studyIndex == 1 then
        local name = I18N.Get(petCfg:Name())
        self.p_text_task.text = I18N.GetWithParams(param.desc, name)
    else
        self.p_text_task.text = I18N.Get(param.desc)
    end
    self.p_text_task_content.text = I18N.GetWithParams("petguide_research_task_pt", curAddPoint)

end

function PetBookTaskComp:OnClickGoto()
    if self.researchType == PetResearchTopicType.GetNum then
        self.onClick()
        -- local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
        -- if isCityRadar then
        --     return
        -- end
        -- g_Game.UIManager:Open(UIMediatorNames.RadarMediator, {tracePetId = self.petCfgId})
    elseif self.researchType == PetResearchTopicType.MaxInitSkillStar then
        ---@type TextToastMediatorParameter
        local toastParameter = {}
        toastParameter.clickTransform = self.p_btn_detail.transform
        toastParameter.content = I18N.Get("petskill_info_desc")
        ModuleRefer.ToastModule:ShowTextToast(toastParameter)
    elseif self.researchType == PetResearchTopicType.MaxSkillStar then
        g_Game.UIManager:Open(UIMediatorNames.UIPetSkillLearnMediator, {skillId = self.skillId})
    end
end

function PetBookTaskComp:OnSlgSkillClick(param)
    g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 2, cfgId = param.index, level = 1})
end

return PetBookTaskComp
