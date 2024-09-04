local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local NotificationType = require("NotificationType")
local Utils = require("Utils")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")

---@class UIPlayerHomepageMediator : BaseUIMediator
local UIPlayerHomepageMediator = class('UIPlayerHomepageMediator', BaseUIMediator)

local I18N_SEEYA = "playerinfo_tbc"

function UIPlayerHomepageMediator:ctor()

end

function UIPlayerHomepageMediator:OnCreate()
    self:InitObjects()
end

function UIPlayerHomepageMediator:InitObjects()
	--self.portraitImage = self:Image("p_btn_change_head")
	--self.portraitChangeButton = self:Button("p_btn_change_head", Delegate.GetOrCreate(self, self.OnPortraitChangeButtonClick))
	---@type PlayerInfoComponent
	self.portraitImage = self:LuaObject("child_ui_head_player")
	self.child_reddot_head_change = self:LuaObject('child_reddot_head_change')
	self.nameText = self:Text("p_text_name")
	self.nameChangeButton = self:Button("p_btn_change_name", Delegate.GetOrCreate(self, self.OnNameChangeButtonClick))
	self.idLabel = self:Text("p_text_id", "playerinfo_id")
	self.idText = self:Text("p_text_id_detail")
	self.idCopyButton = self:Button("p_icon_copy", Delegate.GetOrCreate(self, self.OnIdCopyButtonClick))
	self.areaLabel = self:Text("p_text_area", "playerinfo_warzone")
	self.areaText = self:Text("p_text_area_detail")
	self.allianceLabel = self:Text("p_text_league", "playerinfo_crew")
	self.allianceText = self:Text("p_text_league_detail")
	self.signatureChangeButton = self:Button("p_btn_say", Delegate.GetOrCreate(self, self.OnSignatureChangeButtonClick))
	self.signatureText = self:Text("p_text_say")
	self.levelText = self:Text("p_text_lv")
	self.levelTextLabel = self:Text("p_text_lv_1", "playerinfo_level_txt")
	self.levelLabel = self:Text("p_text_player_lv", "playerinfo_level")
	self.levelProgressText = self:Text("p_text_lv_number")
	self.levelProgressSlider = self:Slider("p_progress_lv")
	self.expAddButton = self:Button("p_btn_lv", Delegate.GetOrCreate(self, self.OnExpAddButtonClick))
	-- self.detailButton = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnDetailButtonClick))
	-- self.detailLabel = self:Text("p_text_detail", "playerinfo_info")
	self.personaliseButton = self:Button("p_btn_personalise", Delegate.GetOrCreate(self, self.OnPersonaliseButtonClick))
	self.personaliseLabel = self:Text("p_text_personalise", "skincollection_system")
	self.accountButton = self:Button('p_btn_account', Delegate.GetOrCreate(self, self.OnAccountButtonClick))
	self.accountLabel = self:Text('p_text_account', 'playerinfo_account_button')
	self.achievementButton = self:Button("p_btn_achievement", Delegate.GetOrCreate(self, self.OnAchievementButtonClick))
	self.achievementLabel = self:Text("p_text_achievement", "playerinfo_achievement")
	self.ladderButton = self:Button("p_btn_list", Delegate.GetOrCreate(self, self.OnLadderButtonClick))
	self.ladderLabel = self:Text("p_text_list", "playerinfo_rank")
	self.settingButton = self:Button("p_btn_set", Delegate.GetOrCreate(self, self.OnSettingButtonClick))
	self.settingLabel = self:Text("p_text_set", "playerinfo_settings")
	self.serviceButton = self:Button("p_btn_service", Delegate.GetOrCreate(self, self.OnServiceButtonClick))
	self.serviceLabel = self:Text("p_text_service", "playerinfo_contact")
	self.closeButton = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseButtonClick))
	self.powerText = self:Text("p_text_power_number")

	self.btnEnergy = self:Button('p_btn_energy', Delegate.GetOrCreate(self, self.OnBtnEnergyClicked))
    self.sliderProgressEnergy = self:Slider('p_progress_energy')
    self.textEnergyNumber = self:Text('p_text_energy_number')
    self.btnEnergyAdd = self:Button('p_btn_energy_add', Delegate.GetOrCreate(self, self.OnBtnEnergyAddClicked))

	---@type NotificationNode
	self.child_reddot_leaderboard = self:LuaObject('child_reddot_leaderboard')
	self.child_reddot_leaderboard:SetVisible(true)
	ModuleRefer.LeaderboardModule:AttachLeaderboardEntryRedDot(self.child_reddot_leaderboard.CSComponent.gameObject)
	ModuleRefer.LeaderboardModule:UpdateDailyRewardState()

	self.child_reddot_personalise = self:LuaObject('child_reddot_personalise')
end

function UIPlayerHomepageMediator:OnShow(param)
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPortraitChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.Name.MsgPath, Delegate.GetOrCreate(self, self.OnNameChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.Notice.MsgPath, Delegate.GetOrCreate(self, self.OnSignatureChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.CommanderExp.MsgPath, Delegate.GetOrCreate(self, self.OnLevelExpChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.CommanderLevel.MsgPath, Delegate.GetOrCreate(self, self.OnLevelExpChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath,Delegate.GetOrCreate(self,self.RefreshEnergy))
    self:RefreshUI()
	if ModuleRefer.PersonaliseModule:CheckIsPersonaliseOpen() then
		self.child_reddot_personalise:SetVisible(true)
		self.child_reddot_personalise:ShowRedDot()
	else
		ModuleRefer.PersonaliseModule:RefreshRedPoint()
	end
	if ModuleRefer.PersonaliseModule:CheckIsHeadChangeOpen() then
		self.child_reddot_head_change:SetVisible(true)
		self.child_reddot_head_change:ShowRedDot()
	end
end

function UIPlayerHomepageMediator:OnHide(param)
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath,Delegate.GetOrCreate(self,self.RefreshEnergy))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPortraitChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.Name.MsgPath, Delegate.GetOrCreate(self, self.OnNameChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.Notice.MsgPath, Delegate.GetOrCreate(self, self.OnSignatureChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.CommanderExp.MsgPath, Delegate.GetOrCreate(self, self.OnLevelExpChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.CommanderLevel.MsgPath, Delegate.GetOrCreate(self, self.OnLevelExpChange))
end

function UIPlayerHomepageMediator:OnOpened(param)
	self.portraitImage:FeedData(ModuleRefer.PlayerModule:GetPlayer().Basics.PortraitInfo)
	self.portraitImage:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnPortraitChangeButtonClick))
	
	self.child_reddot_personalise:SetVisible(true)
	local redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseBtnNode", NotificationType.PERSONALISE)
	ModuleRefer.NotificationModule:AttachToGameObject(redNode, self.child_reddot_personalise.go, self.child_reddot_personalise.redDot)

end

function UIPlayerHomepageMediator:OnClose(param)
end

function UIPlayerHomepageMediator:OnBtnEnergyClicked(args)
	local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
    local isMax = curEnery >= maxEnergy
	local text = I18N.GetWithParams("energy_tips_1", string.format("%d", ConfigRefer.ConstMain:PPPIncInterval() / 60))
	local maxTimeStamp = nil
    if not isMax then
		local lackNum = maxEnergy - curEnery
		local costSeconds = math.ceil(lackNum / ConfigRefer.ConstMain:PPPIncNum()) * ConfigRefer.ConstMain:PPPIncInterval()
		maxTimeStamp = costSeconds + radarInfo.LastAddTime.timeSeconds
	end
	ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnEnergy.transform, content = text, timeStamp = maxTimeStamp, timeText = "energy_tips_2", tailContent = I18N.Get("energy_tips_3")})
end

function UIPlayerHomepageMediator:OnBtnEnergyAddClicked(args)
	local provider = require("EnergyGetMoreDataProvider").new()
	provider:SetItemList({ConfigRefer.ConstMain:AddenergyItemId()})
	g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function UIPlayerHomepageMediator:RefreshEnergy()
	local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
	self.sliderProgressEnergy.value = curEnery / maxEnergy
	self.textEnergyNumber.text = curEnery .. "/" .. maxEnergy
end

function UIPlayerHomepageMediator:RefreshUI()
	self:RefreshPortrait()
	self:RefreshName()
	self:RefreshSignature()
	self:RefreshLevelExp()
	self:RefreshEnergy()
	local player = ModuleRefer.PlayerModule:GetPlayer()

	--self.idText.text = ModuleRefer.PlayerModule:GetAccountId()
	self.idText.text = tostring(ModuleRefer.PlayerModule:GetPlayerId())
	self.areaText.text = "#" .. tostring(player.Basics.DistrictId)
	if (player.Owner.AllianceID > 0) then
		self.allianceText.text = player.Owner.AllianceName.String
	else
		self.allianceText.text = "-"
	end
	self.powerText.text = CS.System.String.Format("{0:#,0}", player.PlayerWrapper2.PlayerPower.TotalPower)
end

function UIPlayerHomepageMediator:OnPortraitChangeButtonClick()
	local sysIndex = NewFunctionUnlockIdDefine.Head_Change
	if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex) then
		ModuleRefer.ToastModule:AddSimpleToast(ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(sysIndex))
		return
	end
	if ModuleRefer.PersonaliseModule:CheckIsHeadChangeOpen() then
		ModuleRefer.PersonaliseModule:ResetHeadChangeOpenFlag()
		self.child_reddot_head_change:SetVisible(false)
	end
	g_Game.UIManager:Open(UIMediatorNames.UIPlayerPortraitSelectMediator)
end

function UIPlayerHomepageMediator:OnNameChangeButtonClick()
	g_Game.UIManager:Open(UIMediatorNames.UIPlayerChangeNameMediator, { changeName = true })
end

function UIPlayerHomepageMediator:OnIdCopyButtonClick()
	Utils.CopyToClipboard(tostring(ModuleRefer.PlayerModule:GetPlayerId()))
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("playerinfo_copyid"))
end

function UIPlayerHomepageMediator:OnSignatureChangeButtonClick()
	g_Game.UIManager:Open(UIMediatorNames.UIPlayerChangeNameMediator, { changeName = false })
end

function UIPlayerHomepageMediator:OnExpAddButtonClick()
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = self.expAddButton.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.Get("playerinfo_exp_getmore_txt")
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

function UIPlayerHomepageMediator:OnDetailButtonClick()
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(I18N_SEEYA))
end

function UIPlayerHomepageMediator:OnPersonaliseButtonClick()
	local sysIndex = NewFunctionUnlockIdDefine.Personalise
	if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex) then
		ModuleRefer.ToastModule:AddSimpleToast(ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(sysIndex))
		return
	end
	if ModuleRefer.PersonaliseModule:CheckIsPersonaliseOpen() then
		ModuleRefer.PersonaliseModule:ResetPersonaliseOpenFlag()
		self.child_reddot_personalise:SetVisible(false)
	end
	g_Game.UIManager:Open(UIMediatorNames.UIPlayerPersonaliseMediator)
end

function UIPlayerHomepageMediator:OnAccountButtonClick()
	if ModuleRefer.FPXSDKModule:HasUserCenter() then
		ModuleRefer.FPXSDKModule:OpenUserCenter()
	else
		-- 没有用户中心功能的，暂定打开某个配置的网址
		CS.UnityEngine.Application.OpenURL('https://www.funplus.com')
	end
end

function UIPlayerHomepageMediator:OnAchievementButtonClick()
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(I18N_SEEYA))
end

function UIPlayerHomepageMediator:OnLadderButtonClick()
	if ModuleRefer.LeaderboardModule:IsLeadboardUnlock() then
		g_Game.UIManager:Open(UIMediatorNames.LeaderboardUIMediator)
		return
	end

	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('leaderboard_info_1'))
end

function UIPlayerHomepageMediator:OnSettingButtonClick()
	g_Game.UIManager:Open(UIMediatorNames.UISettingsMediator)
end

function UIPlayerHomepageMediator:OnServiceButtonClick()
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(I18N_SEEYA))
end

function UIPlayerHomepageMediator:OnPortraitChange()
	self:RefreshPortrait()
end

function UIPlayerHomepageMediator:RefreshPortrait()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	--g_Game.SpriteManager:LoadSprite(require("CommonPlayerDefine").HEAD_ICONS[player.Basics.Portrait], self.portraitImage)
	-- g_Game.SpriteManager:LoadSprite(ModuleRefer.PlayerModule:GetSelfPortraitSpriteName(), self.portraitImage)
	self.portraitImage:FeedData(player.Basics.PortraitInfo)
end

function UIPlayerHomepageMediator:OnCloseButtonClick()
	self:CloseSelf()
end

function UIPlayerHomepageMediator:OnNameChange()
	self:RefreshName()
end

function UIPlayerHomepageMediator:OnSignatureChange()
	self:RefreshSignature()
end

function UIPlayerHomepageMediator:OnLevelExpChange()
	self:RefreshLevelExp()
end

function UIPlayerHomepageMediator:RefreshName()
	self.nameText.text = ModuleRefer.PlayerModule:GetPlayer().Basics.Name
end

function UIPlayerHomepageMediator:RefreshSignature()
	self.signatureText.text = ModuleRefer.PlayerModule:GetPlayer().Basics.Notice
end

function UIPlayerHomepageMediator:RefreshLevelExp()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	self.levelText.text = tostring(player.Basics.CommanderLevel)
	local minExp = ModuleRefer.PlayerModule:GetMinExpByLevel(player.Basics.CommanderLevel)
	local nextExp = ModuleRefer.PlayerModule:GetMinExpByLevel(player.Basics.CommanderLevel + 1)
	if (player.Basics.CommanderLevel >= ModuleRefer.PlayerModule:GetMaxLevel()) then
		self.expAddButton.gameObject:SetActive(false)
		self.levelProgressText.text = I18N.Get("playerinfo_levelmax")
	else
		self.expAddButton.gameObject:SetActive(true)
		local exp = player.Basics.CommanderExp
		self.levelProgressText.text = tostring(exp) .. "/" .. tostring(nextExp)
		local prg = (exp - minExp) / (nextExp - minExp)
		self.levelProgressSlider.value = prg
	end
end

return UIPlayerHomepageMediator
