local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainSummaryBehemothCageSubCell:BaseUIComponent
---@field new fun():AllianceTerritoryMainSummaryBehemothCageSubCell
---@field super BaseUIComponent
local AllianceTerritoryMainSummaryBehemothCageSubCell = class('AllianceTerritoryMainSummaryBehemothCageSubCell', BaseUIComponent)

function AllianceTerritoryMainSummaryBehemothCageSubCell:OnCreate(param)
	self._status = self:StatusRecordParent("")
	self._p_icon_boss = self:Image("p_icon_boss")
	self._p_text_name_boss = self:Text("p_text_name_boss")
	self._p_text = self:Text("p_text")
end

---@param data AllianceBehemoth
function AllianceTerritoryMainSummaryBehemothCageSubCell:OnFeedData(data)
	local config = ConfigRefer.KmonsterData:Find(data._cageConfig:Monster())
	g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_boss)
	self._p_text_name_boss.text = I18N.Get(config:Name())
	if data:IsFake() then
		local unlock, unlockConfig = ModuleRefer.AllianceModule.Behemoth:IsBehemothUnLocked(data)
		if unlock then
			self._status:SetState(1)
		else
			self._status:SetState(2)
			self._p_text.text = ModuleRefer.AllianceModule.Behemoth:GetBehemothUnLockedTips(unlockConfig:Id())
		end
	else
		self._p_text_name_boss.text = I18N.Get(config:Name())
		self._status:SetState(0)
	end
end

return AllianceTerritoryMainSummaryBehemothCageSubCell
