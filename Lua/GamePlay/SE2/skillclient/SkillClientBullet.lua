---
--- Created by wupei. DateTime: 2021/12/8
---

---@class SkillClientBullet
local SkillClientBullet = class("SkillClientBullet")
local Vector3 = CS.UnityEngine.Vector3
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local Delegate = require("Delegate")
local SELogger = require('SELogger')
local ProjectileType = require("SkillClientGen").ProjectileType
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle

---@protected
function SkillClientBullet:ctor(...)
    self._skillClientParam = nil
	self._target = nil
    self._targetTrans = nil
    self._targetPosition = Vector3.zero
    self._bulletSpeed = 0
    self._parent = nil
    self._transform = nil
    self._localPosition = nil
    self._localRotation = nil
    self._localScale = nil
    self._position = nil
    self._rotation = nil
    -- self._timer = nil
    self._effect = PooledGameObjectHandle("SkillClientBullet")
	self._projectileType = ProjectileType.Line
	self._verticalSpeed = 0
	self._verticalAcc = 0
end

---@param param SkillClientParam
function SkillClientBullet:SetSkillClientParam(param)
    self._skillClientParam = param
end

---@param data skillclient.data.Effect
function SkillClientBullet:SetData(data)
	---@type skillclient.data.Effect
	self._data = data
end

function SkillClientBullet:SetTarget(target)
	self._target = target
end

function SkillClientBullet:CreateEffect(assetPath)
    local filename = get_filename_without_extension(assetPath)
    if not filename then
        g_Logger.Error("Create Effect Failed. path: %s", assetPath)
    end

    self._effect:Create(filename, require("SESceneRoot").GetSceneRoot(), Delegate.GetOrCreate(self, self.InitEffect))
end

function SkillClientBullet:InitEffect(go, userdata)
    if Utils.IsNull(go) then
        g_Logger.Error('SkillClientBullet:InitEffect return: go is nil')
        return
    end
    
    self._transform = go.transform
    if self._parent then
        self._transform:SetParent(self._parent, false)
    end
    if self._localPosition then
        self._transform.localPosition = self._localPosition
    end
    if self._position then
        self._transform.position = self._position
    end
    if self._localRotation then
        self._transform.localRotation = self._localRotation
    end
    if self._rotation then
        self._transform.rotation = self._rotation
    end
    if self._localScale then
        self._transform.localScale = self._localScale
    end
    if self._lockRot then
        self._lockBeh = CS.DragonReborn.LockWorldRotation.Get(self._transform)
        self._lockBeh:StartLock(self._lockRot)
    end

	-- 技能预警圈处理
	if (self._data and self._data.IsAlertRange) then
		---@type CS.AlertRange
		local alertRange = go:GetComponent(typeof(CS.AlertRange))
		if (Utils.IsNotNull(alertRange)) then
			alertRange:SetTime(self._data.Time)
		end
	end
end

function SkillClientBullet:DestroyEffect()
    -- if self._timer then
    --     TimerUtility.StopAndRecycle(self._timer)
    --     self._timer = nil
    -- end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
    
    self._transform = nil
    self._effect:Delete()

    if self._lockBeh then
        self._lockBeh.enabled = false
    end
end

function SkillClientBullet:SetParent(parent)
    if Utils.IsNotNull(self._transform) then
        self._transform:SetParent(parent)
    else
        self._parent = parent
    end
end

function SkillClientBullet:SetPosition(pos)
	if (Utils.IsNotNull(self._transform)) then
		self._transform.position = pos
	else
		self._position = pos
	end
end

function SkillClientBullet:SetLocalPosition(pos)
    if Utils.IsNotNull(self._transform) then
        self._transform.localPosition = pos
    else
        self._localPosition = pos
    end
end

function SkillClientBullet:GetPosition()
	if (Utils.IsNotNull(self._transform)) then
		return self._transform.position
	else
		return self._position
	end
end

function SkillClientBullet:GetLocalPosition()
    if Utils.IsNotNull(self._transform) then
        return self._transform.localPosition
    else
        return self._localPosition
    end
end

function SkillClientBullet:SetLocalRotation(rot)
    if Utils.IsNotNull(self._transform) then
        self._transform.localRotation = rot
    else
        self._localRotation = rot
    end
end

function SkillClientBullet:GetLocalRotation()
    if Utils.IsNotNull(self._transform) then
        return self._transform.localRotation
    else
        return self._localRotation
    end
end

function SkillClientBullet:SetLocalScale(scale)
    if Utils.IsNotNull(self._transform) then
        self._transform.localScale = scale
    else
        self._localScale = scale
    end
end

function SkillClientBullet:GetLocalScale()
    if Utils.IsNotNull(self._transform) then
        return self._transform.localScale
    else
        return self._localScale
    end
end

function SkillClientBullet:GetPosition()
    if Utils.IsNotNull(self._transform) then
        return self._transform.position
    else
        return self._position
    end
end

function SkillClientBullet:SetRotation(rot)
    if Utils.IsNotNull(self._transform) then
        self._transform.rotation = rot
    else
        self._rotation = rot
    end
end

function SkillClientBullet:GetRotation()
    if Utils.IsNotNull(self._transform) then
        return self._transform.rotation
    else
        return self._rotation
    end
end

function SkillClientBullet:SetForward(forward)
    self:SetRotation(CS.UnityEngine.Quaternion.LookRotation(forward))
end

function SkillClientBullet:SetTargetPosition(targetTrans, targetPos, bulletSpeed)
    self._targetTrans = targetTrans
    self._targetPosition = targetPos
    self._bulletSpeed = bulletSpeed
    -- self._timer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.Update), 0, -1, true)
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Update))
	if (not self._targetPosition) then
		if (self._targetTrans) then
			self._targetPosition = self._targetTrans.position
		end
	end
end

function SkillClientBullet:SetProjectileType(type)
	self._projectileType = type

	-- 定高伪抛物线处理
	if (type == ProjectileType.HeightFixedParabola) then
		local h = self._data.Height
		local pos = self:GetPosition()
		local pv2 = CS.UnityEngine.Vector2(pos.x, pos.z)
		local tv2 = CS.UnityEngine.Vector2(self._targetPosition.x, self._targetPosition.z)
		local dist = CS.UnityEngine.Vector2.Distance(pv2, tv2)
		local t = dist / self._data.Speed
		local a = 2 * h / t / t
		self._verticalAcc = -a
		self._verticalSpeed = a * t
		self._horizentalSpeed = self._data.Speed
	end
end

function SkillClientBullet:Update(delta)
	if (not self._target or not self._target:IsCtrlValid() or (self._data.DestroyWhenOwnerDie and self._target:HasCtrlAndDead())) then
		self:DestroyEffect()
		return
	end

    if (Utils.IsNull(self._targetPosition) and Utils.IsNull(self._targetTrans)) then
        SELogger.LogError('SkillClientBullet:Update targetPosition and targetTrans are nil')
		self:DestroyEffect()
        return
    end

	if (Utils.IsNull(self._targetPosition)) then
		self._targetPosition = self._targetTrans.position
	end

    local pos = self:GetPosition()
	local localPos = self:GetLocalPosition()
    if (not pos and not localPos) then
        SELogger.LogError('SkillClientBullet:Update pos and localPos nil')
		self:DestroyEffect()
        return
    end
	
	local lineDelta = self._bulletSpeed * delta
	local direction = self._targetPosition - pos
	local newPos
	local reached = CS.UnityEngine.Vector3.SqrMagnitude(pos - self._targetPosition) < lineDelta * lineDelta
    -- SELogger.LogError('SkillClientBullet:Update lineDelta %s, timeDelta %s, speed %s', lineDelta, delta, self._bulletSpeed)

	-- 弹道效果按弹道类型处理
	if (self._data.IsBallistic) then
		if (self._projectileType == ProjectileType.Immediate) then
			
			-- 瞬间到达
			newPos = self._targetPosition
			reached = true

		elseif (self._projectileType == ProjectileType.Line) then
			
			-- 直线
			newPos = pos + direction.normalized * lineDelta
		
		elseif (self._projectileType == ProjectileType.HeightFixedParabola) then
			
			-- 定高伪抛物线
			local vDelta = self._verticalSpeed * delta
			self._verticalSpeed = self._verticalSpeed + self._verticalAcc * delta
			local hDelta = self._horizentalSpeed * delta
			direction = self._targetPosition - pos
			newPos = pos + direction.normalized * hDelta + CS.UnityEngine.Vector3.up * vDelta
			
		else

			-- 追踪目标
			local tp = self._targetPosition
			if Utils.IsNotNull(self._targetTrans) then
				direction = self._targetTrans.position - pos
				tp = self._targetTrans.position
			end
			newPos = pos + direction.normalized * lineDelta
			reached = CS.UnityEngine.Vector3.SqrMagnitude(newPos - tp) < lineDelta * lineDelta

		end

		self:SetPosition(newPos)
		self:SetForward(direction)
	else
		reached = true
	end

	-- 抵达目标处理
	if (reached) then

		self:SetPosition(self._targetPosition)
		self:DestroyEffect()
		return
	end
end

function SkillClientBullet:SetLockRotation(rot)
    self._lockRot = rot
end 

return SkillClientBullet
