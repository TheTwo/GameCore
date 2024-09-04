---
--- Created by wupei. DateTime: 2022/1/21
---

---@class SkillClientUtils
local SkillClientUtils = {}
local rapidJson = require("rapidjson")

---@type table<table, CS.UnityEngine.AnimationCurve>
local curves = {}

local function GetSerializedFloatValue(value)
    if type(value) == "number" then
        return value
    elseif value == "Infinity" then
        return CS.System.Single.PositiveInfinity
    elseif value == "-Infinity" then
        return CS.System.Single.NegativeInfinity
    elseif value == "NaN" then
        return CS.System.Single.NaN
    end
    return 0
end

---@param data any
---@return CS.UnityEngine.AnimationCurve
function SkillClientUtils.GetCurve(data)
    if data == nil or data == rapidJson.null then
        return nil
    end
    local curve = curves[data]
    if curve == nil then
        curve = CS.UnityEngine.AnimationCurve()
        curves[data] = curve
        curve.preWrapMode = data.preWrapMode
        curve.postWrapMode = data.postWrapMode
        local Keyframe = CS.UnityEngine.Keyframe
        for _, v in ipairs(data.keys) do
            ---@type CS.UnityEngine.Keyframe
            local key = Keyframe()
            key.time = v.time
            key.value = v.value
            key.inTangent = GetSerializedFloatValue(v.inTangent)
            key.outTangent = GetSerializedFloatValue(v.outTangent)
            key.inWeight = GetSerializedFloatValue(v.inWeight)
            key.outWeight = GetSerializedFloatValue(v.outWeight)
            key.weightedMode = v.weightedMode
            curve:AddKey(key)
        end
    end
    return curve
end

---@return void
function SkillClientUtils.ClearCache()
    curves = {}
end

return SkillClientUtils
