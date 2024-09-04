
local Behavior = require("Behavior")
local SkillClientGen = require("SkillClientGen")
local SkillClientEnum = require("SkillClientEnum")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Utils = require("Utils")
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper

---@class Alert:Behavior
---@field super Behavior
local Alert = class("Alert", Behavior)

---@param self Alert
---@param ... any
---@return void
function Alert:ctor(...)
    Alert.super.ctor(self, ...)

    ---@type skillclient.data.Alert
    self._dataAlert = self._data
    self._effect = nil
    self._createHelper = PooledGameObjectCreateHelper.Create("SkillClientAlert")
end

---@param self Alert
---@return void
function Alert:OnStart()
    local data = self._dataAlert
    local type = data.Shape
	local sceneRoot = require("SESceneRoot").GetSceneRoot()
    if (type == SkillClientGen.Shape.Round) then
		self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_circle), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
	elseif (type == SkillClientGen.Shape.Rectangle) then
		self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_rectangle), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
	else
		if (data.Angle == SkillClientGen.FanAngle._45) then
			self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_sector45), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
		elseif (data.Angle == SkillClientGen.FanAngle._90) then
			self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_sector90), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
		elseif (data.Angle == SkillClientGen.FanAngle._135) then
			self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_sector135), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
		else
			self._effect = self._createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.se_alert_sector180), sceneRoot, Delegate.GetOrCreate(self, self.InitAlertRange))
		end
    end
end

function Aler:InitAlertRange()
	if (Utils.IsNull(self._effect)) then return end

	if (self._dataAlert.Shape == SkillClientGen.Shape.Rectangle) then
		self._effect.transform.localScale = CS.UnityEngine.Vector3(self._dataAlert.Width, 1, self._dataAlert.Length)
	else
		self._effect.transform.localScale = CS.UnityEngine.Vector3.one * self._dataAlert.Length
	end

	---@type CS.AlertRange
	local alertRange = self._effect:GetComponent(typeof(CS.AlertRange))
	if (alertRange) then
		alertRange:SetTime(self._dataAlert.Time)
	end
end

---@param self Alert
---@return void
function Alert:OnUpdate()
    if self._effect and self._skillTarget:HasCtrlAndDead() then
        self._effect:Delete()
        self._effect = nil
    end
end

---@param self Alert
---@return void
function Alert:OnEnd()
    if self._effect then
        self._effect:Delete()
        self._effect = nil
    end
end

return Alert
