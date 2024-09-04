---
--- Created by wupei. DateTime: 2022/3/1
---

local BuffBehavior = require("BuffBehavior")
local Utils = require("Utils")
local Delegate = require("Delegate")
local BuffClientManager = require("BuffClientManager")
local gen = require("BuffClientGen")
local SESceneRoot = require("SESceneRoot")
local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion

local VectorMult = function(v1, v2)
    return Vector3(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z)
end

local VectorDivNumber = function(v1, v2)
    return Vector3(v1.x / v2, v1.y / v2, v1.z / v2)
end

---@class BuffEffect:BuffBehavior
local BuffEffect = class("BuffEffect", BuffBehavior)

---@param self BuffEffect
---@param ... any
---@return void
function BuffEffect:ctor(...)
    BuffEffect.super.ctor(self, ...)

    ---@type buffclient.data.Effect
    self._effectData = self._data
    self._effect = nil
	self.createHelper = BuffClientManager.GetInstance():GetCreateHelper("BuffClientEffect")
    self._needWaitOnCtrlValidForStart = false
end

function BuffEffect:DoOnStartImpl()
    local success, parent, pos, rot, scale = self:CheckTransAndParam()
    if not success then
        return
    end

    self:CreateEffect()
    if (parent and self._effect.SetParent) then
        self._effect:SetParent(parent)
    end
	if (self._effect.SetLocalPosition) then
        if Utils.IsNotNull(parent) then
            pos = parent:InverseTransformPoint(pos)
        end
		self._effect:SetLocalPosition(pos)
	end
	if (self._effect.SetLocalRotation) then
		self._effect:SetLocalRotation(rot)
	end
	if (self._effect.SetLocalScale) then
		self._effect:SetLocalScale(scale)
	end
end

---@param self BuffEffect
---@return void
function BuffEffect:OnStart()
    self._needWaitOnCtrlValidForStart = false
    if string.IsNullOrEmpty(self._effectData.EffectPath) then
        return
    end
    if self:CheckNeedWaitTargetValid() then
        self._needWaitOnCtrlValidForStart = true
        return
    end
    self:DoOnStartImpl()
end

function BuffEffect:OnCtrlValid()
    if not self._needWaitOnCtrlValidForStart then
        return
    end
    self._needWaitOnCtrlValidForStart = false
    self:DoOnStartImpl()
end

---@param self BuffEffect
---@return void
function BuffEffect:CreateEffect()
    local filename = nil
    if self._effectData.EffectPath then
        filename = get_filename_without_extension(self._effectData.EffectPath)
        if not filename then
            g_Logger.Error("Create Effect Failed. path: %s", self._effectData.EffectPath)
        end
    end

    self._effect = self.createHelper:Create(filename, require("SESceneRoot").GetSceneRoot(), Delegate.GetOrCreate(self, self.InitEffect), nil, 0, false)
end

function BuffEffect:InitEffect(go, userdata)
    local success, parent, pos, rot, scale = self:CheckTransAndParam()
    if not success then
        return
    end
    local effectTrans = go.transform
    if parent then
        effectTrans:SetParent(parent, false)
    end
    effectTrans.localPosition = pos
    effectTrans.localRotation = rot
    effectTrans.localScale = scale
end

function BuffEffect:CheckNeedWaitTargetValid()
    local dataAttach = self._effectData.Attach
    if dataAttach == gen.Attach.AttachNodeSelf then
        return not self._target:IsCtrlValid()
    elseif not self._effectData.IsFollow then
        if dataAttach ~= gen.Attach.OtherRoot then
            return not self._target:IsCtrlValid()
        end
    elseif dataAttach ~= gen.Attach.OtherRoot then
        return not self._target:IsCtrlValid()
    end
    return false
end

---@param self BuffEffect
---@return void
function BuffEffect:CheckTransAndParam()
    local dataAttach = self._effectData.Attach
    local clientScale = SESceneRoot.GetClientScale()
    local nilParent = SESceneRoot.GetSceneRoot()
    local dataOffset = Vector3(self._effectData.Offset.x * clientScale, self._effectData.Offset.y * clientScale, self._effectData.Offset.z * clientScale)
    local dataRotation = Quaternion.Euler(self._effectData.Rotation)
    local dataScale = self._effectData.Scale
    local parent, pos, rot, scale
    if dataAttach == gen.Attach.AttachNodeOther then
        g_Logger.Error("buff不能使用AttachNodeOther")
        return false
    elseif dataAttach == gen.Attach.AttachNodeSelf then
        local attachTrans = self:GetTransSubNode(self._target:GetTransform(), self._effectData.AttachNodeName)
        if attachTrans == nil then
            return false
        end
        if not self._effectData.IsFollow then
            parent = nilParent
            pos = attachTrans.position + attachTrans.rotation * dataOffset
            rot = attachTrans.parent.rotation * (attachTrans.localRotation * dataRotation)
            scale = VectorMult(attachTrans.lossyScale, dataScale)
            scale = VectorDivNumber(scale, clientScale)
        else
            parent = attachTrans
            pos = dataOffset
            rot = dataRotation
            scale = dataScale
        end
    else
        if not self._effectData.IsFollow then
            parent = nilParent
            local trans
            if dataAttach == gen.Attach.OtherRoot then
                g_Logger.Error("buff不能使用OtherRoot")
                return false
            else
                trans = self._target:GetTransform()
            end
            if trans then
                pos = trans.position + trans.rotation * dataOffset
                rot = trans.parent.rotation * (trans.localRotation * dataRotation)
                scale = VectorMult(trans.lossyScale, dataScale)
                scale = VectorDivNumber(scale, clientScale)
            else
                if dataAttach == gen.Attach.OtherRoot then
                    g_Logger.Error("buff不能使用OtherRoot")
                    return false
                else
                    pos = self._target:GetPosition(dataOffset)
                end
                rot = dataRotation
                scale = dataScale
            end
        else
            if dataAttach == gen.Attach.OtherRoot then
                g_Logger.Error("buff不能使用OtherRoot")
                return false
            else
                parent = self._target:GetTransform()
            end
            if parent == nil then
                return false
            end
            pos = dataOffset
            rot = dataRotation
            scale = dataScale
        end
    end
    return true, parent, pos, rot, scale
end

---@param self BuffEffect
---@return void
function BuffEffect:OnEnd()
    if self._effect then
        self.createHelper:Delete(self._effect)
        self._effect = nil
        self.createHelper = nil
    end
end

---@param self BuffEffect
---@param trans any
---@param name any
---@return UnityEngine.Transform
function BuffEffect:GetTransSubNode(trans, name)
    if Utils.IsNotNull(trans) then
        local findTrans = trans:FirstOrDefaultByName(name)
        if findTrans then
            trans = findTrans
        else
            g_Logger.Log("trans not found. attachNodeName: %s, root: %s", name,
                    trans.name)
        end
    end
    return trans
end

return BuffEffect
