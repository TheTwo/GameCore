---@sceneName:scene_pet_settlement
local BaseUIMediator = require("BaseUIMediator")
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local PetQuality = require("PetQuality")
local ChatShareType = require("ChatShareType")
local UIMediatorNames = require("UIMediatorNames")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local SetPetIsLockParameter = require("SetPetIsLockParameter")
local HeroUIUtilities = require("HeroUIUtilities")

---@class SEPetSettlementParam
---@field petCompId number	@宠物实例的id
---@field showAsGetPet boolean @是否是作为获得宠物展示
---@field closeCallback fun()
---@field closeCallbackData any
---@field lose boolean
---@field loseReason string
---@field autoClose boolean

---@class SEPetSettlementMediator : BaseUIMediator
local SEPetSettlementMediator = class("SEPetSettlementMediator", BaseUIMediator)

local SP_BASE_QUALITY_PREFIX = "sp_common_base_collect_0"
local SP_BASE_QUALITY_CIRCLE_PREFIX = "sp_common_base_collect_s_0"

local AUTO_CLOSE_TIME = 10
local I18N_AUTO_CLOSE = "se_end_countdown"

local QUALITY_BACKGROUND = {
    "sp_common_base_collect_01",
    "sp_common_base_collect_02",
    "sp_common_base_collect_03",
    "sp_common_base_collect_04",
}

function SEPetSettlementMediator:ctor()
	---@type SEPetSettlementParam
	self._param = nil
	self._autoCloseRemainTime = AUTO_CLOSE_TIME
end

function SEPetSettlementMediator:OnCreate()
	self:InitObjects()
end

function SEPetSettlementMediator:InitObjects()
	self.textContinue = self:Text("p_text_continue_1", "pet_se_result_memo")

	---@type UIPetInfoComponent
	self.petInfoComp = self:LuaObject("child_pet_info")

	self.winNode = self:GameObject("p_win")
	self.imagePet = self:Image("p_img_pet")
	self.imagePetShadow = self:Image("p_img_pet_l")
	self.textWin = self:Text("p_text_win", "pet_se_result_win")
	self.textName = self:Text("p_text_name")
	self.textTime = self:Text("p_text_time", "pet_se_catchnum")
	self.textJudge = self:Text("p_text_arrest", "pet_se_catchevaluate")
	self.textWinItem = self:Text("p_text_win_item", "pet_se_catchitemnum")
	self.iconQuality = self:Image("p_icon_quality")
	self.newPet = self:GameObject("p_new_pet")
	self.newPetText = self:Text("p_text_new_pet", "pet_new")
	self.textQuality = self:Text("p_text_quality")
	self.baseQuality = self:Image("p_base_quality")
	self.baseQualityCircle = self:Image("p_base_quality_circle")
	self.vxTrigger = self:BindComponent("p_vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))

	self.loseNode = self:GameObject("p_lose")
	self.textLose = self:Text("p_text_lose", "pet_se_result_lose")
	self.textReason = self:Text("p_text_reason")
	self.btnLock = self:Button('p_btn_lock', Delegate.GetOrCreate(self, self.OnBtnLockClicked))
    self.goIconLock = self:GameObject('p_icon_lock')
    self.goIconUnlock = self:GameObject('p_icon_unlock')
	self.btnShareS = self:Button('p_btn_share_s', Delegate.GetOrCreate(self, self.OnBtnShareClicked))
    self.btnShare = self:Button('p_btn_share', Delegate.GetOrCreate(self, self.OnBtnShareClicked))
	self.textText = self:Text("p_text", "pet_share_name")
	self.p_text_first = self:Text('p_text_first',"pet_first_acquisition_tips")
	self.p_text_skill_book = self:Text("p_text_skill_book",'pet_skill_acquisition_tips')

	self.p_btn_change_name = self:Button('p_btn_change_name',Delegate.GetOrCreate(self, self.OnPetRenameClick))
	self.p_base = self:Image("p_base")
end

function SEPetSettlementMediator:OnBtnLockClicked(args)
	local params = SetPetIsLockParameter.new()
	params.args.PetCompId = self._param.petCompId
	params.args.Value = not ModuleRefer.PetModule:IsPetLocked(self._param.petCompId)
	params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
		if (suc) then
			self:RefreshLockState(self._param.petCompId)
		end
	end)
end

function SEPetSettlementMediator:RefreshLockState(petId)
	local isLocked = ModuleRefer.PetModule:IsPetLocked(petId)
	self.goIconLock:SetVisible(isLocked)
	self.goIconUnlock:SetVisible(not isLocked)
end

function SEPetSettlementMediator:OnPetRenameClick()
	ModuleRefer.PetModule:RenamePet(self._param.petCompId)
end

function SEPetSettlementMediator:OnBtnShareClicked(args)
	if not self.petCfg then
		return
	end
	local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(self._param.petCompId)
	local pet = ModuleRefer.PetModule:GetPetByID(self._param.petCompId)
	local param = {}
    param.type = ChatShareType.Pet
	param.configID = self.petCfg:Id()
	param.skillLevels = skillLevels
	param.petGeneInfo = pet.PetGeneInfo
	local petCompId = self._param.petCompId
	local petInfo = ModuleRefer.PetModule:GetPetByID(petCompId)
	local templateIds = petInfo.TemplateIds or {}
	local templateLvs = petInfo.TemplateLevels
	local unlockNum = #petInfo.TemplateIds
	if unlockNum > 0 then
		param.x = templateIds[1]
		param.y = templateLvs[1]
	end
	param.z = petInfo.RandomAttrItemCfgId
	g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
	local keyMap = FPXSDKBIDefine.ExtraKey.pet_share
    local extraDic = {}
    extraDic[keyMap.pet_id] = petCompId
	extraDic[keyMap.pet_type] = self.petCfg:Type()
	extraDic[keyMap.pet_cfgId] = self.petCfg:Id()
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.pet_share, extraDic)
end

---@param param SEPetSettlementParam
function SEPetSettlementMediator:OnShow(param)
	g_Game.SoundManager:Play("sfx_ui_get_heropet")
	AUTO_CLOSE_TIME = ConfigRefer.PetConsts.PetSettlementAutoCloseTime and ConfigRefer.PetConsts:PetSettlementAutoCloseTime() or AUTO_CLOSE_TIME
	self._param = param

	if (not self._param.lose) then
		self.winNode:SetActive(true)
		self.loseNode:SetActive(false)

		-- 用于展示宠物的个性化属性
		local petCompId = self._param.petCompId
		local showAsGetPet = self._param.showAsGetPet or false
		local petInfo = ModuleRefer.PetModule:GetPetByID(petCompId)
		if petInfo == nil then
			g_Logger.Error('SEPetSettlementMediator:OnShow petInfo is nil, petCompId %s', petCompId)
			return
		end

		self.petInfoComp:FeedData({
			petId = petCompId,
			petInfo = ModuleRefer.PetModule:GetPetByID(petCompId),
			showAsGetPet = showAsGetPet,
		})
		self:RefreshLockState(petCompId)

		---@type PetConfigCell
		local petCfg = ModuleRefer.PetModule:GetPetCfg(petInfo.ConfigId)
		self.petCfg = petCfg
		if (petCfg) then
			self.textName.text = I18N.Get(petCfg:Name())
			local portrait = petCfg:ShowPortrait()
			self:LoadSprite(portrait, self.imagePet)
			self:LoadSprite(portrait, self.imagePetShadow)
			g_Game.SpriteManager:LoadSprite(SP_BASE_QUALITY_PREFIX .. (petCfg:Quality() + 1), self.baseQuality)
			g_Game.SpriteManager:LoadSprite(SP_BASE_QUALITY_CIRCLE_PREFIX .. (petCfg:Quality() + 1), self.baseQualityCircle)
			g_Game.SpriteManager:LoadSprite(QUALITY_BACKGROUND[petCfg:Quality() + 1], self.p_base)

			self.textQuality.color = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(petCfg:PetColor()):ColorStr())
			local rarityCfg = ConfigRefer.PetRarity:Find(petCfg:Quality())
			if (rarityCfg) then
				self.textQuality.text = I18N.Get(rarityCfg:RarityName())
			else
				self.textQuality.text = "*???"
			end

			local hasPet = ModuleRefer.PetModule:HasPetByCfgId(petInfo.ConfigId)
			if not hasPet then

			end
		end
		self.newPet:SetActive(petInfo.TypeIndex == 1)
		local isShow = petCfg:Quality() >= PetQuality.LV4
		self.btnShare.gameObject:SetActive(isShow)

		if param.showAsGetPet then
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
				self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
				self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6)
			end)
		elseif ModuleRefer.PetModule:IsHighQuality(petInfo.ConfigId) then
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
		else
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
		end

		if (param.autoClose) then
			self._autoCloseRemainTime = AUTO_CLOSE_TIME
			g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.RefreshAutoClose))
			self:RefreshAutoClose()
		end
	else
		self.winNode:SetActive(false)
		self.loseNode:SetActive(true)
		if (self._param.loseReason) then
			self.textReason.text = self._param.loseReason
		end
	end
end

function SEPetSettlementMediator:OnHide(param)
	g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.RefreshAutoClose))

	if (self.petCfg) then
		if ModuleRefer.PetModule:IsHighQuality(self.petCfg:Id()) then
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
		else
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
		end
	end
end

function SEPetSettlementMediator:OnOpened(param)

end

function SEPetSettlementMediator:OnClose(param)
	if (self._param and self._param.closeCallback) then
		self._param.closeCallback(self._param.closeCallbackData)
	end
end

function SEPetSettlementMediator:RefreshAutoClose()
	self.textContinue.text = I18N.GetWithParams(I18N_AUTO_CLOSE, math.floor(self._autoCloseRemainTime))
	self._autoCloseRemainTime = self._autoCloseRemainTime - 1
	if (self._autoCloseRemainTime < 0) then
		self:CloseSelf()
	end
end

return SEPetSettlementMediator
