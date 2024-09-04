local SkillClientNative = require("SkillClientNative")
local SkillClientEnum = require("SkillClientEnum")
local Vector3 = CS.UnityEngine.Vector3

---@class SESkillClientNative:SkillClientNative
local SESkillClientNative = class("SESkillClientNative", SkillClientNative)

---@param self SESkillClientNative
---@param ... any
---@return void
function SESkillClientNative:ctor(...)
    SESkillClientNative.super.ctor(self, ...)
    self.Environment = nil
end

---@param self SESkillClientNative
---@param dataShake skillclient.data.CameraShake
---@return void
function SESkillClientNative:CameraShake(dataShake)
    local env = require("SEEnvironment").Instance()
    --env:StartCameraShake(dataShake.AmplitudeGain, dataShake.FrequencyGain, dataShake.Time)
	env:StartCameraShake(dataShake)
end

---弹出伤害数字
---@param self SESkillClientNative
---@param damageTextData any
---@param skillTarget any
---@param serverData any
---@return void
function SESkillClientNative:SpawnDamageNum(damageTextData, skillTarget, serverData)
    local env = require("SEEnvironment").Instance()
    env:GetDamageManager():OnSkillClientDamage(damageTextData, skillTarget, serverData)
end

---@param self SESkillClientNative
---@param offsetType any
---@return void
function SESkillClientNative:GetOffset(offsetType)
    if offsetType == SkillClientEnum.OffsetType.Alert then
        return self.Environment:GetSkillManager():GetAlertOffset()
    end
    return SESkillClientNative.super.GetOffset(self, offsetType)
end

---@param self SESkillClientNative
---@param pos wrpc.PBVector3
---@return void
function SESkillClientNative:ConvertServerPos(pos)
    local env
    if (self.Environment) then
        env = self.Environment
    else
        env = require("SEEnvironment").Instance()
    end
    return env:ServerPos2Client(Vector3(pos.X, pos.Y, pos.Z))
end

return SESkillClientNative
