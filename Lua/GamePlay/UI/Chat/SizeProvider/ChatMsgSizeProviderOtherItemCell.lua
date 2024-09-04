local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local ChatShareType = require("ChatShareType")
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")
local DBEntityType = require('DBEntityType')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local MapBuildingSubType = require("MapBuildingSubType")

---@class ChatMsgSizeProviderOtherItemCell : BaseUIComponent
local ChatMsgSizeProviderOtherItemCell = class('ChatMsgSizeProviderOtherItemCell', BaseUIComponent)
local I18N_FROM_NAME_SYSTEM_TOAST = "chat_system_name"

function ChatMsgSizeProviderOtherItemCell:ctor()
    self.param = nil
    self._holdStartTime = 0
end

function ChatMsgSizeProviderOtherItemCell:OnCreate(param)
    self.gameObject = self:GameObject('')
    ---@type PlayerInfoComponent
    self.portrait = self:LuaObject("child_ui_head_player_l")
    self.name = self:Text("p_text_name_l")
    ---@type UIEmojiText
    self.text = self:LuaObject("ui_emoji_text_l")
    self.bubblePanel = self:GameObject("p_bubble_l")
    self.bubble = self:GameObject("p_btn_bubble_l")

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
    self.translationBtn = self:Button("p_btn_group_translate")
    self.translatingMark = self:GameObject("p_group_translating")
    self.translationRecoverBtn = self:Button("p_btn_group_revert")

    -- Alliance WorldEvent Use Only
    self.p_world_event_l = self:GameObject('p_world_event_l')
    self.child_comp_btn_share_world_event_l = self:Button('child_comp_btn_share_world_event_l', Delegate.GetOrCreate(self, self.OnClickGotoWorldEvent))
    self.p_text_world_event_l = self:Text('p_text_world_event_l')
    self.p_text_world_event_title_l = self:Text('p_text_world_event_title_l')

    ---@see ChatAllianceRecruitItem
    self.luaAllianceRecruit = self:LuaObject("p_league_recruit_l")
    self.p_league_group_l = self:GameObject("p_league_group_l")
end

function ChatMsgSizeProviderOtherItemCell:OnClose(param)
    self.param = nil
end

function ChatMsgSizeProviderOtherItemCell:OnFeedData(param)
    if (not param) then
        return
    end
    self.param = param
    self.p_world_event_l:SetVisible(false)
    self.luaAllianceRecruit:SetVisible(false)
    self.p_league_group_l:SetVisible(false)
    if self.param.isWorldEvent then
        local entity = g_Game.DatabaseManager:GetEntity(self.param.ExpeditionEntityId, DBEntityType.Expedition)
        if not entity then
            self.gameObject:SetVisible(false)
            return
        end
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
        local node = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(param.cfgId)
        if node then
            self.cfgId = node.ConfigId
            self.toastContent.text = I18N.Get(cfg:Name())
            self.child_comp_btn_share_world_event_l:SetVisible(true)
        else
            self.gameObject:SetVisible(false)
        end
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
        self.toastButton:FeedData({
            buttonName = "child_comp_btn_share",
            onClick = function()
            end,
        })
        self.toastButton:SetButtonText(I18N.Get("getmore_go"))
        if toast.ExpireTime.Seconds > 0 then
            local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
            local leftTime = toast.ExpireTime.Seconds - curTime
            if leftTime > 0 then
                self.isActive = true
                self.toastButton:SetEnabled(true)
            else
                self.isActive = false
                self.toastButton:SetEnabled(false)
            end
        end
        self.translationRoot:SetActive(false)
    elseif self.param.isShare then
        self.luaAllianceRecruit:SetVisible(false)
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
        self.luaGOShareCoordL:RefreshGroupItemInfo(chatParam)
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
    else
        self.luaAllianceRecruit:SetVisible(false)
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
            self.text:FeedData({text = message.TranslatedInfo.targetText})
        else
            self.text:FeedData({text = self.param.text})
        end
    end
end

function ChatMsgSizeProviderOtherItemCell:CreateChatParam(param)
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

function ChatMsgSizeProviderOtherItemCell:OnClickTranslateTo()

end

function ChatMsgSizeProviderOtherItemCell:OnClickGotoWorldEvent()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        local callback = function()
            ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
        end
        g_Game.UIManager:CloseAllByName(UIMediatorNames.UIChatMediator)
        scene:LeaveCity(callback)
    else
        ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
    end
end

return ChatMsgSizeProviderOtherItemCell
