local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local GuideUtils = require('GuideUtils')
local ClientDataKeys = require('ClientDataKeys')
local UIMediatorNames = require("UIMediatorNames")
local PetCollectionEnum = require("PetCollectionEnum")
local TimeFormatter = require("TimeFormatter")
local AudioConsts = require('AudioConsts')

local Vector3 = CS.UnityEngine.Vector3
local Color = CS.UnityEngine.Color

local PetCollectionResearchCompleteFullMediator = class('PetCollectionResearchCompleteFullMediator', BaseUIMediator)
function PetCollectionResearchCompleteFullMediator:ctor()
end

function PetCollectionResearchCompleteFullMediator:OnCreate()
    self.p_text_subtitle = self:Text('p_text_subtitle', I18N.Get("mail_congrat_reward"))
    self.p_text_desc = self:Text('p_text_desc')
    self:PointerClick("base", Delegate.GetOrCreate(self, self.OnClick))
end

function PetCollectionResearchCompleteFullMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_DETAIL_TAB, Delegate.GetOrCreate(self, self.SwitchTab))
    self:Refresh(param)
    if not self.closeTimer then
        self.closeTimer = TimerUtility.DelayExecute(function()
            self:CloseSelf()
        end, 3)
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_study_complete)
end

function PetCollectionResearchCompleteFullMediator:OnHide(param)
    if self.closeTimer then
        TimerUtility.StopAndRecycle(self.closeTimer)
        self.closeTimer = nil
    end
end

function PetCollectionResearchCompleteFullMediator:OnClick()
    self:CloseSelf()
end

function PetCollectionResearchCompleteFullMediator:OnOpened(param)
end

function PetCollectionResearchCompleteFullMediator:OnClose(param)
end

function PetCollectionResearchCompleteFullMediator:Refresh(param)
    if not param then
        return
    end

    local petType = ConfigRefer.PetType:Find(param.PetTypeCfgId)
    self.p_text_desc.text = I18N.Get(ConfigRefer.Pet:Find(petType:SamplePetCfg()):Name()) .. I18N.Get("pet_research_finish_des")
end

return PetCollectionResearchCompleteFullMediator
