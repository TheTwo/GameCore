local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local Delegate = require("Delegate")
local UIMediatorNames = require('UIMediatorNames')

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionChoice:StoryStepActionBase
---@field new fun():StoryStepActionChoice
---@field super StoryStepActionBase
local StoryStepActionChoice = class('StoryStepActionChoice', StoryStepActionBase)

function StoryStepActionChoice:ctor()
    StoryStepActionBase.ctor(self)
    self._choice = 0
    self._runtimeId = nil
end

function StoryStepActionChoice:LoadConfig(actionParam)
    self._choiceConfigId = tonumber(actionParam)
end

function StoryStepActionChoice:Init(stepInfo)
    if stepInfo and stepInfo.Choice and stepInfo.Choice > 0 then
        self._choice = stepInfo.Choice
    end
end

function StoryStepActionChoice:OnEnter()
    local param = StoryDialogUIMediatorParameter.new()
    param:SetChoiceGroup(self._choiceConfigId, Delegate.GetOrCreate(self, self.OnChoice))
    self._runtimeId = g_Game.UIManager:Open(UIMediatorNames.StoryDialogUIMediator, param)
    self.NeedDelayCleanUp = true
end

function StoryStepActionChoice:OnLeave()
    if self.NeedDelayCleanUp then
        if self._runtimeId then
            local mediator = g_Game.UIManager:FindUIMediator(self._runtimeId)
            if mediator then
                mediator.__canDelayCleanUp = true
                mediator:Hide()
            end
        end
    else
        g_Game.UIManager:Close(self._runtimeId)
        self._runtimeId = nil
    end
end

function StoryStepActionChoice:OnDelayCleanUp()
    if self._runtimeId then
        local mediator = g_Game.UIManager:FindUIMediator(self._runtimeId)
        if mediator then
            if mediator and mediator.__canDelayCleanUp then
                g_Game.UIManager:Close(self._runtimeId)
            end
        end
    end
    self._runtimeId = nil
end

function StoryStepActionChoice:OnSetEndStatus(isRestore)
    self.Owner:SetChoice(self._choice)
end

---@param index number
function StoryStepActionChoice:OnChoice(index)
    self._choice = index
    self:EndAction()
    return true
end

function StoryStepActionChoice:GetChoiceConfigId()
    return self._choiceConfigId
end

function StoryStepActionChoice:GetChoice()
    return self._choice or 1
end

return StoryStepActionChoice