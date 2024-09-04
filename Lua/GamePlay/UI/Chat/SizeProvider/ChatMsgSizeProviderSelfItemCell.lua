local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local ChatShareType = require("ChatShareType")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local MapBuildingSubType = require("MapBuildingSubType")

---@class ChatMsgSizeProviderSelfItemCell : BaseUIComponent
local ChatMsgSizeProviderSelfItemCell = class('ChatMsgSizeProviderSelfItemCell', BaseUIComponent)

local HOLD_TIME = 0.5

function ChatMsgSizeProviderSelfItemCell:ctor()
    self.param = nil
	self._holdStartTime = 0
end

function ChatMsgSizeProviderSelfItemCell:OnCreate(param)
	self._onUpdateDelegate = nil
	self.portrait = self:LuaObject("child_ui_head_player_r")
	self.name = self:Text("p_text_name_r")
	---@type UIEmojiText
	self.text = self:LuaObject("ui_emoji_text_r")
	self.bubble = self:GameObject("p_btn_bubble_r")

	--Share
	self.goShareCoordR = self:GameObject("p_share_coord_r")
    ---@type ShareChatSelfItem
	self.luaGOShareCoordR = self:LuaObject("group_coord")

    ---@see ChatAllianceRecruitItem
	self.luaAllianceRecruit = self:LuaObject("p_league_recruit_r")
    self.p_league_group_r = self:GameObject("p_league_group_r")
end

function ChatMsgSizeProviderSelfItemCell:OnFeedData(param)
    if (not param) then return end
	self.param = param
	self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
	if self.param.isShare then
        self.luaAllianceRecruit:SetVisible(false)
		self.portrait.CSComponent.gameObject:SetActive(true)
		self.portrait:FeedData({
			iconId = param.extInfo.p
		})
		
		self.goShareCoordR:SetActive(true)
		---@type ShareChatItemParam
		local chatParam = self:CreateChatParam(param.extInfo)
		self.luaGOShareCoordR:RefreshGroupItemInfo(chatParam)
    elseif self.param.isAllianceRecruit then
        self.portrait.CSComponent.gameObject:SetActive(true)
        self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
        self.portrait:FeedData({iconId = param.extInfo.p})
        self.luaAllianceRecruit:SetVisible(true)
        self.luaAllianceRecruit:FeedData(param)
    elseif self.param.iaAllianceAssemble then
        self.p_league_group_r:SetVisible(true)
	else
        self.luaAllianceRecruit:SetVisible(false)
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

function ChatMsgSizeProviderSelfItemCell:CreateChatParam(param)
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
            if param.payload and param.payload.content then
                chatParam.shareDesc = param.payload.content
            end
		end
    elseif chatParam.type == ChatShareType.Pet then
		chatParam.configID = param.c
		chatParam.x = param.x
		chatParam.y = param.y
		chatParam.z = param.z
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

return ChatMsgSizeProviderSelfItemCell
