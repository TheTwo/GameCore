--- Created by wupei. DateTime: 2021/7/2

local Behavior = require("Behavior")
local SkillClientEnum = require("SkillClientEnum")
local SkillClientGen = require("SkillClientGen")
local Quaternion = CS.UnityEngine.Quaternion

---@class AdjustDirection:Behavior
---@field super Behavior
local AdjustDirection = class("AdjustDirection", Behavior)

---@param self AdjustDirection
---@param ... any
---@return void
function AdjustDirection:ctor(...)
    AdjustDirection.super.ctor(self, ...)
    ---@type skillclient.data.AdjustDirection
    self._adjustData = self._data
    self._tweener = nil
end

---@param self AdjustDirection
---@return void
function AdjustDirection:OnStart()
    if not self._adjustData.AutoAimTarget then
        self:UpdateForward(self._adjustData.Tweening)
    end
end

---@param self AdjustDirection
---@return void
function AdjustDirection:OnUpdate()
    if self._adjustData.AutoAimTarget then
        self:UpdateForward(false)
    end
end

---@param self AdjustDirection
---@return void
function AdjustDirection:OnEnd()
    if self:IsCancel() and self._tweener then
        if self._tweener:IsPlaying() then
            self._tweener:Complete()
        end
        self._tweener = nil
    end
end

---@param self AdjustDirection
---@param tweening any
---@return void
function AdjustDirection:UpdateForward(tweening)
    if self._skillTarget:IsCtrlValid() then
        local type = self._skillTarget:GetType()
        local dirTarget = self._adjustData.DirTarget
        local forward = nil
        if type == SkillClientEnum.SkillTargetType.Attacker then
            if dirTarget == SkillClientGen.DirTarget.Defender then
                forward = self._skillTarget:GetForwardToEnemy()
            elseif dirTarget == SkillClientGen.DirTarget.Server then
                if self._skillTarget:IsPlayer() then --只有玩家不受服务器影响
                    forward = self._skillParam:GetServerDataDirection()
                end
            end
        else
            if dirTarget == SkillClientGen.DirTarget.Attacker then
                forward = self._skillTarget:GetForwardToEnemy()
            --elseif dirTarget == SkillClientGen.DirTarget.Server then
                --不需要处理
            end
        end
        if forward ~= nil then
            forward.y = 0
            if forward.x ~= 0 or forward.z ~= 0 then
                if self._adjustData.Angle ~= 0 then
                    forward = Quaternion.Euler(0, self._adjustData.Angle, 0) * forward
                end
                if tweening then
                    self._tweener = self._skillTarget:SetForward(forward, self._adjustData.Time, self._adjustData.PlayRotAnim)
                else
                    self._skillTarget:SetForward(forward)
                end
            end
        end
    end
end

return AdjustDirection
