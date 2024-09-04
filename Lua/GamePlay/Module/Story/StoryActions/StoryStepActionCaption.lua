local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCaption:StoryStepActionBase
---@field new fun():StoryStepActionCaption
---@field super StoryStepActionBase
local StoryStepActionCaption = class('StoryStepActionCaption', StoryStepActionBase)

function StoryStepActionCaption:ctor()
    StoryStepActionBase.ctor(self)
    self._runtimeId = nil
end

function StoryStepActionCaption:LoadConfig(actionParam)
    self._captionConfigId = tonumber(actionParam)
end

function StoryStepActionCaption:OnEnter()
    local param = StoryDialogUIMediatorParameter.new()
    param:SetCaption(self._captionConfigId, Delegate.GetOrCreate(self, self.OnCaptionEnd))
    g_Game.EventManager:AddListener(EventConst.STORY_DIALOG_UI_CLOSED, Delegate.GetOrCreate(self, self.OnDialogUIClosed))
    self._runtimeId = g_Game.UIManager:Open(UIMediatorNames.StoryDialogUIMediator, param)
    self.NeedDelayCleanUp = true
end

function StoryStepActionCaption:OnLeave()
    g_Game.EventManager:RemoveListener(EventConst.STORY_DIALOG_UI_CLOSED, Delegate.GetOrCreate(self, self.OnDialogUIClosed))
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

function StoryStepActionCaption:OnDelayCleanUp()
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

function StoryStepActionCaption:OnCaptionEnd()
    self:EndAction()
end

function StoryStepActionCaption:OnDialogUIClosed()
    if self.IsDone or self.IsFailure then
        return
    end
    self:EndAction()
end

function StoryStepActionCaption:GetCaptionConfigId()
    return self._captionConfigId
end

return StoryStepActionCaption