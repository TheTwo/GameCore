local Delegate = require("Delegate")
local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local UIMediatorNames = require('UIMediatorNames')
local StoryDialogType = require("StoryDialogType")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionDialog:StoryStepActionBase
---@field new fun():StoryStepActionDialog
---@field super StoryStepActionBase
local StoryStepActionDialog = class('StoryStepActionDialog', StoryStepActionBase)

function StoryStepActionDialog:ctor()
    StoryStepActionBase.ctor(self)
    self._mediatorId = nil
    self._skipRestoreDialogPlaying = false
end

function StoryStepActionDialog:LoadConfig(actionParam)
    self._dialogGroupId = tonumber(actionParam)
end

function StoryStepActionDialog:OnEnter()
    self._skipRestoreDialogPlaying = true
    local param = StoryDialogUIMediatorParameter.new();
    local dialogType = param:SetDialogGroup(self._dialogGroupId, Delegate.GetOrCreate(self, self.OnDialogEnd))
    if not dialogType then
        self:EndAction(false)
        return
    end
    self._skipRestoreDialogPlaying = dialogType ~= StoryDialogType.CharacterDrawing
    g_Game.EventManager:AddListener(EventConst.STORY_DIALOG_UI_CLOSED, Delegate.GetOrCreate(self, self.OnDialogUIClosed))
    if dialogType ~= StoryDialogType.SmallAvatarThrough then
        self:SetGestureBlock()
        self._unRef = true
    end
    self._mediatorId = ModuleRefer.StoryModule:OpenDialogMediatorByType(dialogType, param, true)
    self.NeedDelayCleanUp = false
    if not self._skipRestoreDialogPlaying then
        ModuleRefer.StoryModule:SetStoryDialogPlaying(true)
    end
end

function StoryStepActionDialog:OnLeave()
    if not self._skipRestoreDialogPlaying then
        ModuleRefer.StoryModule:SetStoryDialogPlaying(false)
    end
    if self._unRef then
        self._unRef = false
        self:UnSetGestureBlock()
    end
    
    g_Game.EventManager:RemoveListener(EventConst.STORY_DIALOG_UI_CLOSED, Delegate.GetOrCreate(self, self.OnDialogUIClosed))
    if self.NeedDelayCleanUp then
        if self._mediatorId then
            local mediator = g_Game.UIManager:FindUIMediator(self._mediatorId)
            if mediator then
                mediator.__canDelayCleanUp = true
                mediator:Hide()
            end
        end
    else
        if self._mediatorId then
            g_Game.UIManager:Close(self._mediatorId)
        end
        self._mediatorId = nil
    end
end

function StoryStepActionDialog:OnDelayCleanUp()
    if self._mediatorId then
        local mediator = g_Game.UIManager:FindUIMediator(self._mediatorId)
        if mediator and mediator.__canDelayCleanUp then
            g_Game.UIManager:Close(self._mediatorId)
        end
    end
    self._mediatorId = nil
end

function StoryStepActionDialog:OnDialogEnd()
    self:EndAction(true)
end

function StoryStepActionDialog:OnDialogUIClosed()
    if self.IsDone or self.IsFailure then
        return
    end
    self:EndAction(true)
end

function StoryStepActionDialog:GetDialogGroupId()
    return self._dialogGroupId
end

return StoryStepActionDialog