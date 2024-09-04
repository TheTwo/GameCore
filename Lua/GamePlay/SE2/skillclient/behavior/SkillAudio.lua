--- Created by wupei. DateTime: 2021/8/5

local Behavior = require("Behavior")

---@class SkillAudio:Behavior
---@field super Behavior
local SkillAudio = class("SkillAudio", Behavior)

---@param self SkillAudio
---@param ... any
---@return void
function SkillAudio:ctor(...)
    SkillAudio.super.ctor(self, ...)

    ---@type skillclient.data.SkillAudio
    self._skillAudioData = self._data
    self._audioHandle = nil
    self._isPlaying = false
end

---@param self SkillAudio
---@return void
function SkillAudio:OnStart()
    self._isPlaying = false

    if self._skillAudioData.DestroyWhenOwnerDie then
        if self._skillTarget:HasCtrlAndDead() then
            return
        end
    end

    self._isPlaying = true
    self._audioHandle = g_Game.SoundManager:Play(self._skillAudioData.EventName)
end

---@param self SkillAudio
---@return void
function SkillAudio:OnUpdate()
    if not self._isPlaying then
        return
    end

    -- 人物死亡销毁
    if self._skillAudioData.DestroyWhenOwnerDie then
        if self._skillTarget:HasCtrlAndDead() then
            self:StopAudio()
            return
        end
    end

    -- 技能取消停止
    if self._skillAudioData.DestroyWhenSkillCancel then
        if self:IsCancel() then
            self:StopAudio()
            return
        end
    end
end

---@param self SkillAudio
---@return void
function SkillAudio:OnEnd()
    
end

function SkillAudio:StopAudio()
    if self._isPlaying and self._audioHandle:IsValid() then
        self._isPlaying = false
        g_Game.SoundManager:Stop(self._audioHandle)
    end
end

return SkillAudio
