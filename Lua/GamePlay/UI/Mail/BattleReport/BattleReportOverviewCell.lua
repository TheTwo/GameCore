local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require("Delegate")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local ObjectType = require("ObjectType")
local I18N = require("I18N")
local SceneType = require("SceneType")
local UIMediatorNames = require("UIMediatorNames")
local KingdomMapUtils = require("KingdomMapUtils")
local NumberFormatter = require("NumberFormatter")
local MailUtils = require("MailUtils")

---@class BattleReportOverviewCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local BattleReportOverviewCell = class('BattleReportOverviewCell', BaseTableViewProCell)

---@class BattleReportOverviewCellData
---@field result number
---@field attacker wds.BattleReportUnitBasic
---@field target wds.BattleReportUnitBasic
---@field sceneType number
---@field titleImageSp string
---@field titleTimeStr string
---@field showHp boolean|nil

function BattleReportOverviewCell:ctor()
	BattleReportOverviewCell.super.ctor(self)
    self._attackerX = 0
	self._attackerY = 0
	self._targetX = 0
	self._targetY = 0
	self._sceneType = SceneType.None
end

function BattleReportOverviewCell:OnCreate(param)
	
	-- 胜负图标
	self.titleImage = self:Image("p_base_title")
	self.titleTime = self:Text("p_text_time")

	self.victoryNode = self:GameObject("p_status_victory")
	self.defeatNode = self:GameObject("p_status_defeat")
	self.escapeNode = self:GameObject("p_status_escape")
	self.victoryText = self:Text("p_text_status_victory", ModuleRefer.MailModule:GetBattleReportVictoryText())
	self.defeatText = self:Text("p_text_status_defeat", ModuleRefer.MailModule:GetBattleReportDefeatText())


	-- 玩家侧
	---@type PlayerInfoComponent
	self.playerInfoComp = self:LuaObject("p_player_head_comp_l")
    self.playerNameText = self:Text("p_text_name_player")
	self.playerPosText = self:Text("p_text_position_player")
	self.playerPosButton = self:Button("p_btn_position_player", Delegate.GetOrCreate(self, self.OnPlayerPosTextClick))
	self.playerPower = self:Text("p_text_score_player")
	self.playerPowerRoot = self:GameObject("p_power_1")
	self.playerCurHp = self:Slider("p_progress_power_player")
	self.playerOrgHp = self:Image("p_progress_view_player")
	self.playerHpText = self:Text("p_text_power_player")
	self.playerHpLossText = self:Text("p_text_power_loss_player")
	self.playerHpRoot = self:GameObject("p_hp")

	-- 目标侧
	---@type PlayerInfoComponent
	self.targetPlayerInfoComp = self:LuaObject("p_player_head_comp_r")
	self.targetNameText = self:Text("p_text_name_boss")
	self.targetPosText = self:Text("p_text_position_enemy")
	self.TargetPosButton = self:Button("p_btn_position_enemy", Delegate.GetOrCreate(self, self.OnTargetPosTextClick))
	self.targetPower = self:Text("p_text_score_boss")
	self.targetPowerRoot = self:GameObject("p_power_2")
	self.targetCurHp = self:Slider("p_progress_power_boss")
	self.targetOrgHp = self:Image("p_progress_view_boss")
	self.targetHpText = self:Text("p_text_power_boss")
	self.targetHpLossText = self:Text("p_text_power_loss_boss")
	self.targetHpLossText2 = self:Text("p_text_power_loss_boss_2")
	self.targetHpRoot = self:GameObject("p_hp_enemy")

	self.targetBossNode = self:GameObject("p_head_boss")
	self.targetBossImg = self:Image("p_img_head_boss")
	self.targetPlayerNode = self:GameObject("p_head_player_r")
	self.targetConstructionNode = self:GameObject("p_head_construction")
	self.targetConstructionImage = self:Image("p_img_construction")
end

---@param data BattleReportOverviewCellData
function BattleReportOverviewCell:OnFeedData(data)
	self._sceneType = data.sceneType
	self:RefreshUI(data)
end

---@param data BattleReportOverviewCellData
function BattleReportOverviewCell:RefreshUI(data)
	g_Game.SpriteManager:LoadSprite(data.titleImageSp, self.titleImage)

	if Utils.IsNotNull(self.titleTime) then
		self.titleTime.text = data.titleTimeStr
	end

	-- 胜负
	if (data.result == wds.BattleResult.BattleResult_Win) then
		self.victoryNode:SetActive(true)
		self.defeatNode:SetActive(false)
		self.escapeNode:SetActive(false)
	elseif (data.result == wds.BattleResult.BattleResult_Loss) then
		self.victoryNode:SetActive(false)
		self.defeatNode:SetActive(true)
		self.escapeNode:SetActive(false)
	else
		self.victoryNode:SetActive(false)
		self.defeatNode:SetActive(false)
		self.escapeNode:SetActive(true)
	end

	local attackerInfo = data.attacker
	local targetInfo = data.target

	if data.showHp then
		self.playerHpRoot:SetActive(true)
		self.targetHpRoot:SetActive(true)
	else
		self.playerHpRoot:SetActive(false)
		self.targetHpRoot:SetActive(false)
	end

	if self.targetHpLossText2 then
		self.targetHpLossText2:SetVisible(false)
	end

	self.playerInfoComp:FeedData(attackerInfo.PortraitInfo)
	self.playerNameText.text = MailUtils.MakePlayerName(attackerInfo.AllianceName, attackerInfo.Name)

	self._attackerX = attackerInfo.Pos.X
	self._attackerY = attackerInfo.Pos.Y
	if Utils.IsNotNull(self.playerPosText) then
		self.playerPosText.text = self:GetLocationStr(attackerInfo.Pos)
	end

	self.playerCurHp.value = math.clamp01(attackerInfo.CurHp / attackerInfo.MaxHp)
	self.playerOrgHp.fillAmount = math.clamp01(attackerInfo.OriHp / attackerInfo.MaxHp)
	self.playerHpText.text = self:GetHpStr(attackerInfo)
	self.playerHpLossText.text = math.floor(attackerInfo.CurHp - attackerInfo.OriHp)
	self.playerPower.text = NumberFormatter.Normal(attackerInfo.Power)
	self.playerPowerRoot:SetActive(attackerInfo.Power > 0)

	-- 怪物
	if (targetInfo.ObjectType == ObjectType.SlgMob) then
		self.targetBossNode:SetActive(true)
		self.targetPlayerNode:SetActive(false)
		self.targetConstructionNode:SetActive(false)

		local name, icon, level, monsterCfg = MailUtils.GetMonsterNameIconLevel(targetInfo.ConfId)
		self.targetNameText.text = "Lv." .. level .. " " .. name
		g_Game.SpriteManager:LoadSprite(icon, self.targetBossImg)

		if data.showHp and monsterCfg and monsterCfg:IsStake() then
			if self.targetHpLossText2 then
				self.targetHpLossText2:SetVisible(true)
				self.targetHpLossText2.text = I18N.GetWithParams("alliance_activity_coordination1", targetInfo.TakeDamage)
			end
			self.targetHpRoot:SetActive(false)
		end
	-- 建筑
	elseif targetInfo.ObjectType == ObjectType.SlgVillage or 
		targetInfo.ObjectType == ObjectType.Pass or 
		targetInfo.ObjectType == ObjectType.SlgCommonBuilding or 
		targetInfo.ObjectType == ObjectType.SlgResource or 
		targetInfo.ObjectType == ObjectType.SlgEnergyTower or 
		targetInfo.ObjectType == ObjectType.SlgTransferTower or 
		targetInfo.ObjectType == ObjectType.SlgDefenceTower or 
		targetInfo.ObjectType == ObjectType.SlgMobileFortress
	then
		self.targetBossNode:SetActive(false)
		self.targetPlayerNode:SetActive(false)
		self.targetConstructionNode:SetActive(true)

		local name, icon, level = MailUtils.GetMapBuildingNameIconLevel(targetInfo.ConfId)
		self.targetNameText.text = "Lv." .. level .. " " .. name
		g_Game.SpriteManager:LoadSprite(icon, self.targetConstructionImage)
	-- 打主堡
	elseif targetInfo.ObjectType == ObjectType.SlgCastle then
		self.targetBossNode:SetActive(false)
		self.targetPlayerNode:SetActive(true)
		self.targetConstructionNode:SetActive(false)

		self.targetPlayerInfoComp:FeedData(targetInfo.PortraitInfo)
		self.targetNameText.text = MailUtils.MakePlayerName(targetInfo.AllianceName, targetInfo.Name)
	-- 部队
	else
		self.targetBossNode:SetActive(false)
		self.targetPlayerNode:SetActive(true)
		self.targetConstructionNode:SetActive(false)

		self.targetPlayerInfoComp:FeedData(targetInfo.PortraitInfo)
		self.targetNameText.text = MailUtils.MakePlayerName(targetInfo.AllianceName, targetInfo.Name)
	end

	self._targetX = targetInfo.Pos.X
	self._targetY = targetInfo.Pos.Y
	if Utils.IsNotNull(self.targetPosText) then
		self.targetPosText.text = self:GetLocationStr(targetInfo.Pos)
	end

	self.targetHpRoot:SetActive(data.showHp and targetInfo.MaxHp > 0)
	self.targetCurHp.value = math.clamp01(targetInfo.CurHp / targetInfo.MaxHp)
	self.targetOrgHp.fillAmount = math.clamp01(targetInfo.OriHp / targetInfo.MaxHp)
	self.targetHpText.text = self:GetHpStr(targetInfo)
	self.targetHpLossText.text = math.floor(targetInfo.CurHp - targetInfo.OriHp)
	self.targetPower.text = NumberFormatter.Normal(targetInfo.Power)
	self.targetPowerRoot:SetActive(targetInfo.Power > 0)
end

---@param self BattleReportOverviewCell
---@param pos wds.Vector3F
function BattleReportOverviewCell:GetLocationStr(pos)
	return "X:" .. math.floor(pos.X) .. " Y:" .. math.floor(pos.Y)
end

---@param self BattleReportOverviewCell
---@param info wds.BattleReportUnitBasic
function BattleReportOverviewCell:GetHpStr(info)
	return math.floor(info.CurHp) .. "/" .. math.floor(info.MaxHp)
end

function BattleReportOverviewCell:OnPlayerPosTextClick(text)
	if (self._attackerX and self._attackerY) then
		self:GotoPos(self._attackerX, self._attackerY, self._sceneType)
	end
end

function BattleReportOverviewCell:OnTargetPosTextClick(text)
	if (self._targetX and self._targetY) then
		self:GotoPos(self._targetX, self._targetY, self._sceneType)
	end
end

--- 坐标跳转
---@param self BattleReportOverviewCell
---@param x number
---@param y number
---@param sceneType number
function BattleReportOverviewCell:GotoPos(x, y, sceneType)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.UIMailMediator)
    KingdomMapUtils.GotoCoordinate(x, y, sceneType)
end

return BattleReportOverviewCell;
