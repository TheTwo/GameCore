local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionSoundEvent:StoryStepActionBase
---@field new fun():StoryStepActionSoundEvent
---@field super StoryStepActionBase
local StoryStepActionSoundEvent = class('StoryStepActionSoundEvent', StoryStepActionBase)

function StoryStepActionSoundEvent:ctor()
    StoryStepActionBase.ctor(self)
    self._audioId = nil
    self._audioKey = string.Empty
end

function StoryStepActionSoundEvent:LoadConfig(actionParam)
    if string.IsNullOrEmpty(actionParam) then
        g_Logger.Warn("actionParam is empty!")
        self:SetEndStatus(false)
        return
    end
    self._audioId = tonumber(actionParam)
    if not self._audioId then
        self._audioKey = actionParam
    end
end

function StoryStepActionSoundEvent:OnEnter()
    if self._audioId then
        g_Game.SoundManager:PlayAudio(self._audioId)
    else
        g_Game.SoundManager:Play(self._audioKey)
    end
    self:SetEndStatus(false)
end

return StoryStepActionSoundEvent