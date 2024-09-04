local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local GuideUtils = require('GuideUtils')
local KingdomMapUtils = require('KingdomMapUtils')
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local EventConst = require("EventConst")
local ChatShareType = require("ChatShareType")
local TimerUtility = require("TimerUtility")
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")
local DBEntityType = require('DBEntityType')
local MapBuildingSubType = require("MapBuildingSubType")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local TimeFormatter = require("TimeFormatter")
local SlgUtils = require("SlgUtils")
local ObjectType = require("ObjectType")

local SHARE_PET_QUALITY_BASE = "sp_chat_base_quality_0"

---@class ChatMsgOtherItemCell : BaseTableViewProCell
local ChatMsgOtherItemCell = class('ChatMsgOtherItemCell', BaseTableViewProCell)

local HOLD_TIME = 0.5
local I18N_FROM_NAME_SYSTEM_TOAST = "chat_system_name"
local TRANSLATION_DELAY = 0.5 --- 翻译延迟，需求来自银狼(王玮楠) 2023/11/01 12:03:38

function ChatMsgOtherItemCell:ctor()
    self.param = nil
    self._holdStartTime = 0
end

function ChatMsgOtherItemCell:OnCreate(param)
    self.gameObject = self:GameObject('')
    ---@type PlayerInfoComponent
    self.portrait = self:LuaObject("child_ui_head_player_l")
    self.portrait:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnPortraitClick))
    self.name = self:Text("p_text_name_l")
    ---@type UIEmojiText
    self.text = self:LuaObject("ui_emoji_text_l")
    self.bubblePanel = self:GameObject("p_bubble_l")
    self.bubble = self:GameObject("p_btn_bubble_l")
    self:PointerDown("p_btn_bubble_l", Delegate.GetOrCreate(self, self.OnDown))
    self:PointerUp("p_btn_bubble_l", Delegate.GetOrCreate(self, self.OnUp))

    -- Toast
    self.toastPanel = self:GameObject("p_share_l")
    self.toastPortrait = self:Image("p_head_icon")
    self.toastIcon = self:Image("p_img_head_monster_l")
    self.toastTitle = self:Text("p_text_share_l")
    self.toastContent = self:Text("p_text_join_battle_l")
    self.toastReward = self:GameObject("p_group_reward_l")
    self.toastShareCoordL = self:GameObject("p_share_coord_l")
    ---@type BistateButton
    self.toastButton = self:LuaObject("p_btn_share_l")

    -- Share
    self.goShareCoordL = self:GameObject("p_share_coord_l")
    ---@type ShareChatOtherItem
    self.luaGOShareCoordL = self:LuaObject("group_coord")

    -- Translation
    self.translationRoot = self:GameObject("btns_translate")
    self.translationBtn = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickTranslateTo))
    self.translatingMark = self:GameObject("p_group_translating")
    self.translationRecoverBtn = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickRecoverTranslation))

    self.p_league_group_l = self:GameObject("p_league_group_l")
    self.p_text_group_l = self:Text("p_text_group_l", "gathering_elite_title")
    self.p_text_distance_l = self:Text("p_text_distance_l")
    self.p_text_time_l = self:Text("p_text_time_l")
    self.p_img_head_l = self:Image("p_img_head_l")
    self.p_text_join_content_l = self:Text("p_text_join_content_l")
    self.p_btn_joined_l = self:Button("p_btn_joined_l")
    self.p_btn_joined_l:SetVisible(false)
    -- self.p_text_joined_l = self:Text("p_text_joined_l", "alliance_recommend_banner_look")
    self.p_btn_join_l = self:Button("p_btn_join_l", Delegate.GetOrCreate(self, self.OnBtnAssembleClick))
    self.p_btn_join_l:SetVisible(true)
    self.p_text_join_l = self:Text("p_text_join_l", "goto")
    self.p_btn_d_l = self:Button("p_btn_d_l")
    self.p_btn_d_l:SetVisible(false)
    -- self.p_text_d_l = self:Text("p_text_d_l", "village_info_expired")
    -- Alliance Task
    self.p_task_l = self:GameObject('p_task_l')
    self.p_text_task_title_l = self:Text("p_text_task_title_l")
    self.p_text_task_l = self:Text("p_text_task_l")
    self.p_progress_l = self:Slider('p_progress_l')
    self.p_text_progress_l = self:Text('p_text_progress_l')
    self.p_btn_goto_l = self:Button('p_btn_goto_l', Delegate.GetOrCreate(self, self.OnClickGotoAllianceTask))

    -- Alliance WorldEvent Use Only
    self.p_world_event_l = self:GameObject('p_world_event_l')
    self.child_comp_btn_share_world_event_l = self:Button('child_comp_btn_share_world_event_l', Delegate.GetOrCreate(self, self.OnClickGotoWorldEvent))
    self.p_text_world_event_l = self:Text('p_text_world_event_l')
    self.p_text_world_event_title_l = self:Text('p_text_world_event_title_l')

    -- Alliance Recruit
    ---@see ChatAllianceRecruitItem
    self.luaAllianceRecruit = self:LuaObject("p_league_recruit_l")

    self.goSharePetCardL = self:GameObject('p_share_pet_card_l')
    self.btnSharePetCardL = self:Button('p_share_pet_card_l', Delegate.GetOrCreate(self, self.OnBtnSharePetCardLClicked))
    self.imgQualityBaseL = self:Image('p_quality_base_l')
    self.imgIconPetL = self:Image('p_icon_pet_l')
    self.textPetNameL = self:Text('p_text_pet_name_l')
    self.imgQualityHeadL = self:Image('p_quality_head_l')

    -- pet
    self.group_star = self:LuaObject('group_star')
end

function ChatMsgOtherItemCell:OnShow(param)
end

function ChatMsgOtherItemCell:OnOpened(param)
end

function ChatMsgOtherItemCell:OnClose(param)
    self.param = nil
    self:RemoveFrameTicker()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
end

function ChatMsgOtherItemCell:OnFeedData(param)
    if not param or not param.extInfo then
        return
    end
    
    self.param = param
    self.skillLevels = param.extInfo.pl
    self.p_task_l:SetVisible(false)
    self.p_world_event_l:SetVisible(false)
    self.goSharePetCardL:SetActive(false)
    self.luaAllianceRecruit:SetVisible(false)
    self.p_league_group_l:SetVisible(false)
    if self.param.isWorldEvent then
        local entity = g_Game.DatabaseManager:GetEntity(self.param.ExpeditionEntityId, DBEntityType.Expedition)
        if not entity then
            self.gameObject:SetVisible(false)
            return
        end
        self.cfgId = param.cfgId
        self.p_world_event_l:SetVisible(true)
        self.portrait.CSComponent.gameObject:SetActive(false)
        self.toastPortrait.gameObject:SetActive(true)
        self.toastPanel:SetActive(false)
        self.bubblePanel:SetActive(false)
        self.goShareCoordL:SetActive(false)
        self.name.text = I18N.Get(I18N_FROM_NAME_SYSTEM_TOAST)
        ---@type ToastConfigCell
        local toastCfg = ConfigRefer.Toast:Find(8)

        if (Utils.IsNullOrEmpty(toastCfg:Icon())) then
            self.toastIcon.gameObject:SetActive(false)
        else
            self.toastIcon.gameObject:SetActive(true)
            g_Game.SpriteManager:LoadSprite(toastCfg:Icon(), self.toastIcon)
        end
        self.p_text_world_event_title_l.text = "联盟世界事件"
        self.p_text_world_event_l.text = "联盟世界事件开启"
        local cfg = ConfigRefer.WorldExpeditionTemplate:Find(self.param.cfgId)
        self.cfgId = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(param.cfgId).ConfigId
        self.toastContent.text = I18N.Get(cfg:Name())
        self.child_comp_btn_share_world_event_l:SetVisible(true)
    elseif (self.param.isToast) then
        ---@type wds.Toast
        local toast = self.param.toast
        self.portrait.CSComponent.gameObject:SetActive(false)
        self.toastPortrait.gameObject:SetActive(true)
        self.toastPanel:SetActive(true)
        self.bubblePanel:SetActive(false)
        self.goShareCoordL:SetActive(false)
        self.name.text = I18N.Get(I18N_FROM_NAME_SYSTEM_TOAST)
        ---@type ToastConfigCell
        local toastCfg = ConfigRefer.Toast:Find(toast.ConfigId)
        local dataContent = toast.Title
        local title = ServiceDynamicDescHelper.ParseWithI18N(toastCfg:Title(), toastCfg:TitleDescLength(), toastCfg, toastCfg.TitleDesc, dataContent.StringParams, dataContent.IntParams,
                                                             dataContent.FloatParams, dataContent.ConfigParams)

        dataContent = toast.Content
        local content = ServiceDynamicDescHelper.ParseWithI18N(toastCfg:Content(), toastCfg:ContentDescLength(), toastCfg, toastCfg.ContentDesc, dataContent.StringParams, dataContent.IntParams,
                                                               dataContent.FloatParams, dataContent.ConfigParams)

        if (Utils.IsNullOrEmpty(toastCfg:Icon())) then
            self.toastIcon.gameObject:SetActive(false)
        else
            self.toastIcon.gameObject:SetActive(true)
            g_Game.SpriteManager:LoadSprite(toastCfg:Icon(), self.toastIcon)
        end
        self.toastTitle.text = title
        self.toastContent.text = content
        self.toastReward:SetActive(false)
        self.toastButton.CSComponent.gameObject:SetActive(toastCfg:TriggerGuide() > 0)
        self.toastButton:FeedData({buttonName = "child_comp_btn_share", onClick = Delegate.GetOrCreate(self, self.OnToastClick)})
        self.toastButton:SetButtonText(I18N.Get("getmore_go"))
        if toast.ExpireTime.Seconds > 0 then
            local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
            local leftTime = toast.ExpireTime.Seconds - curTime
            if leftTime > 0 then
                self.isActive = true
                self.toastButton:SetEnabled(true)
                g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
            else
                self.isActive = false
                self.toastButton:SetEnabled(false)
            end
        end
        self.translationRoot:SetActive(false)
    elseif self.param.isShare then
        self.portrait.CSComponent.gameObject:SetActive(true)
        self.toastPortrait.gameObject:SetActive(false)
        self.toastPanel:SetActive(false)
        self.bubblePanel:SetActive(false)
        self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
        if param.extInfo.vt and param.extInfo.vt.p then
            self.portrait:FeedData({iconId = param.extInfo.vt.p})
        else
            self.portrait:FeedData({iconId = param.extInfo.p})
        end

        self.goShareCoordL:SetActive(true)
        ---@type ShareChatItemParam
        local chatParam = self:CreateChatParam(param.extInfo)

        if chatParam.type == ChatShareType.Pet then
            self.petParam = chatParam
            self.luaGOShareCoordL:SetVisible(false)
            self.goSharePetCardL:SetActive(true)
            self:RefreshPetCard(chatParam)
            self.goShareCoordL:SetActive(false)
        elseif chatParam.type == ChatShareType.AllianceTask then
			self.goShareCoordL:SetVisible(false)
			self.p_task_l:SetVisible(true)
			local provider = require('AllianceTaskItemDataProvider').new(param.extInfo.c)
			self.p_text_task_title_l.text =  I18N.Get("alliance_target_3")
			self.p_text_task_l.text = provider:GetTaskStr(true)
			local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(param.extInfo.c)
			self.p_progress_l.value = numCurrent/numNeeded
			self.p_text_progress_l.text = numCurrent .. "/" .. numNeeded
        else
            self.goShareCoordL:SetActive(true)
            self.luaGOShareCoordL:RefreshGroupItemInfo(chatParam)
            self.luaGOShareCoordL:SetVisible(true)
        end
        self.translationRoot:SetActive(false)
    elseif self.param.isAllianceRecruit then
        self.portrait.CSComponent.gameObject:SetActive(true)
        self.toastPortrait.gameObject:SetActive(false)
        self.toastPanel:SetActive(false)
        self.bubblePanel:SetActive(false)
        self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
        self.portrait:FeedData({iconId = param.extInfo.p})
        self.luaAllianceRecruit:SetVisible(true)
        self.luaAllianceRecruit:FeedData(param)
        self.translationRoot:SetActive(false)
    elseif self.param.iaAllianceAssemble then
        self.p_league_group_l:SetVisible(true)
        self.portrait.CSComponent.gameObject:SetActive(true)
        self.toastPortrait.gameObject:SetActive(false)
        self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
        self.portrait:FeedData({iconId = param.extInfo.p})
        self:SetupAssembleInfo(param.extInfo)
    else
        self.portrait.CSComponent.gameObject:SetActive(true)
        self.toastPortrait.gameObject:SetActive(false)
        self.toastPanel:SetActive(false)
        self.bubblePanel:SetActive(true)
        self.goShareCoordL:SetActive(false)
        self.name.text = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(param.extInfo, param.uid)
        ---@type wds.PortraitInfo
        local portraitInfo = wds.PortraitInfo.New()
        portraitInfo.PlayerPortrait = param.extInfo.p
        portraitInfo.PortraitFrameId = param.extInfo.fp
        portraitInfo.CustomAvatar = param.extInfo.ca and param.extInfo.ca or ""
        self.portrait:FeedData(portraitInfo)
        self.translationRoot:SetActive(true)
        if self.param.translation.showTranslated then
            self.translationBtn:SetVisible(false)
            self.translatingMark:SetActive(false)
            self.translationRecoverBtn:SetVisible(true)
        elseif self.param.translation.translating then
            self.translationBtn:SetVisible(false)
            self.translatingMark:SetActive(true)
            self.translationRecoverBtn:SetVisible(false)
        else
            self.translationBtn:SetVisible(true)
            self.translatingMark:SetActive(false)
            self.translationRecoverBtn:SetVisible(false)
        end

        if self.param.translation.showTranslated then
            local message = ModuleRefer.ChatModule:GetMessage(self.param.imId)
            if message then
                self.text:FeedData({text = message.TranslatedInfo.targetText})
            else
                self.text:FeedData({text = self.param.text})
            end
        else
            self.text:FeedData({text = self.param.text})
        end
    end
end

function ChatMsgOtherItemCell:AddFrameTicker()
    if (not self._onUpdateDelegate) then
        self._onUpdateDelegate = Delegate.GetOrCreate(self, self.OnUpdate)
        g_Game:AddFrameTicker(self._onUpdateDelegate)
    end
end

function ChatMsgOtherItemCell:RemoveFrameTicker()
    if (self._onUpdateDelegate) then
        g_Game:RemoveFrameTicker(self._onUpdateDelegate)
        self._onUpdateDelegate = nil
    end
end

function ChatMsgOtherItemCell:OnDown(go, data)
    self._holdStartTime = g_Game.Time.time
    self:AddFrameTicker()
end

function ChatMsgOtherItemCell:OnUp(go, data)
    self:RemoveFrameTicker()
end

function ChatMsgOtherItemCell:OnUpdate(delta)
    if (g_Game.Time.time - self._holdStartTime >= HOLD_TIME) then
        g_Game.UIManager:Open(UIMediatorNames.UIChatMessagePopupMediator, {data = self.param, anchorGo = self.bubble})
        self:RemoveFrameTicker()
    end
end

function ChatMsgOtherItemCell:OnPortraitClick()
    ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self.param.uid, self.portrait.CSComponent.gameObject)
    -- g_Game.UIManager:Open(UIMediatorNames.UIChatHeadPopupMediator, {anchorGo = self.portrait.CSComponent.gameObject, data = self.param})
end

function ChatMsgOtherItemCell:OnToastClick()
    if (self.param.toast) then
        local toastCfg = ConfigRefer.Toast:Find(self.param.toast.ConfigId)
        if self.param.toast.Position then
            local triggerFunc = function()
                local myCityPosition = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(self.param.toast.Position.X, self.param.toast.Position.Y, KingdomMapUtils.GetMapSystem())
                KingdomMapUtils.MoveAndZoomCamera(myCityPosition, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
            end
            if KingdomMapUtils.IsCityState() then
                KingdomMapUtils.GetKingdomScene():LeaveCity(function()
                    triggerFunc()
                end)
            else
                triggerFunc()
            end
        else
            if toastCfg:TriggerGuide() > 0 then
                GuideUtils.GotoByGuide(toastCfg:TriggerGuide(), false)
                g_Game.EventManager:TriggerEvent(EventConst.CHAT_CLOSE_PANEL)
            end
        end

    end
end

function ChatMsgOtherItemCell:CreateChatParam(param)
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
        chatParam.gn = param.gn
        chatParam.pl = param.pl
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

function ChatMsgOtherItemCell:SecondUpdate()
    if not self.param or not self.param.toast or not self.param.toast.ExpireTime then
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
        return
    end
    if self.param.toast.ExpireTime.Seconds > 0 and self.isActive then
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        local remainTime = self.param.toast.ExpireTime.Seconds - curTime
        if remainTime <= 0 then
            self.isActive = false
            self.toastButton:SetEnabled(false)
            g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
        end
    end
end

function ChatMsgOtherItemCell:OnClickTranslateTo()
    if self.param.translation == nil then
        return
    end

    if self.param.translation.isTranslated then
        self.param.translation.showTranslated = true
        local tableView = self:GetTableViewPro()
        if Utils.IsNotNull(tableView) then
            tableView:UpdateChild(self.param)
        end
    else
        self.param.translation.translating = true
        local message = ModuleRefer.ChatModule:GetMessage(self.param.imId)
        ModuleRefer.ChatSDKModule:Translate(message, Delegate.GetOrCreate(self, self.OnTranslationCallback))
        local tableView = self:GetTableViewPro()
        if Utils.IsNotNull(tableView) then
            tableView:UpdateChild(self.param)
        end
        self.param.translation.startTranslateTime = CS.UnityEngine.Time.realtimeSinceStartup
    end
end

---@param imId number
---@param code number
---@param msg string
---@param info CS.FunPlusChat.Models.FPTranslatedInfo
function ChatMsgOtherItemCell:OnTranslationCallback(imId, code, msg, info)
    if self.param == nil or imId ~= self.param.imId then
        return
    end

    local finishTime = CS.UnityEngine.Time.realtimeSinceStartup
    if finishTime - self.param.translation.startTranslateTime < TRANSLATION_DELAY then
        TimerUtility.DelayExecute(function()
            self:OnTranslationCallback(imId, code, msg, info)
        end, TRANSLATION_DELAY - (finishTime - self.param.translation.startTranslateTime))
        return
    end

    self.param.translation.translating = false
    if code ~= 0 then
        g_Logger.ErrorChannel("Chat", "Translate failed, code: %s, msg: %s", code, msg)
    else
        self.param.translation.isTranslated = true
        self.param.translation.showTranslated = true
    end

    local tableView = self:GetTableViewPro()
    if Utils.IsNotNull(tableView) then
        tableView:UpdateChild(self.param)
    end
end

function ChatMsgOtherItemCell:OnClickRecoverTranslation()
    if self.param.translation == nil then
        return
    end

    self.param.translation.showTranslated = false
    local tableView = self:GetTableViewPro()
    if Utils.IsNotNull(tableView) then
        tableView:UpdateChild(self.param)
    end
end

function ChatMsgOtherItemCell:OnClickGotoAllianceTask()
	local provider = require('AllianceTaskItemDataProvider').new(self.param.extInfo.c)
	provider:OnGoto()
    g_Game.UIManager:CloseByName(UIMediatorNames.UIChatMediator)
end

function ChatMsgOtherItemCell:OnClickGotoWorldEvent()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.UIChatMediator)
        scene:LeaveCity(function()
            ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
        end)
    else
        g_Game.UIManager:CloseAllByName(UIMediatorNames.UIChatMediator)
        ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
    end
end

function ChatMsgOtherItemCell:RefreshPetCard(param)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(param.configID)
    g_Game.SpriteManager:LoadSprite(SHARE_PET_QUALITY_BASE .. petCfg:Quality(), self.imgQualityBaseL)
    g_Game.SpriteManager:LoadSprite("sp_hero_frame_circle_" .. (petCfg:Quality() + 2), self.imgQualityHeadL)
    self:LoadSprite(petCfg:Icon(), self.imgIconPetL)
    self.textPetNameL.text = I18N.Get(petCfg:Name())
    self:SetStars()
end

function ChatMsgOtherItemCell:OnBtnSharePetCardLClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.PetShareMediator, self.petParam)
end

function ChatMsgOtherItemCell:GetTargetDistance(posX, posY)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then return end
    local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    return AllianceWarTabHelper.CalculateMapDistance(posX, posY, castlePos.X, castlePos.Y)
end

function ChatMsgOtherItemCell:SetupAssembleInfo(args)
    local t = args.t
    local configId = args.c
    local objectType = args.ot or ObjectType.SlgMob
    local srcName = args.n
    local distance = self:GetTargetDistance(args.px, args.py)

    self.p_text_distance_l:SetVisible(distance ~= nil)
    if distance then
        if distance > 1000 then
            self.p_text_distance_l.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            self.p_text_distance_l.text = ("%dM"):format(math.floor(distance + 0.5))
        end
    end

    self.p_text_time_l.text = TimeFormatter.TimeToDateTimeStringUseFormat(t, "MM.dd HH:mm:ss")
    local pic
    local targetName
    if configId then
        targetName, pic = SlgUtils.GetNameIconPowerByConfigId(objectType, configId)
    else
        targetName = args.tn
        local pPortrait = args.tp
        pic = ModuleRefer.PlayerModule:GetPortraitSpriteName(pPortrait)
    end
    self.p_text_join_content_l.text = I18N.GetWithParams("alliance_team_toast01", srcName, targetName)
    g_Game.SpriteManager:LoadSprite(pic, self.p_img_head_l)
end

function ChatMsgOtherItemCell:OnBtnAssembleClick()
    ---@type AllianceWarNewMediatorParameter
    local param = {}
    param.enterTabIndex = 1
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, param)
end

function ChatMsgOtherItemCell:SetStars()
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

return ChatMsgOtherItemCell
