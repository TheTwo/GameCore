local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local ChatShareType = require("ChatShareType")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local MapBuildingSubType = require("MapBuildingSubType")
local TimeFormatter = require("TimeFormatter")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local SlgUtils = require("SlgUtils")
local ObjectType = require("ObjectType")

local SHARE_PET_QUALITY_BASE = "sp_chat_base_quality_0"

---@class ChatMsgSelfItemCell : BaseTableViewProCell
local ChatMsgSelfItemCell = class('ChatMsgSelfItemCell', BaseTableViewProCell)

local HOLD_TIME = 0.5

function ChatMsgSelfItemCell:ctor()
    self.param = nil
	self._holdStartTime = 0
end

function ChatMsgSelfItemCell:OnCreate(param)
	self._onUpdateDelegate = nil
	self.portrait = self:LuaObject("child_ui_head_player_r")
	self.name = self:Text("p_text_name_r")
	---@type UIEmojiText
	self.text = self:LuaObject("ui_emoji_text_r")
	self.bubble = self:GameObject("p_btn_bubble_r")
	self:PointerDown("p_btn_bubble_r", Delegate.GetOrCreate(self, self.OnDown))
	self:PointerUp("p_btn_bubble_r", Delegate.GetOrCreate(self, self.OnUp))

	--Share
	self.goShareCoordR = self:GameObject("p_share_coord_r")
    ---@type ShareChatSelfItem
	self.luaGOShareCoordR = self:LuaObject("group_coord")

	self.goSharePetCardR = self:GameObject('p_share_pet_card_r')
	self.btnSharePetCardR = self:Button('p_share_pet_card_r', Delegate.GetOrCreate(self, self.OnBtnSharePetCardRClicked))
    self.imgQualityBaseR = self:Image('p_quality_base_r')
	self.imgQualityHeadR = self:Image('p_quality_head_r')
    self.imgIconPetR = self:Image('p_icon_pet_r')
    self.textPetNameR = self:Text('p_text_pet_name_r')
    self.imgAptitude1R = self:Image('p_aptitude_1_r')
    self.imgAptitude2R = self:Image('p_aptitude_2_r')
    self.imgAptitude3R = self:Image('p_aptitude_3_r')
	---@see ChatAllianceRecruitItem
	self.luaAllianceRecruit = self:LuaObject("p_league_recruit_r")

	self.p_league_group_r = self:GameObject("p_league_group_r")
	self.p_text_group_r = self:Text("p_text_group_r", "gathering_elite_title")
	self.p_text_distance_r = self:Text("p_text_distance_r")
	self.p_text_time_r = self:Text("p_text_time_r")
	self.p_img_head_r = self:Image("p_img_head_r")
	self.p_text_join_content_r = self:Text("p_text_join_content_r")
	self.p_btn_joined_r = self:Button("p_btn_joined_r")
	self.p_btn_joined_r:SetVisible(false)
	self.p_btn_join_r = self:Button("p_btn_join_r", Delegate.GetOrCreate(self, self.OnBtnAssembleClick))
	self.p_btn_join_r:SetVisible(true)
	self.p_text_join_r = self:Text("p_text_join_r", "goto")
	self.p_btn_d_r = self:Button("p_btn_d_r")
	self.p_btn_d_r:SetVisible(false)

	---@type PetStarLevelComponent
	self.group_star = self:LuaObject('group_star')

	-- Alliance Task
    self.p_task_r = self:GameObject('p_task_r')
    self.p_text_task_title_r = self:Text("p_text_task_title_r")
    self.p_text_task_r = self:Text("p_text_task_r")
    self.p_progress_r = self:Slider('p_progress_r')
    self.p_text_progress_r = self:Text('p_text_progress_r')
    self.p_btn_goto_r = self:Button('p_btn_goto_r', Delegate.GetOrCreate(self, self.OnClickGotoAllianceTask))
end

function ChatMsgSelfItemCell:OnShow(param)
end

function ChatMsgSelfItemCell:OnOpened(param)
end

function ChatMsgSelfItemCell:OnClose(param)
	self:RemoveFrameTicker()
end

function ChatMsgSelfItemCell:OnFeedData(param)
    if (not param) then return end
	self.param = param
	self.p_task_r:SetVisible(false)
	self.goSharePetCardR:SetActive(false)
	self.luaAllianceRecruit:SetVisible(false)
	self.p_league_group_r:SetVisible(false)
	self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
	if self.param.isShare then
		self.portrait.CSComponent.gameObject:SetActive(true)
		self.portrait:FeedData({
			iconId = param.extInfo.p
		})

		---@type ShareChatItemParam
		local chatParam = self:CreateChatParam(param.extInfo)
		if chatParam.type == ChatShareType.Pet then
			self.petParam = chatParam
			self.skillLevels = chatParam.pl
			self:SetStars()
			self.luaGOShareCoordR:SetVisible(false)
			self.goSharePetCardR:SetActive(true)
			self:RefreshPetCard(chatParam)
			self.goShareCoordR:SetActive(false)
		elseif chatParam.type == ChatShareType.AllianceTask then
			self.goShareCoordR:SetVisible(false)
			self.p_task_r:SetVisible(true)
			local provider = require('AllianceTaskItemDataProvider').new(param.extInfo.c)
			self.p_text_task_title_r.text =  I18N.Get("alliance_target_3")
			self.p_text_task_r.text = provider:GetTaskStr(true)
			local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(param.extInfo.c)
			self.p_progress_r.value = numCurrent/numNeeded
			self.p_text_progress_r.text = numCurrent .. "/" .. numNeeded
		else
			self.goShareCoordR:SetActive(true)
			self.luaGOShareCoordR:RefreshGroupItemInfo(chatParam)
			self.luaGOShareCoordR:SetVisible(true)
		end
	elseif param.isAllianceRecruit then
		self.portrait.CSComponent.gameObject:SetActive(true)
		local player = ModuleRefer.PlayerModule:GetPlayer()
		self.portrait:FeedData(player.Basics.PortraitInfo)
		self.luaAllianceRecruit:SetVisible(true)
		self.luaAllianceRecruit:FeedData(param)
	elseif param.iaAllianceAssemble then
		self.p_league_group_r:SetVisible(true)
		self.portrait.CSComponent.gameObject:SetActive(true)
		local player = ModuleRefer.PlayerModule:GetPlayer()
		self.portrait:FeedData(player.Basics.PortraitInfo)
		self:SetupAssembleInfo(param.extInfo)
	else
		self.portrait.CSComponent.gameObject:SetActive(true)
		local player = ModuleRefer.PlayerModule:GetPlayer()
		---@type wds.PortraitInfo
		self.portrait:FeedData(player.Basics.PortraitInfo)
		self.goShareCoordR:SetActive(false)
		self.text:FeedData({
			text = param.text
		})
	end
end

function ChatMsgSelfItemCell:AddFrameTicker()
	if (not self._onUpdateDelegate) then
		self._onUpdateDelegate = Delegate.GetOrCreate(self, self.OnUpdate)
		g_Game:AddFrameTicker(self._onUpdateDelegate)
	end
end

function ChatMsgSelfItemCell:RemoveFrameTicker()
	if (self._onUpdateDelegate) then
		g_Game:RemoveFrameTicker(self._onUpdateDelegate)
		self._onUpdateDelegate = nil
	end
end

function ChatMsgSelfItemCell:OnDown(go, data)
	self._holdStartTime = g_Game.Time.time
	self:AddFrameTicker()
end

function ChatMsgSelfItemCell:OnUp(go, data)
	self:RemoveFrameTicker()
end

function ChatMsgSelfItemCell:OnUpdate(delta)
	if (g_Game.Time.time - self._holdStartTime >= HOLD_TIME) then
		g_Game.UIManager:Open(UIMediatorNames.UIChatMessagePopupMediator, {
			data = self.param,
			anchorGo = self.bubble,
		})
		self:RemoveFrameTicker()
	end
end

function ChatMsgSelfItemCell:CreateChatParam(param)
	---@type ShareChatItemParam
	local chatParam = {}
	chatParam.type = param.t
	if param.b then
		chatParam.shareTime = param.b
	end
    if chatParam.type == ChatShareType.WorldEvent then
        local configInfo = ConfigRefer.WorldExpeditionTemplate:Find(param.c)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
            chatParam.configID = param.c
        end
    elseif chatParam.type == ChatShareType.ResourceField then
        local configInfo = ConfigRefer.FixedMapBuilding:Find(param.c)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
            chatParam.configID = param.c
            local outputNum = configInfo:OutputResourceCount()
            local outputInterval = configInfo:OutputResourceInterval() or 300
            local resourceYield = 3600 / outputInterval * outputNum
            chatParam.resourceYield = resourceYield or 0
        end
    elseif chatParam.type == ChatShareType.SlgMonster then
        local configInfo = ConfigRefer.KmonsterData:Find(param.c)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
            chatParam.configID = param.c
            chatParam.combatValue = configInfo:RecommendPower() or 0
        end
	elseif chatParam.type == ChatShareType.SlgBuilding then
		local configInfo = ConfigRefer.FixedMapBuilding:Find(param.c)
		if configInfo then
			chatParam.x = param.x
            chatParam.y = param.y
			chatParam.level = configInfo:Level()
			chatParam.name = I18N.Get(configInfo:Name())
            chatParam.shareDesc = param.sd
		end
	elseif chatParam.type == ChatShareType.Pet then
		chatParam.configID = param.c
		chatParam.x = param.x
		chatParam.y = param.y
		chatParam.z = param.z
		chatParam.pl = param.pl
		chatParam.gn = param.gn
	elseif chatParam.type == ChatShareType.AllianceMark then
        chatParam.x = param.x
        chatParam.y = param.y
		if string.IsNullOrEmpty(param.on) then
            local mapLabelCfg = ConfigRefer.AllianceMapLabel:Find(param.c)
            chatParam.name = I18N.Get(mapLabelCfg:DefaultDesc())
        else
            chatParam.name = param.on
        end
        chatParam.shareDesc = param.sd
        chatParam.customPic = ConfigRefer.AllianceMapLabel:Find(param.c):Icon()
    else
        if param.vt then
            local config = ConfigRefer.Territory:Find(param.vt.i)
            if config then
                chatParam.x = config:VillagePosition():X()
                chatParam.y = config:VillagePosition():Y()
                local villageConfig = ConfigRefer.FixedMapBuilding:Find(config:VillageId())
				local isBehemothCage = false
                if villageConfig then
                    chatParam.name = I18N.Get(villageConfig:Name())
                    chatParam.customPic = villageConfig:Image()
					chatParam.level = villageConfig:Level()
					if villageConfig:SubType() == MapBuildingSubType.CageSubType1 or villageConfig:SubType() == MapBuildingSubType.CageSubType2 then
                        isBehemothCage = true
                    end
                end
				chatParam.type = ChatShareType.SlgBuilding
                ---@type VillageFastForwardToSelectTroopDelegate
                chatParam.context = {}
                chatParam.context.__name = "VillageFastForwardToSelectTroopDelegate"
				chatParam.context.__isBehemothCage = isBehemothCage
            end
        else
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.name = I18N.Get("share_position_content")
        end
    end
	self.posX = chatParam.x
	self.posY = chatParam.y
	return chatParam
end

function ChatMsgSelfItemCell:RefreshPetCard(param)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(param.configID)
    g_Game.SpriteManager:LoadSprite(SHARE_PET_QUALITY_BASE .. petCfg:Quality(), self.imgQualityBaseR)
    g_Game.SpriteManager:LoadSprite("sp_hero_frame_circle_" .. (petCfg:Quality() + 2), self.imgQualityHeadR)
    self:LoadSprite(petCfg:Icon(), self.imgIconPetR)
    self.textPetNameR.text = I18N.Get(petCfg:Name())

    local randAttrCfg = ConfigRefer.PetRandomAttrItem:Find(param.z)
	if (randAttrCfg) then
		local sp1 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(1))
		g_Game.SpriteManager:LoadSprite(sp1, self.imgAptitude1R)
		local sp2 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(2))
		g_Game.SpriteManager:LoadSprite(sp2, self.imgAptitude2R)
		local sp3 = ModuleRefer.PetModule:GetPetAttrQualitySP(randAttrCfg:AttrQuality(3))
		g_Game.SpriteManager:LoadSprite(sp3, self.imgAptitude3R)
	end
end

function ChatMsgSelfItemCell:OnBtnSharePetCardRClicked(args)
	g_Game.UIManager:Open(UIMediatorNames.PetShareMediator, self.petParam)
end

function ChatMsgSelfItemCell:GetTargetDistance(posX, posY)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then return end
    local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    return AllianceWarTabHelper.CalculateMapDistance(posX, posY, castlePos.X, castlePos.Y)
end

function ChatMsgSelfItemCell:SetupAssembleInfo(args)
    local t = args.t
    local configId = args.c
    local objectType = args.ot or ObjectType.SlgMob
    local srcName = args.n
    local distance = self:GetTargetDistance(args.px, args.py)

    self.p_text_distance_r:SetVisible(distance ~= nil)
    if distance then
        if distance > 1000 then
            self.p_text_distance_r.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            self.p_text_distance_r.text = ("%dM"):format(math.floor(distance + 0.5))
        end
    end

    self.p_text_time_r.text = TimeFormatter.TimeToDateTimeStringUseFormat(t, "MM.dd HH:mm:ss")
    local pic
    local targetName
    if configId then
        targetName, pic = SlgUtils.GetNameIconPowerByConfigId(objectType, configId)
    else
        targetName = args.tn
        local pPortrait = args.tp
        pic = ModuleRefer.PlayerModule:GetPortraitSpriteName(pPortrait)
    end
    self.p_text_join_content_r.text = I18N.GetWithParams("alliance_team_toast01", srcName, targetName)
    g_Game.SpriteManager:LoadSprite(pic, self.p_img_head_r)
end

function ChatMsgSelfItemCell:OnBtnAssembleClick()
    ---@type AllianceWarNewMediatorParameter
    local param = {}
    param.enterTabIndex = 1
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, param)
end

function ChatMsgSelfItemCell:OnClickGotoAllianceTask()
    g_Game.UIManager:CloseByName(UIMediatorNames.UIChatMediator)
	local provider = require('AllianceTaskItemDataProvider').new(self.param.extInfo.c)
	provider:OnGoto()
end


function ChatMsgSelfItemCell:SetStars()
    if self.group_star then
        if self.skillLevels then
            local param = {skillLevels = self.skillLevels}
            self.group_star:FeedData(param)
            self.group_star:SetVisible(true)
        else
            self.group_star:SetVisible(false)
        end
    end
end

return ChatMsgSelfItemCell
