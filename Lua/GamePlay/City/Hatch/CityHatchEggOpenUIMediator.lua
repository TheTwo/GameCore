---Scene Name : scene_city_popup_egg_open
local BaseUIMediator = require ('BaseUIMediator')
---@class CityHatchEggOpenUIMediator:BaseUIMediator
local CityHatchEggOpenUIMediator = class('CityHatchEggOpenUIMediator', BaseUIMediator)
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local ConfigRefer = require("ConfigRefer")
local PetQuality = require("PetQuality")

function CityHatchEggOpenUIMediator:OnCreate()
    self._p_img_egg = self:Image("p_img_egg")
    self._p_trigger = self:AnimTrigger("p_trigger")
end

---@param param CityHatchEggOpenUIParameter
function CityHatchEggOpenUIMediator:OnOpened(param)
    self.param = param
    g_Game.SpriteManager:LoadSprite(self.param:GetEggIcon(), self._p_img_egg)

    local quality = PetQuality.LV2
    for _, rewardPet in pairs(self.param.resultParam.result.RewardPets) do
        local petCfg = ConfigRefer.Pet:Find(rewardPet.PetId)
        if petCfg and petCfg:Quality() > quality then
            quality = petCfg:Quality()
        end
    end

    local triggerEnum = CS.FpAnimation.CommonTriggerType.Custom3
    if quality == PetQuality.LV3 then
        triggerEnum = CS.FpAnimation.CommonTriggerType.Custom2
    elseif quality == PetQuality.LV4 then
        triggerEnum = CS.FpAnimation.CommonTriggerType.Custom1
    end
    self._p_trigger:PlayAll(triggerEnum)
    g_Game.SoundManager:Play("sfx_petegg_hatch")
    self:IntervalRepeat(Delegate.GetOrCreate(self, self.OnVfxFinished), 1.8, 0)
end

function CityHatchEggOpenUIMediator:OnVfxFinished()
    --- 希望每次单开的时候都播Roll星的拍脸
    if self.param:IsOnlyOneAndNotNew() then
        self:ShowPopupUI()
    elseif not self.param:IsOnlyOneAndNew() then
        self:ShowResultUI()
    end
    self.resultShowed = true
    self:CloseSelf()
end

function CityHatchEggOpenUIMediator:ShowPopupUI()
    ---@type SEPetSettlementParam
    local param = {}
    param.petCompId = self.param.resultParam.result.RewardPets[1].PetCompId
    param.showAsGetPet = true
    local provider = UIAsyncDataProvider.new()
    local name = UIMediatorNames.SEPetSettlementMediator
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator | UIAsyncDataProvider.CheckTypes.DoNotShowInCityZoneRecoverState
    local checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    provider:Init(name, nil, check, checkFailedStrategy, false, param)
    provider:SetOtherMediatorCheckType(0)
    provider:AddOtherMediatorBlackList(UIMediatorNames.SEPetSettlementMediator)
    provider:AddOtherMediatorBlackList(UIMediatorNames.CityHatchEggOpenUIMediator)
    provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogUIMediator)
    provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogChatUIMediator)
    provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogRecordUIMediator)
    provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogSkipPopupUIMediator)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

function CityHatchEggOpenUIMediator:ShowResultUI()
    local param = self.param.resultParam
    local provider = UIAsyncDataProvider.new()
    local name = UIMediatorNames.CatchPetResultMediator
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
    local checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    provider:Init(name, nil, check, checkFailedStrategy, false, param)
    provider:SetOtherMediatorCheckType(0)
    provider:AddOtherMediatorBlackList(UIMediatorNames.SEPetSettlementMediator)
    provider:SetPriority(-100)
    g_Game.UIAsyncManager:AddAsyncMediator(provider, false)
end

function CityHatchEggOpenUIMediator:OnClose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick2))

    if not self.resultShowed then
        if self.param:IsOnlyOneAndNotNew() then
            self:ShowPopupUI()
        elseif not self.param:IsOnlyOneAndNew() then
            self:ShowResultUI()
        end
    end
end

return CityHatchEggOpenUIMediator