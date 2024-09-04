--- Created by wupei. DateTime: 2021/7/3

local Utils = require("Utils")

local Behavior = require("Behavior")

---@class GlowEffect:Behavior
---@field super Behavior
local GlowEffect = class("GlowEffect", Behavior)
local Color = CS.UnityEngine.Color
local ColorCreate = function(color)
    return Color(color.r, color.g, color.b, color.a)
end

local EffectColorId --Common/ChareacterSE
local initColor

---@param self GlowEffect
---@param ... any
---@return void
function GlowEffect:ctor(...)
    GlowEffect.super.ctor(self, ...)
    
    ---@type skillclient.data.GlowEffect
    self._glowData = self._data
    self._renderers = nil
    self._startColor = nil
    self._endColor = nil
    self._startTime = 0
    self._init = false
    self._id = 0
end

---@param self GlowEffect
---@return void
function GlowEffect:OnStart()
    if not self._skillTarget:IsCtrlValid() then
        return
    end

    local renderers = self._skillTarget:GetCtrl():GetFbxRendererList()
    if renderers == nil or renderers.Length <= 0 then
        return
    end

    -- add running state
    self._id = self._skillTarget:GetCtrl():GenerateGlowEffectId()
    self._skillTarget:GetCtrl():AddRunningGlowEffect(self._id, self._glowData)

    self._renderers = renderers

    if EffectColorId == nil then
        EffectColorId = CS.UnityEngine.Shader.PropertyToID("_EffectColor")
    end

    if initColor == nil then
        initColor = CS.UnityEngine.Color(0, 0, 0, 0)
    end

    self._startColor = ColorCreate(self._glowData.Color)
    self._endColor = ColorCreate(self._glowData.EndColor)
    self._startTime = self._skillRunner:GetTime()
    self:SetColor(self._startColor)

    self._init = true
end

---@param self GlowEffect
---@return void
function GlowEffect:OnUpdate()
    if not self._init then
        return
    end

    local easeTime = self._glowData.EaseTime
    if easeTime <= 0 then
        return
    end

    local passTime = self._skillRunner:GetTime() - self._startTime
    local time = passTime % (2 * easeTime)
    local startColor, endColor, rate
    if time < easeTime then
        startColor = self._startColor
        endColor = self._endColor
        rate = time / easeTime
    else
        startColor = self._endColor
        endColor = self._startColor
        rate = (time - easeTime) / easeTime
    end

    self:SetColor(Color.Lerp(startColor, endColor, rate))
end

---@param self GlowEffect
---@return void
function GlowEffect:OnEnd()
    if self._renderers == nil or self._renderers.Length <= 0 then
        return
    end

    -- restore color
    self:SetColor(initColor)

    -- remove running state
    self._skillTarget:GetCtrl():RemoveRunningGlowEffect(self._id)
end

---@param self GlowEffect
---@param color any
---@return void
function GlowEffect:SetColor(color)
    -- 给当前显示的GlowEffect设置颜色
    local displayGlowEffectId = self._skillTarget:GetCtrl():GetDisplayGlowEffectId()
    if self._id ~= displayGlowEffectId then
        return
    end

    for i = 0, self._renderers.Length - 1 do
        ---@type UnityEngine.Renderer
        local render = self._renderers[i]
        if Utils.IsNotNull(render) then
            render.material:SetColor(EffectColorId, color)
        end
    end
end

return GlowEffect
