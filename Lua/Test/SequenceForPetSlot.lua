---@class SequenceForPetSlot
---@field new fun():SequenceForPetSlot
local SequenceForPetSlot = class("SequenceForPetSlot")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local BattleStep = require("BattleStep")
local CheckStep = require("CheckStep")
local MoveStep = require("MoveStep")
local NpcActStep = require("NpcActStep")
local RestartStep = require("RestartStep")
local UIActStep = require("UIActStep")
local UnlockZoneStep = require("UnlockZoneStep")
local WaitStateNormalStep = require("WaitStateNormalStep")
local EmptyStep = require("EmptyStep")
local ProtocolId = require("ProtocolId")


function SequenceForPetSlot:ctor()
    
end

function SequenceForPetSlot:Start()
    ---@type EmptyStep[]
    self.sequence = {
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexLuaComp, {"_loadedComponents", "child_stroy_dialog_btn_top"}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.SimCall, {"OnClickSkipBtn"}):SetSequence(self),

        MoveStep.new(13.72, 210.49):SetSequence(self),

        NpcActStep.new(3023, NpcActStep.ActionEnum.CheckExist):SetSequence(self),
        NpcActStep.new(3023, NpcActStep.ActionEnum.Interact):SetSequence(self),

        UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexLuaComp, {"_loadedComponents", "child_story_dialog_npc_left_1"}):SetSequence(self),
        UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexComp, {typeof(CS.TableViewPro), "_t_table_task_l"}):SetSequence(self),
        UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexTableViewCell, {1}):SetSequence(self),
        UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.SimCall, {"OnClickSelfBtn"}):SetSequence(self),

        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexLuaComp, {"_loadedComponents", "child_stroy_dialog_btn_top"}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.SimCall, {"OnClickSkipBtn"}):SetSequence(self),

        UIActStep.new("UIOneDaySuccessMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        UIActStep.new("UIOneDaySuccessMediator", UIActStep.ActionEnum.CloseUI):SetSequence(self),

        BattleStep.new({{x = 24.65, z = 213.65}}):SetSequence(self),
        EmptyStep.new():SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 40, z = 216.72}}):SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 52, z = 214.14}}):SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 68, z = 206.23}}):SetSequence(self),

        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexLuaComp, {"_loadedComponents", "child_stroy_dialog_btn_top"}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.SimCall, {"OnClickSkipBtn"}):SetSequence(self),

        MoveStep.new(70.65, 203.88):SetSequence(self),
        NpcActStep.new(3029, NpcActStep.ActionEnum.CheckExist):SetSequence(self),
        NpcActStep.new(3029, NpcActStep.ActionEnum.Interact, ProtocolId.CastleGetTreasure):SetSequence(self),

        UIActStep.new("SEPetSettlementMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        UIActStep.new("SEPetSettlementMediator", UIActStep.ActionEnum.CloseUI):SetSequence(self),

        UnlockZoneStep.new(2):SetSequence(self),

        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.IndexLuaComp, {"_loadedComponents", "child_stroy_dialog_btn_top"}):SetSequence(self),
        -- UIActStep.new("StoryDialogUIMediator", UIActStep.ActionEnum.SimCall, {"OnClickSkipBtn"}):SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 106.53, z = 200.54}}):SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 96.6, z = 201.27}, {x = 84.75, z = 202.72}}):SetSequence(self),

        EmptyStep.new():SetSequence(self),
        BattleStep.new({{x = 109.49, z = 214.82}}):SetSequence(self),

        MoveStep.new(107.21, 212.62):SetSequence(self),
        NpcActStep.new(2000, NpcActStep.ActionEnum.CheckExist):SetSequence(self),
        NpcActStep.new(2000, NpcActStep.ActionEnum.Interact, ProtocolId.CastleGetTreasure):SetSequence(self),

        WaitStateNormalStep.new():SetSequence(self),

        UIActStep.new("GuideFingerSlideMediator", UIActStep.ActionEnum.CheckOrWaitUI, {10}):SetSequence(self),
        UIActStep.new("GuideFingerSlideMediator", UIActStep.ActionEnum.CloseUI):SetSequence(self),

        NpcActStep.new(3006, NpcActStep.ActionEnum.CheckExist):SetSequence(self),
        NpcActStep.new(3006, NpcActStep.ActionEnum.Interact, ProtocolId.RequestNpcService):SetSequence(self),

        CheckStep.new(1000201):SetSequence(self),
        RestartStep.new():SetSequence(self),
    }

    self.currentStepIndex = 1
    self:ExecuteStep()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    g_Game.EventManager:AddListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))
    g_Game.EventManager:AddListener(EventConst.UI_MEDIATOR_OPENED, Delegate.GetOrCreate(self, self.OnUIMediatorOpened))

    g_Logger.Error("SequenceForPetSlot Start")
end

function SequenceForPetSlot:ExecuteStep()
    self.currentStep = self.sequence[self.currentStepIndex]
    if self.currentStep then
        if self.currentStep:IsFirstExecuted() then
            self.currentStep:Start()
        end
        local flag, stepReturn = self.currentStep:TryExecuted(self.lastReturn)
        if flag then
            self:MoveNext(stepReturn)
        end
    else
        self:End()
    end
end

function SequenceForPetSlot:MoveNext(stepReturn)
    self.lastReturn = stepReturn
    self.currentStepIndex = self.currentStepIndex + 1
    self.currentStep:End()
end

function SequenceForPetSlot:End()
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))
    g_Game.EventManager:RemoveListener(EventConst.UI_MEDIATOR_OPENED, Delegate.GetOrCreate(self, self.OnUIMediatorOpened))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    self.sequence = nil
    self.currentStepIndex = nil
    g_Logger.Error("SequenceForPetSlot End")
end

function SequenceForPetSlot:OnSecondTicker()
    if self.sequence and self.currentStepIndex then
        self:ExecuteStep()
    end
end

function SequenceForPetSlot:OnCityStateChange(city, oldState, newState)
    if newState:GetName() == "CityStateSeBattle" then
        ---@type SEEnvironment
        local seEnv = city.citySeManger._seEnvironment
        seEnv:SendAutoCastPetCardRequest(true)
    end
end

function SequenceForPetSlot:OnUIMediatorOpened(mediatorName)
    if mediatorName == "SystemRestartUIMediator" then
        local RuntimeDebugSettings = require("RuntimeDebugSettings")
        RuntimeDebugSettings:ClearOverrideAccountConfig()
        g_Game.UIManager:CloseByName("SystemRestartUIMediator")
    end
end

return SequenceForPetSlot