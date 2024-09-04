local CitizenBTDefine = require("CitizenBTDefine")
local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenStateHelper = require("CityCitizenStateHelper")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionPlayClipContextParam
---@field clipName string
---@field soundId number @audioResId
---@field leftTime number|nil
---@field skipRestore boolean

---@class CitizenBTActionPlayClip:CitizenBTActionNode
---@field new fun():CitizenBTActionPlayClip
---@field super CitizenBTActionNode
local CitizenBTActionPlayClip = class('CitizenBTActionPlayClip', CitizenBTActionNode)

function CitizenBTActionPlayClip:Enter(context, gContext)
    self:CheckAndFixPos(context, gContext)
    ---@type CitizenBTActionPlayClipContextParam
    local playClipParam = context:Read(CitizenBTDefine.ContextKey.PlayClipInfo)
    local citizen = context:GetCitizen()
    citizen:ChangeAnimatorState(playClipParam.clipName)
    if playClipParam.soundId and playClipParam.soundId ~= 0 then
        self._soundHandle = citizen:PlaySound(playClipParam.soundId)
    end
    self._skipRestore = playClipParam.skipRestore or false
    self._leftTime = playClipParam.leftTime
end

function CitizenBTActionPlayClip:Run(context, gContext)
    ---@type CitizenBTActionPlayClipContextParam
    local playClipParam = context:Read(CitizenBTDefine.ContextKey.PlayClipInfo)
    if not playClipParam then
        return false
    end
    return CitizenBTActionPlayClip.super.Run(self, context, gContext)
end

function CitizenBTActionPlayClip:Tick(dt, nowTime, context, gContext)
    if not self._leftTime then
        return
    end
    self._leftTime = self._leftTime - dt
    if self._leftTime < 0 then
        return true
    end
end

function CitizenBTActionPlayClip:Exit(context, gContext)
    if self._soundHandle then
        g_Game.SoundManager:Stop(self._soundHandle)
    end
    self._soundHandle = nil
    if not self._skipRestore then
        local citizen = context:GetCitizen()
        citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    end
end

---@param context CitizenBTContext
---@param gContext CitizenBTContext
function CitizenBTActionPlayClip:CheckAndFixPos(context, gContext)
    ---@type CitizenBTActionGoToContextParam
    local targetInfo = context:Read(CitizenBTDefine.ContextKey.GotoTargetInfo)
    if targetInfo then
        if targetInfo.exitDir then
            context:GetCitizen()._moveAgent:StopMoveTurnToRotation(targetInfo.exitDir)
            return
        elseif targetInfo.exitTurnTo then
            context:GetCitizen()._moveAgent:StopMoveTurnToPos(targetInfo.exitTurnTo)
            return
        end
    end
    local citizenData = context:GetCitizenData()
    targetInfo = CityCitizenStateHelper.GetTargetInfo(context)
    if not targetInfo then
        return
    end
    local pos = context:GetCitizen():ReadMoveAgentPos()
    if not pos then
        return
    end
    targetInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    local targetPos = citizenData:GetDirPositionById(targetInfo.id, targetInfo.type)
    if not targetPos then
        return
    end
    context:GetCitizen()._moveAgent:StopMoveTurnToPos(targetPos)
end

return CitizenBTActionPlayClip