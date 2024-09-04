---
--- Created by hao.wu.ss. DateTime: 2023/3/30
---
---
local BuffBehavior = require("BuffBehavior")
local Utils = require("Utils")

---@class BuffNodeVisible:BuffBehavior
local BuffNodeVisible = class("BuffNodeVisible", BuffBehavior)


---@param self BuffNodeVisible
---@param ... any
---@return void
function BuffNodeVisible:ctor(...)
    BuffNodeVisible.super.ctor(self, ...)

    ---@type buffclient.data.NodeVisible
    self._buffData = self._data
	self._orgVisible = false
end

---@param self BuffNodeVisible
---@return void
function BuffNodeVisible:OnStart()
	self:DoInternalStart()
end

function BuffNodeVisible:OnCtrlValid()
    self:DoInternalStart()
end

function BuffNodeVisible:DoInternalStart()
	local trans = self._target:GetFbxTransform()
	if Utils.IsNull(trans) then return end
	local node = trans:FirstOrDefaultByName(self._buffData.NodeName)
	if (Utils.IsNotNull(node)) then
		self._orgVisible = node.gameObject.activeSelf
		if (self._orgVisible ~= self._buffData.Visible) then
			node.gameObject:SetActive(self._buffData.Visible)
		end
	end
end

---@param self BuffNodeVisible
---@return void
function BuffNodeVisible:OnEnd()
	if (self._buffData.RestoreOnEnd) then
		local trans = self._target:GetFbxTransform()
		if Utils.IsNull(trans) then return end
		local node = trans:FirstOrDefaultByName(self._buffData.NodeName)
		if (Utils.IsNotNull(node)) then
			node.gameObject:SetActive(self._orgVisible)
		end
	end
end

return BuffNodeVisible
