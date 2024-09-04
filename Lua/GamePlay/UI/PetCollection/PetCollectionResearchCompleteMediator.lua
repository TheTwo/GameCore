local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local GuideUtils = require('GuideUtils')
local ClientDataKeys = require('ClientDataKeys')
local Vector3 = CS.UnityEngine.Vector3
local UIMediatorNames = require("UIMediatorNames")
local PetCollectionEnum = require("PetCollectionEnum")
local TimeFormatter = require("TimeFormatter")
local Color = CS.UnityEngine.Color
local TimerUtility = require('TimerUtility')
local UIHelper = require('UIHelper')
local AudioConsts = require('AudioConsts')

local PetCollectionResearchCompleteMediator = class('PetCollectionResearchCompleteMediator', BaseUIMediator)
function PetCollectionResearchCompleteMediator:ctor()
end

function PetCollectionResearchCompleteMediator:OnCreate()
    self.p_icon_pet = self:Image('p_icon_pet')
    self.p_text_desc = self:Text('p_text_desc')
    self.p_progress = self:Slider('p_progress')
    self.p_text_goal = self:Text('p_text_goal')

    -- self.p_text_goal_1 = self:Text('p_text_goal_1')
    -- self.p_text_goal_2 = self:Text('p_text_goal_2')
    -- self.p_text_goal_3 = self:Text('p_text_goal_3')
    -- self.p_text_goal_4 = self:Text('p_text_goal_4')
    -- self.p_text_goal_5 = self:Text('p_text_goal_5')

    -- self.p_icon_check_1 = self:GameObject('p_icon_check_1')
    -- self.p_icon_check_2 = self:GameObject('p_icon_check_2')
    -- self.p_icon_check_3 = self:GameObject('p_icon_check_3')
    -- self.p_icon_check_4 = self:GameObject('p_icon_check_4')
    -- self.p_icon_check_5 = self:GameObject('p_icon_check_5')

    -- self.p_goal_1 = self:GameObject('p_goal_1')
    -- self.p_goal_2 = self:GameObject('p_goal_2')
    -- self.p_goal_3 = self:GameObject('p_goal_3')
    -- self.p_goal_4 = self:GameObject('p_goal_4')
    -- self.p_goal_5 = self:GameObject('p_goal_5')

    self.vx_trigger = self:BindComponent("vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    -- self.iconChecks = {self.p_icon_check_1, self.p_icon_check_2, self.p_icon_check_3, self.p_icon_check_4, self.p_icon_check_5}
    -- self.goals = {self.p_goal_1, self.p_goal_2, self.p_goal_3, self.p_goal_4, self.p_goal_5}

    self:PointerClick("base", Delegate.GetOrCreate(self, self.OnClick))

    self.p_text_reach = self:Text('p_text_reach', "petguide_toast_research_complete")
    self.p_text_progress = self:Text('p_text_progress')

end

function PetCollectionResearchCompleteMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_DETAIL_TAB, Delegate.GetOrCreate(self, self.SwitchTab))
    self:Refresh(param)
    if not self.closeTimer then
        self.closeTimer = TimerUtility.DelayExecute(function()
            self:CloseSelf()
        end, 2)
    end
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    -- local vxIndex = self.vxIndex
    -- if vxIndex == self.nodeMax - 1 then
    --     -- 满星特效 4s延迟
    --     self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)

    --     TimerUtility.StopAndRecycle(self.closeTimer)
    --     self.closeTimer = TimerUtility.DelayExecute(function()
    --         self:CloseSelf()
    --     end, 4)

    --     self.completeAllVXTimer = TimerUtility.DelayExecute(function()
    --         self.p_text_desc.text = I18N.Get("tech_info_achieve")
    --     end, 2.7)
    -- else
    --     if vxIndex == 0 then
    --         self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    --     elseif vxIndex == 1 then
    --         self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    --     elseif vxIndex == 2 then
    --         self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
    --     elseif vxIndex == 3 then
    --         self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
    --     end
    -- end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_study_complete)
end

function PetCollectionResearchCompleteMediator:OnHide(param)
    if self.closeTimer then
        TimerUtility.StopAndRecycle(self.closeTimer)
        self.closeTimer = nil
    end

    if self.completeAllVXTimer then
        TimerUtility.StopAndRecycle(self.completeAllVXTimer)
        self.completeAllVXTimer = nil
    end
end

function PetCollectionResearchCompleteMediator:OnClick()
    self:CloseSelf()
end

function PetCollectionResearchCompleteMediator:Refresh(param)
    if not param then
        return
    end

    local petType = ConfigRefer.PetType:Find(param.PetTypeCfgId)
    local cfg = ModuleRefer.PetCollectionModule:GetResearchConfig(param.PetTypeCfgId)
    self.p_text_desc.text = I18N.Get("petguide_research") .. param.PetResearchLevel

    if param.PetResearchPoint >= param.PetResearchPointTotal then
        self.p_text_progress:SetVisible(false)
        self.p_text_reach:SetVisible(true)
    else
        self.p_text_progress:SetVisible(true)
        self.p_text_reach:SetVisible(false)
        self.p_text_progress.text = param.PetResearchPoint .. "/" .. param.PetResearchPointTotal
    end
    self.p_progress.value = param.PetResearchPoint / param.PetResearchPointTotal
    local iconId = ConfigRefer.Pet:Find(petType:SamplePetCfg()):TinyIcon()
    local icon = ConfigRefer.ArtResourceUI:Find(iconId):Path()
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_pet)
    -- local num = topic:ItemsLength()
    -- self.nodeMax = num
    -- for i = 1, 5 do
    --     self.goals[i]:SetVisible(i <= num)
    -- end

end

return PetCollectionResearchCompleteMediator
