--- Created by wupei. DateTime: 2021/7/2

local SELogger = require("SELogger")

local Behavior = require("Behavior")

---@class Move:Behavior
---@field super Behavior
local Move = class("Move", Behavior)

---@param self Move
---@param ... any
---@return void
function Move:ctor(...)
    Move.super.ctor(self, ...)

    ---@type skillclient.data.Move
    self._dataMove = self._data
    self._moveTweener = nil
end

---@param self Move
---@return void
function Move:OnStart()
    if self._skillParam:IsIgnoreMove(self._skillTarget) then
        return
    end

    local ctrl = self._skillTarget:GetCtrl()
    if ctrl and ctrl:IsValid() then
        -- 说明文档: https://funplus.yuque.com/slgtech/ls944w/gz31bv (技能编辑器备注)
        -- 尝试获取服务端计算的目标位置
        local targetId = self._skillTarget:GetID()
        local dstPos,serverOriginPos = self._skillParam:GetMoveEndPosition(targetId)
        if not dstPos then
            return
        end
        if serverOriginPos and serverOriginPos.X == 0 and serverOriginPos.Y == 0 then
            SELogger.Trace("Try push to [0,0], ignored!")
            return
        end
        local curve = require("SkillClientUtils").GetCurve(self._dataMove.Curve)
        self._moveTweener = ctrl:TryPushTo(dstPos, self._dataMove.Time, curve)
    end
end

---@param self Move
---@return void
function Move:OnEnd()
    self._moveTweener = nil
end

---@param self Move
---@return void
function Move:OnTimeScaleChanged()
    if self._moveTweener and self._moveTweener:IsActive() then
        self._moveTweener.TimeScale = self._skillRunner:GetTimeScale()
    end
end

return Move
