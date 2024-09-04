---
--- Created by wupei. DateTime: 2021/12/22
---

local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local SELogger = require('SELogger')
local SkillDef = require("SkillDef")
local BuffGainType = require("BuffGainType")

---@class SEDamageData
---@field msg wrpc.SkillResultData
---@field time number
---@field hasDamage boolean

---@class SEDamageManager
local SEDamageManager = class("SEDamageManager")

local FT_STYLE_NORMAL = 0
local FT_STYLE_NORMAL_CRITICAL = 1
local FT_STYLE_HEALING = 2
local FT_STYLE_HEALING_CRITICAL = 3
local FT_STYLE_FIRE = 4
local FT_STYLE_FIRE_CRITICAL = 5
local FT_STYLE_ICE = 6
local FT_STYLE_ICE_CRITICAL = 7
local FT_STYLE_POISON = 8
local FT_STYLE_POISON_CRITICAL = 9
local FT_STYLE_ELECTRIC = 10
local FT_STYLE_ELECTRIC_CRITICAL = 11
local FT_STYLE_NORMAL_SKILL = 12
local FT_STYLE_NORMAL_SKILL_CRITICAL = 13
local FT_STYLE_BUFF_NEUTRAL = 14
local FT_STYLE_BUFF_POSITIVE = 15
local FT_STYLE_BUFF_NEGATIVE = 16

local DI_DURATION = 0.2
local DI_OFFSET = 0.2
local DI_OFFSET_MAX = 0.6
local DI_HOSTILE_DURATION = 0.2
local DI_HOSTILE_OFFSET = 0.2
local DI_HOSTILE_OFFSET_MAX = 0.6

local BUFF_ATTACKER_ID = 'buff_attacker_id'
local BUFF_SEQ_NO = 'buff_seq_no'

---@param self SEDamageManager
---@param env any
---@return void
function SEDamageManager:ctor(env)
    DI_DURATION = ConfigRefer.ConstSe:SeFloatingTextCheckDuration()
    DI_OFFSET = ConfigRefer.ConstSe:SeFloatingTextOffset()
    DI_OFFSET_MAX = ConfigRefer.ConstSe:SeFloatingTextOffsetMax()
    DI_HOSTILE_DURATION = ConfigRefer.ConstSe:SeFloatingTextHostileCheckDuration()
    DI_HOSTILE_OFFSET = ConfigRefer.ConstSe:SeFloatingTextHostileOffset()
    DI_HOSTILE_OFFSET_MAX = ConfigRefer.ConstSe:SeFloatingTextHostileOffsetMax()

    ---@type SEEnvironment
    self._env = env
    ---@type table<string, SEDamageData>
    self._damageValues = {}
    ---@type Timer
    self._timer = nil
end

---@param self SEDamageManager
---@return SEEnvironment
function SEDamageManager:GetEnvironment()
    return self._env
end

---@param self SEDamageManager
---@return void
function SEDamageManager:Dispose()
    if self._timer then
        TimerUtility.StopAndRecycle(self._timer)
        self._timer = nil
    end
end

---@param self SEDamageManager
---@return void
function SEDamageManager:Start()
    self._timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnClearDamage), 5, -1)
end

local list = {0, 0, 0, 0}
local GetKey = function(attackerId, runnerId, targetId, seqNo)
    list[1] = attackerId
    list[2] = runnerId
    list[3] = targetId
    list[4] = seqNo
    return table.concat(list)
end

---@param self SEDamageManager
---@param msg wrpc.SkillResultData
function SEDamageManager:OnPushBattleBuffDamage(msg)
    self:PopDamage(msg, 1)
end

---@param self SEDamageManager
---@param msg wrpc.SkillResultData
---@param attackerId number
---@return void
function SEDamageManager:OnPushBattleDamage(msg, attackerId)
    local runnerId = msg.RunnerId
    local targetId = msg.TargetId
    local seqNo = msg.SeqNo
    local key = GetKey(attackerId, runnerId, targetId, seqNo)
    local value = self._damageValues[key]
    if (not value) then
        ---@type SEDamageData
        local damageData = {}
        damageData.msg = msg
        damageData.time = g_Game.Time.time
        self._damageValues[key] = damageData
    elseif value.hasDamage then
        self._damageValues[key] = nil
        self:PopDamage(msg, 1)  --关键帧已过,直接弹出
    else
        SELogger.Log("runnerId repeated, attackerId:%s, runnerId:%s, targetId:%s", attackerId, runnerId, targetId)
    end
end

---@param self SEDamageManager
---@param damageText skillclient.data.DamageText
---@param skillTarget SkillClientTarget
---@param serverData wrpc.SkillInfo
---@return void
function SEDamageManager:OnSkillClientDamage(damageText, skillTarget, serverData)
    if not skillTarget:IsCtrlValid() then
        return
    end

    if (serverData == nil) then
        SELogger.Error('SEDamageManager:OnSkillClientDamage return, serverData is nil')
        return
    end

    local runnerId = serverData.RunnerId
    local targetId = skillTarget:GetID()
    local seqNo = serverData.SeqNo
    local attackerId = skillTarget:GetSkillParam():GetAttackerId()
    local rate = damageText.Rate
    self:OnClientDamage(runnerId, targetId, seqNo, attackerId, rate, serverData.localDummy)
end

---@param self SEDamageManager
---@param runnerId number
---@param targetId number
---@param seqNo number
---@param attackerId number
---@param rate number
---@param localDummy {msg:wrpc.SkillResultData}
function SEDamageManager:OnClientDamage(runnerId, targetId, seqNo, attackerId, rate, localDummy)
    local key = GetKey(attackerId, runnerId, targetId, seqNo)
    local msg = self._damageValues[key]
    if msg ~= nil and msg.msg ~= nil then
        self:PopDamage(msg.msg, rate)
    elseif localDummy then
        self:PopDamage(localDummy.msg, rate)
    else
        ---@type SEDamageData
        local damageData = {}
        damageData.hasDamage = true
        damageData.time = g_Game.Time.time
        self._damageValues[key] = damageData --未取到伤害
    end
end

local CLEAR_TIME = 20

---@param self SEDamageManager
---@return void
function SEDamageManager:OnClearDamage()
    local map = self._damageValues
    local time = g_Game.Time.time
    for key, value in pairs(map) do
        if time - value.time > CLEAR_TIME then
            map[key] = nil
        end
    end
end

---@param self SEDamageManager
---@param msg wrpc.SkillResultData
---@param rate any
---@return void
function SEDamageManager:PopDamage(msg, rate)
    --SELogger.Log("PushBattleDamage %s", msg.Msg)

    -- Invisible
    if (self:GetEnvironment():IsEntityInvisible(msg.TargetId)) then
        return
    end

    ---@type SEUnit
    local unit = self:GetEnvironment():GetUnitManager():GetUnit(msg.TargetId)
    if (not unit) then
        unit = self:GetEnvironment():GetUnitManager():GetDeadUnit(msg.TargetId)
        if (not unit) then
            --SELogger.LogError("OnPushBattleDamage TargetId [%s] not found!", msg.Msg.TargetId)
            return
        end
    end

    local damageMsg = msg.Damage
    rate = rate or 1
    local isNormalAttack = false
    local fromBuff = false
    local buffGainType = FT_STYLE_BUFF_NEUTRAL
    if msg.RunnerType and msg.ConfigId then
        if msg.RunnerType == wrpc.DamageRunnerType.DamageRunnerType_Skill then
            local skillLogic = ConfigRefer.KheroSkillLogicalSe:Find(msg.ConfigId)
            if skillLogic then
                local skillDef = skillLogic:SkillDef()
                if skillDef == SkillDef.NormalAttack or skillDef == SkillDef.NormalAttackReally then
                    isNormalAttack = true
                end
            end
        elseif msg.RunnerType == wrpc.DamageRunnerType.DamageRunnerType_Buff then
            local buffConfig = ConfigRefer.KheroBuffLogicalSe:Find(msg.ConfigId)
            if buffConfig then
                local gainType = buffConfig:GainType()
                if gainType == BuffGainType.Positive then
                    buffGainType = FT_STYLE_BUFF_POSITIVE
                elseif gainType == BuffGainType.Negative then
                    buffGainType = FT_STYLE_BUFF_NEGATIVE
                end
            end
        end
    end

    -- Healing?
    local healing = false
    local value
    if damageMsg.Value > 0 then
        value = math.floor(damageMsg.Value * rate)
    else
        value = math.ceil(damageMsg.Value * rate)
    end
    if value == 0 then
        return
    end
    local hostile = self:GetEnvironment():IsHostile(unit)

    -- Style
    local style
    if (value < 0) then
        healing = true
        if hostile then
            -- 敌对不用展示回血
            return
        end
        value = -value
        if (damageMsg.IsCritical) then
            style = FT_STYLE_HEALING_CRITICAL
        else
            style = FT_STYLE_HEALING
        end
    else
        local sdt = require("SpecialDamageType")
        if fromBuff then
            style = buffGainType
        elseif not hostile then
            style = FT_STYLE_NORMAL
            if (damageMsg.IsCritical) then
                style = FT_STYLE_NORMAL_CRITICAL
            end
        elseif not isNormalAttack then
            style = FT_STYLE_NORMAL_SKILL
            if (damageMsg.IsCritical) then
                style = FT_STYLE_NORMAL_SKILL_CRITICAL
            end
        elseif (damageMsg.SpecialDamageType == sdt.Fire) then
            style = FT_STYLE_FIRE
            if (damageMsg.IsCritical) then
                style = FT_STYLE_FIRE_CRITICAL
            end
        elseif (damageMsg.SpecialDamageType == sdt.Elec) then
            style = FT_STYLE_ELECTRIC
            if (damageMsg.IsCritical) then
                style = FT_STYLE_ELECTRIC_CRITICAL
            end
        elseif (damageMsg.SpecialDamageType == sdt.Ice) then
            style = FT_STYLE_ICE
            if (damageMsg.IsCritical) then
                style = FT_STYLE_ICE_CRITICAL
            end
        elseif (damageMsg.SpecialDamageType == sdt.Poison) then
            style = FT_STYLE_POISON
            if (damageMsg.IsCritical) then
                style = FT_STYLE_POISON_CRITICAL
            end
        else
            style = FT_STYLE_NORMAL
            if (damageMsg.IsCritical) then
                style = FT_STYLE_NORMAL_CRITICAL
            end
        end
    end

    local modelId = unit:GetData():GetConfig():Model()
    local model = ConfigRefer.ArtResource:Find(modelId)
    local yOffset = model and model:HpYOffset() or 0

    -- 伤害飘字间隔检查
    local di = unit:GetData():GetDamageIntervalData(healing, damageMsg.IsCritical)
    local dur = DI_DURATION
    local off = DI_OFFSET
    local max = DI_OFFSET_MAX
    if (hostile) then
        dur = DI_HOSTILE_DURATION
        off = DI_HOSTILE_OFFSET
        max = DI_HOSTILE_OFFSET_MAX
    end
    if (g_Game.Time.time - di.lastDamageTime >= dur) then
        di.totalOffset = 0
    else
        di.totalOffset = di.totalOffset + off
        if (di.totalOffset > max) then
            di.totalOffset = 0
        end
    end
    di.lastDamageTime = g_Game.Time.time
    yOffset = yOffset + di.totalOffset

     self:GetEnvironment():SpawnFloatingText(style, unit, tostring(value), CS.UnityEngine.Vector3(0, yOffset, 0), hostile)
end

return SEDamageManager
