local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local HeroUIUtilities = require("HeroUIUtilities")
local I18N = require("I18N")
local Utils = require("Utils")
local NM = ModuleRefer.NotificationModule

---@class UITroopCellPvpTemp : BaseTableViewProCell
local UITroopCellPvpTemp = class('UITroopCellPvpTemp', BaseTableViewProCell)

local I18N_TROOP_INDICES = {
	[1] = "NewFormation_FormationNum1",
	[2] = "NewFormation_FormationNum2",
	[3] = "NewFormation_FormationNum3",
}

---@class UITroopCellPvpTempData
---@field index number
---@field troopPreset wds.TroopPreset
---@field selected boolean
---@field isEmpty boolean
---@field isLocked boolean
---@field leaderHeroId number
---@field linkedPetId number
---@field onClick fun(index: number)
---@field bindRedDot boolean
---@field redDot CS.Notification.NotificationDynamicNode

local STATUS_EMPTY = 0
local STATUS_NORMAL = 1
local STATUS_LOCKED = 2

function UITroopCellPvpTemp:ctor()
	self._playSelectedAnim = false
end

function UITroopCellPvpTemp:OnCreate()
	self.statusRecord = self:StatusRecordParent("")
	self.selected = self:GameObject("p_img_select")
	self.selectedAnim = self:BindComponent("p_img_select", typeof(CS.UnityEngine.Animation))
	self.emptyNode = self:GameObject("p_status_empty")
	self.nonEmptyNode = self:GameObject("p_status_n")
	---@type HeroInfoItemComponent
	self.heroComp = self:LuaObject("child_card_hero_s_ex")
	self.statusFrame = self:Image("p_troop_status")
	self.statusIcon = self:Image("p_icon_status")
	self.lockNode = self:GameObject("p_lock")
	self.goTroop = self:GameObject('troop')
	self.troopIndexText = self:Text("p_text_num")
	self.button = self:Button("p_btn_tab", Delegate.GetOrCreate(self, self.OnButtonClicked))
	---@type NotificationNode
	self.redDot = self:LuaObject("child_reddot_default")

	---@type CommonPetIcon
	self.luaPetCard = self:LuaObject("child_card_pet_s")

	self.goAdd = self:GameObject("p_add")
end


function UITroopCellPvpTemp:OnShow(param)
	if (self._playSelectedAnim) and Utils.IsNotNull(self.selectedAnim) then
		self.selectedAnim:Play()
		self._playSelectedAnim = false
	end
end

function UITroopCellPvpTemp:OnOpened(param)
end

function UITroopCellPvpTemp:OnClose(param)
end

---@param data UITroopCellPvpTempData
function UITroopCellPvpTemp:OnFeedData(data)
	if (data) then
		self.data = data
		self.index = data.index
		---@type wds.TroopPreset
		self.troopPreset = data.troopPreset
		self.onClick = data.onClick
		self.isSelected = data.selected
		self.leaderHeroId = data.leaderHeroId
		if (not self.selected.activeSelf and data.selected) then
			self._playSelectedAnim = true
		end
		self.selected:SetActive(data.selected)
		if data.selected then
			self:SelectSelf()
		end
		if (data.isLocked) then
			if (self.statusRecord.EditCurIndex ~= STATUS_LOCKED) then
				self.statusRecord:ApplyStatusRecord(STATUS_LOCKED)
			end
			if Utils.IsNotNull(self.redDot) then
				self.redDot.go:SetActive(false)
			end
		else
			if (data.isEmpty) then
				if (self.statusRecord.EditCurIndex ~= STATUS_EMPTY) then
					self.statusRecord:ApplyStatusRecord(STATUS_EMPTY)
				end
			else
				if (self.statusRecord.EditCurIndex ~= STATUS_NORMAL) then
					self.statusRecord:ApplyStatusRecord(STATUS_NORMAL)
				end
				self:RefreshData()
			end
			if (data.bindRedDot and data.redDot) then
				if Utils.IsNotNull(self.redDot) then
					self.redDot.go:SetActive(true)
					NM:AttachToGameObject(data.redDot, self.redDot.go)
				end
			else
				if Utils.IsNotNull(self.redDot) then
					self.redDot.go:SetActive(false)
				end
			end
		end
		if data.hideText then
			if Utils.IsNotNull(self.redDot) then
				self.goTroop:SetActive(false)
			end
		else
			if Utils.IsNotNull(self.redDot) then
				self.goTroop:SetActive(true)
				self.troopIndexText.text = tostring(self.index) -- I18N.Get(I18N_TROOP_INDICES[self.index])
			end
		end
	end
end

function UITroopCellPvpTemp:Select(param)
	if (self.onClick) then
		self.onClick(self.index)
	end
	self.selected:SetActive(true)
end

function UITroopCellPvpTemp:UnSelect(param)
	self.selected:SetActive(false)
end

function UITroopCellPvpTemp:OnButtonClicked()
	self:SelectSelf()
end

function UITroopCellPvpTemp:RefreshData()
	local leaderHeroId = self.leaderHeroId
	local petId = self.data.linkedPetId
	if (not leaderHeroId or leaderHeroId <= 0) then
		if self.troopPreset then
			for _, item in ipairs(self.troopPreset.Heroes) do
				if (item.HeroCfgID and item.HeroCfgID > 0) then
					leaderHeroId = item.HeroCfgID
					petId = item.PetCompId
					break
				end
			end
		end
	end
	if (leaderHeroId and leaderHeroId > 0) then
		self.heroComp:FeedData({heroData = ModuleRefer.HeroModule:GetHeroByCfgId(leaderHeroId), hideLv = self.data.hideLv, hideJobIcon = not self.data.showJob})
	end
	if self.luaPetCard then
		if (petId and petId > 0) then
			self.luaPetCard:SetVisible(true)
			-- self.goAdd:SetActive(false)
			self.luaPetCard:FeedData({id = petId})
		else
			-- self.goAdd:SetActive(true)
			self.luaPetCard:SetVisible(false)
		end
	end
	if (not self.troopPreset or self.troopPreset.Status == wds.TroopPresetStatus.TroopPresetIdle) then
		self.statusFrame.gameObject:SetActive(false)
		self.statusIcon.gameObject:SetActive(false)
	else
		self.statusFrame.gameObject:SetActive(true)
		self.statusIcon.gameObject:SetActive(true)
		local troops = ModuleRefer.SlgModule:GetMyTroops()
		local troop = troops and troops[self.index]
		local spIcon, spFrame = HeroUIUtilities.MyTroopStateIconByTroopAndPreset(troop.entityData, self.troopPreset)
		if (troop and troop.entityData) then
			g_Game.SpriteManager:LoadSprite(spIcon, self.statusIcon)
			g_Game.SpriteManager:LoadSprite(spFrame, self.statusFrame)
		elseif self.troopPreset then
			g_Game.SpriteManager:LoadSprite(spIcon, self.statusIcon)
			g_Game.SpriteManager:LoadSprite(spFrame, self.statusFrame)
		else
			self.statusFrame.gameObject:SetActive(false)
			self.statusIcon.gameObject:SetActive(false)
		end
	end
end

return UITroopCellPvpTemp
