local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryBehemothCageSubCell:BaseUIComponent
---@field new fun():AllianceTerritoryBehemothCageSubCell
---@field super BaseUIComponent
local AllianceTerritoryBehemothCageSubCell = class('AllianceTerritoryBehemothCageSubCell', BaseUIComponent)

function AllianceTerritoryBehemothCageSubCell:OnCreate(param)
	self._p_icon_boss = self:Image("p_icon_boss")
	self._p_text_name_boss = self:Text("p_text_name_boss")
	self._p_text_lv_boss = self:Text("p_text_lv_boss")
	self._p_btn_click_go = self:Button("p_btn_click_go", Delegate.GetOrCreate(self, self.OnClickGoto))
	self._p_text_position = self:Text("p_text_position")
	self._p_status = self:GameObject("p_status")
	self._p_icon_attack = self:GameObject("p_icon_attack")
	self._p_icon_defence = self:GameObject("p_icon_defence")
	self._p_text_status = self:Text("p_text_status")
	self._p_battle = self:GameObject("p_battle")
	self._p_text_battle = self:Text("p_text_battle", "alliance_behemoth_attend_tip1")
end

---@param data AllianceBehemoth
function AllianceTerritoryBehemothCageSubCell:OnFeedData(data)
	self._data = data
	local current = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
	local level = 1
	if current == data then
		level = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
	end
	local config = data:GetRefKMonsterDataConfig(level)
	g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_boss)
	self._p_text_name_boss.text = I18N.Get(config:Name())
	local x, y = data:GetMapLocation()
	self._p_text_position.text = ("X:%d,Y:%d"):format(math.floor(x+ 0.5), math.floor(y + 0.5))
	self._p_battle:SetVisible(current == data)
	self._p_status:SetVisible(false)
	local cageMonster = ConfigRefer.KmonsterData:Find(data._cageConfig:Monster())
	self._p_text_lv_boss.text = tostring(cageMonster:Level())
end

function AllianceTerritoryBehemothCageSubCell:OnClickGoto()
	self:GetParentBaseUIMediator():CloseSelf()
	local x, y = self._data:GetMapLocation()
    local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    AllianceWarTabHelper.GoToCoord(x, y, true, nil, nil, nil, nil, size, 0)
end

return AllianceTerritoryBehemothCageSubCell
