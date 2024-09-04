local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Utils = require("Utils")
local EventConst = require("EventConst")
local AudioConsts = require("AudioConsts")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local DBEntityType = require('DBEntityType')
local ChatShareType = require("ChatShareType")
local MapBuildingSubType = require("MapBuildingSubType")

---@class ChatV2UIMediatorOpenContext
---@field openMethod number @nil,0 - normal, 1- privateChat
---@field privateChatUid number
---@field extInfo table|nil

---@class ChatV2UIMediator : BaseUIMediator
local ChatV2UIMediator = class('ChatV2UIMediator', BaseUIMediator)

local MessageType = CS.FunPlusChat.Models.MessageType
--local SessionType = CS.FunPlusChat.Models.SessionType
local GroupType = CS.FunPlusChat.Models.GroupType

local DEFAULT_MSG_COUNT = 20
local TIMESTAMP_MIN_DELTA = 300000	-- 5分钟(ms)
local MESSAGE_MAX_LENGTH = 40
local SORTVALUE_SYSTEM_TOAST = 99999999999903
local SORTVALUE_WORLD = 99999999999902
local SORTVALUE_ALLIANCE = 99999999999901

local EMOJI_INDEX_START = 0
local EMOJI_INDEX_END = 6
local EMOJI_SPRITE_FORMAT = "#%03d"
local EMOJI_TEXT_FORMAT = "[%03d]"

local ChatCellTemplate = {
	Message = "p_item_chat",
	SharePet = "p_item_share_pet_card",
	ShareLeagueAssemble = "p_item_league_group",
	ShareWorldEvent = "p_item_world_event",
	ShareLeagueRecruit = "p_item_league_recruit",
	ShareLeagueTask = "p_item_task",
	ShareCood = "p_item_share_coord",
	HintAndTimestamp = "p_item_chat_hint",
}

function ChatV2UIMediator:ctor()
	self._selectedSessionId = nil
	self._channelDataList = {}
	self._channelDataMap = {}
	self._chatSessionMessageList = {}
	self._chatTablePulling = false
	---@type CS.FunPlusChat.Models.FPMessage
	self._lastMsg = nil
	self._emojiTableGenerated = false
	self._noScrolling = false
end

function ChatV2UIMediator:OnCreate()
	DEFAULT_MSG_COUNT, TIMESTAMP_MIN_DELTA, MESSAGE_MAX_LENGTH = ModuleRefer.ChatModule:GetMainConfigs()
	g_Game.EventManager:AddListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:AddListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))
	g_Game.EventManager:AddListener(EventConst.CHAT_GOTO_SESSION, Delegate.GetOrCreate(self, self.OnGotoSession))
	g_Game.EventManager:AddListener(EventConst.CHAT_SYSTEM_TOAST_CHANGED, Delegate.GetOrCreate(self, self.OnSystemToastChanged))
	g_Game.EventManager:AddListener(EventConst.CHAT_CLOSE_PANEL, Delegate.GetOrCreate(self, self.OnCloseSelf))
    self:InitObjects()
end

function ChatV2UIMediator:InitObjects()
	-- 返回
	self.backButton = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnBackButtonClick))
	self.textBack = self:Text("p_text_back", "chat_list")

	-- 频道列表
	self.channelTable = self:TableViewPro("p_table_left")

	-- 聊天面板
	self.chatIcon = self:Image("p_icon_logo")
	self.chatNameText = self:Text("p_text_name_chat")
	self.chatSendButton = self:Button("p_btn_send", Delegate.GetOrCreate(self, self.OnChatSendButtonClick))
	self.chatSendButtonText = self:Text("p_text_send", "chat_send")
	self.chatTextInput = self:InputField("p_input_abbr", nil, nil, Delegate.GetOrCreate(self, self.OnChatSendButtonClick))
	self.chatTextInput.characterLimit = MESSAGE_MAX_LENGTH
    
	---@type CS.SuperScrollView.LoopListView2
    self._loopListView = self:BindComponent("p_table_chat", typeof(CS.SuperScrollView.LoopListView2))
	---@type CS.UnityEngine.UI.ScrollRect
	self.chatTableScrollRect = self:BindComponent("p_table_chat", typeof(CS.UnityEngine.UI.ScrollRect))
    self._loopListView.mOnDragingAction = Delegate.GetOrCreate(self, self.OnChatTableScrolling)
	self._loopListView.mOnEndDragAction = Delegate.GetOrCreate(self, self.OnChatTableScrollEnd)

	self.chatMenuButton = self:Button("p_btn_set", Delegate.GetOrCreate(self, self.OnChatMenuButtonClick))
	self.chatMenuCloseButton = self:Button("p_btn_empty_set", Delegate.GetOrCreate(self, self.OnChatMenuCloseClick))
	self.chatMenu = self:GameObject("p_tips_set")
	self.chatMenuItemPin = self:Button("p_item_top", Delegate.GetOrCreate(self, self.OnMenuItemPinClick))
	self.chatMenuItemPinText = self:Text("p_text_top", "chat_sticky")
	self.chatMenuItemDelete = self:Button("p_item_delete", Delegate.GetOrCreate(self, self.OnMenuItemRemoveClick))
	self.chatMenuItemDeleteText = self:Text("p_text_delete", "chat_channelremove")
	self.chatTableHolder = self:GameObject("p_content_chat")
	self.chatTableFullscreenMask = self:Button("p_btn_empty_bottom", Delegate.GetOrCreate(self, self.OnChatTableFullscreenMaskClick))
	self._chatTableHolderOrgOffsetMin = self.chatTableHolder.transform.offsetMin
	self.chatInputPanel = self:GameObject("p_group_bottom")

	-- 快捷回复
	self.quickReplyButton = self:Button("p_btn_quick_reply", Delegate.GetOrCreate(self, self.OnQuickReplyButtonClick))
	self.quickReplyPanel = self:GameObject("p_quick_reply")
	self.quickReplyTable = self:TableViewPro("p_table_quick_reply")

	-- 表情
	self.emojiButton = self:Button("p_btn_emoji", Delegate.GetOrCreate(self, self.OnEmojiButtonClick))
	self.emojiPanel = self:GameObject("p_group_emoji")
	self.emojiTable = self:TableViewPro("p_table_quick_emoji")

	-- 动效
	self.fpTopOpen = self:BindComponent("top_open", typeof(CS.FpAnimation.FpAnimatorTotalCommander))
	self.fpTopClose = self:BindComponent("top_close", typeof(CS.FpAnimation.FpAnimatorTotalCommander))
end

local LoadingTipsModes = {
    None = 1,
    WaitRelease = 2,
    Loading = 3,
    Loaded = 4,
}

function ChatV2UIMediator:OnShow(param)
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
    self.loadingTipsMode = LoadingTipsModes.None
    self:InitData()
    self:RefreshData()
    self:InitUI()
	if param and param.privateChatUid then
		local session = ModuleRefer.ChatModule:GetPrivateSessionByUid(param.privateChatUid)
		if session then
			self:OnGotoSession(session.SessionId)
			return
		end
	end

	self:RefreshUI(true)
end

function ChatV2UIMediator:OnHide(param)
	self._loopListView:SetListItemCount(1, false)
end

function ChatV2UIMediator:IsLoadingWaitRelease()
    return self.loadingTipsMode == LoadingTipsModes.WaitRelease
end

function ChatV2UIMediator:IsLoading()
    return self.loadingTipsMode == LoadingTipsModes.Loading
end

function ChatV2UIMediator:IsLoaded()
    return self.loadingTipsMode == LoadingTipsModes.Loaded
end

---@param param ChatV2UIMediatorOpenContext
function ChatV2UIMediator:OnOpened(param)
    if param and param.openMethod and param.openMethod == 1 and param.privateChatUid then
        local session = ModuleRefer.ChatModule:GetPrivateSessionByUid(param.privateChatUid)
        if session then
			self:OnGotoSession(session.SessionId)
            g_Game.EventManager:TriggerEvent(EventConst.CHAT_GOTO_SESSION, session.SessionId)
        else
            local nickname = ModuleRefer.ChatModule:GetNicknameFromExtInfo(param.extInfo, param.privateChatUid)
            local portrait = ModuleRefer.ChatModule:GetPortraitFromExtInfo(param.extInfo)
            local userInfo = CS.FunPlusChat.Models.UserInfo()
            -- userInfo.Avatar = tostring(portrait)
            userInfo.Avatar = string.format("{p:%s, fp:%s, ca:%s}", param.extInfo.p, param.extInfo.fp, param.extInfo.ca)
            userInfo.Nickname = nickname
            userInfo.Uid = param.privateChatUid
            CS.ChatSdkWrapper.CreateP2P(userInfo, function(newSession)
                g_Logger.TraceChannel("Chat", "********* New session created: %s", newSession.SessionId)
                ModuleRefer.ChatModule:SetNextGotoSessionId(newSession.SessionId)
                g_Game.EventManager:TriggerEvent(EventConst.CHAT_SESSION_LIST_UPDATED)
            end)
        end
    end
end

function ChatV2UIMediator:OnClose(param)
	self:PushCurrentUnsentText()
	ModuleRefer.ChatModule:ClearLastUpdatedSessionId()
	self._loopListView.mOnDragingAction = nil
    self._loopListView.mOnEndDragAction = nil
	g_Game.EventManager:RemoveListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_GOTO_SESSION, Delegate.GetOrCreate(self, self.OnGotoSession))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_SYSTEM_TOAST_CHANGED, Delegate.GetOrCreate(self, self.OnSystemToastChanged))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_CLOSE_PANEL, Delegate.GetOrCreate(self, self.OnCloseSelf))
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_cancel)
end

--- 初始化数据
---@param self ChatV2UIMediator
function ChatV2UIMediator:InitData()
	self._selectedSessionId = nil
	local selectedSession = ModuleRefer.ChatModule:GetSession(ModuleRefer.ChatModule:GetSelectedSessionId())
	local latestSession = ModuleRefer.ChatModule:GetSession(ModuleRefer.ChatModule:GetLastUpdatedSessionId())
	if (selectedSession and not latestSession) then
		self._selectedSessionId = selectedSession.SessionId
	elseif (not selectedSession and latestSession) then
		self._selectedSessionId = latestSession.SessionId
	elseif (selectedSession and latestSession) then
		if (selectedSession.Msg and latestSession.Msg and selectedSession.Msg.MsgTime > latestSession.Msg.MsgTime) then
			self._selectedSessionId = selectedSession.SessionId
		else
			self._selectedSessionId = latestSession.SessionId
		end
	end
end

--- 刷新数据
---@param self ChatV2UIMediator
function ChatV2UIMediator:RefreshData()
	self._channelDataList = {}
	self._channelDataMap = {}

	-- 特殊频道
	local worldSession = ModuleRefer.ChatModule:GetWorldSession()
	local allianceSession = ModuleRefer.ChatModule:GetAllianceSession()
	local toastSession = ModuleRefer.ChatModule:GetSystemToastSession()

	-- 其他频道
	local sessionList = ModuleRefer.ChatModule:GetSessionList()
	for id, session in pairs(sessionList) do
		if ((not worldSession or id ~= worldSession.SessionId)
				and (not allianceSession or id ~= allianceSession.SessionId)
				and (not toastSession or id ~= toastSession.SessionId)
			) then
			local data = {
				sessionId = session.SessionId,
				pinned = ModuleRefer.ChatModule:IsPinned(session.SessionId),
				muted = ModuleRefer.ChatModule:IsMuted(session.SessionId),
				sortValue = session.OperationTime,
				selected = self._selectedSessionId == session.SessionId,
				session = session,
				onClick = Delegate.GetOrCreate(self, self.OnChannelItemClick),
			}
			table.insert(self._channelDataList, data)
			self._channelDataMap[session.SessionId] = data
		end
	end

	-- 系统通知频道
	--[[
	if (toastSession) then
		local data = {
			sessionId = toastSession.SessionId,
			pinned = true,
			sortValue = SORTVALUE_SYSTEM_TOAST,
			selected = self._selectedSessionId == toastSession.SessionId,
			toast = true,
			session = toastSession,
			onClick = Delegate.GetOrCreate(self, self.OnChannelItemClick),
		}
		table.insert(self._channelDataList, 1, data)
		self._channelDataMap[toastSession.SessionId] = data
	end
	--]]

	-- 联盟频道
	if (allianceSession) then
		local data = {
			sessionId = allianceSession.SessionId,
			pinned = true,
			sortValue = SORTVALUE_ALLIANCE,
			selected = self._selectedSessionId == allianceSession.SessionId,
			session = allianceSession,
			onClick = Delegate.GetOrCreate(self, self.OnChannelItemClick),
		}
		table.insert(self._channelDataList, 1, data)
		self._channelDataMap[allianceSession.SessionId] = data
	end

	-- 世界频道
	if (worldSession) then
		local data = {
			sessionId = worldSession.SessionId,
			pinned = true,
			sortValue = SORTVALUE_WORLD,
			selected = self._selectedSessionId == worldSession.SessionId,
			session = worldSession,
			onClick = Delegate.GetOrCreate(self, self.OnChannelItemClick),
		}
		table.insert(self._channelDataList, 1, data)
		self._channelDataMap[worldSession.SessionId] = data
	end

	-- 排序
	table.sort(self._channelDataList, ModuleRefer.ChatModule.SortBySortValueDescWithPin)

	self:EnsureSelectedData()
end

--- 确保选定数据完整性
---@param self ChatV2UIMediator
function ChatV2UIMediator:EnsureSelectedData()
	local session = self._channelDataMap[self._selectedSessionId]
	if ((not session or ModuleRefer.ChatModule:IsIgnoredSession(session.session)) and self._channelDataList[1]) then
		self._selectedSessionId = self._channelDataList[1].session.SessionId
		self._channelDataList[1].selected = true
		ModuleRefer.ChatModule:SetSelectedSessionid(self._selectedSessionId)
	end
end

--- 初始化UI
---@param self ChatV2UIMediator
function ChatV2UIMediator:InitUI()
    self._loopListView:InitListView(1, Delegate.GetOrCreate(self, self.OnGetItemByIndex))
	---@type table<number, {data:table, index:string}>
	self._messageImId2Cache = {}
end

function ChatV2UIMediator:OnGetItemByIndex(loopListView, index)
    if index < 0 then return nil end
    if index == 0 then
        local ret = loopListView:NewListViewItem("p_item_loading")
        self:UpdateLoadingTip(ret)
        return ret
    end

    local sessionId = self._selectedSessionId
    local dataList = self._chatSessionMessageList[sessionId]
    if (not dataList) then return nil end

    local wrap = dataList[index]
    if (not wrap) then return nil end

    local ret = loopListView:NewListViewItem(wrap.index)
    local luaBase = ret.gameObject:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
    if (luaBase) then
        luaBase:FeedData(wrap.data)
    end
    return ret
end

---@param item CS.SuperScrollView.LoopListViewItem2
function ChatV2UIMediator:UpdateLoadingTip(item)
    if item == nil then return end

    local luaComp = item:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
    if luaComp == nil then return end

    ---@type ChatV2LoadingComp
    luaComp:FeedData(self)
end

--- 刷新UI
---@param self ChatV2UIMediator
---@param resetSelected boolean
function ChatV2UIMediator:RefreshUI(resetSelected)
	self:RefreshChannelList(resetSelected)
end

--- 刷新频道列表
---@param self ChatV2UIMediator
---@param selectedChanged boolean
---@param refreshSelected boolean
---@param scrollToEnd boolean
function ChatV2UIMediator:RefreshChannelList(selectedChanged, refreshSelected, scrollToEnd)
	if (refreshSelected == nil) then refreshSelected = true end
	local selectedData = nil
	local gotoData = nil
	local gotoSessionId = ModuleRefer.ChatModule:GetNextGotoSessionId()
	g_Logger.TraceChannel("Chat", "********* RefreshChannelList, nextId: %s, selectedId: %s", gotoSessionId, self._selectedSessionId)
	self.channelTable:Clear()
	for _, data in ipairs(self._channelDataList) do
		---@type CS.FunPlusChat.Models.FPSession
		local session = data.session

		if (session) then
			-- 忽略会话过滤
			local ignored = ModuleRefer.ChatModule:IsIgnoredSession(session)
			
			-- 额外联盟检查
			local allianceCheckPass = true
			if (ModuleRefer.ChatModule:IsAllianceSession(session)) then
				allianceCheckPass = ModuleRefer.AllianceModule:IsInAlliance()
			end

			if (not ignored and allianceCheckPass) then
				if (data.selected) then
					selectedData = data
				end
				if (gotoSessionId) then
					if (data.sessionId == gotoSessionId) then
						gotoData = data
					end
				end
				self.channelTable:AppendData(data)
			end
		end
	end
	if (gotoData) then
		ModuleRefer.ChatModule:SetNextGotoSessionId(nil)
		gotoData.selected = true
		self._selectedSessionId = gotoSessionId
		if (selectedData) then
			selectedData.selected = false
			selectedData = gotoData
		end
	end
	if (selectedData) then
		self.channelTable:SetDataVisable(selectedData)
	end
	self.channelTable:RefreshAllShownItem()
	if (refreshSelected) then
		self:RefreshSelectedSession(selectedChanged, selectedChanged or scrollToEnd)
	end
end

--- 移除加载条目
---@param self ChatV2UIMediator
function ChatV2UIMediator:RemoveLoadingItem()
	self.loadingTipsMode = LoadingTipsModes.None
    local item = self._loopListView:GetShownItemByItemIndex(0)
    self:UpdateLoadingTip(item)
end

--- 刷新选定会话
---@param self ChatV2UIMediator
---@param channelChanged boolean 切换频道
---@param scrollToEnd boolean 是否滚动到末端
function ChatV2UIMediator:RefreshSelectedSession(channelChanged, scrollToEnd)
	if (scrollToEnd == nil) then scrollToEnd = true end

	local session = ModuleRefer.ChatModule:GetSession(self._selectedSessionId)
	if (not session) then
		g_Logger.Error("会话不存在: %s", self._selectedSessionId)
		return
	end
	-- 名称
	self.chatNameText.text = ModuleRefer.ChatModule:GetSessionName(session)
    self._chatSessionMessageList[self._selectedSessionId] = {}

	-- 未读更新
	ModuleRefer.ChatModule:SetSessionUnreadCount(session, 0)

	-- 杂项
	local sp
	self.chatMenuButton.gameObject:SetActive(false)
	local canShowShare = true
	if (ModuleRefer.ChatModule:IsSystemToastSession(session)) then
		sp = ModuleRefer.ChatModule:GetSystemToastSpriteName(true)
		canShowShare = false
	elseif (ModuleRefer.ChatModule:IsWorldSession(session)) then
		sp = ModuleRefer.ChatModule:GetWorldSpriteName(true)
	elseif (ModuleRefer.ChatModule:IsAllianceSession(session)) then
		sp = ModuleRefer.ChatModule:GetAllianceSpriteName(true)
	elseif (ModuleRefer.ChatModule:IsGroupSession(session)) then
		sp = ModuleRefer.ChatModule:GetGroupSpriteName(true)
	else
		sp = ModuleRefer.ChatModule:GetPrivateSpriteName(true)
		self.chatMenuButton.gameObject:SetActive(true)
	end
	g_Game.SpriteManager:LoadSprite(sp, self.chatIcon)

	-- 移除加载条目
	self:RemoveLoadingItem()

	-- 频道切换
	if (channelChanged) then
		self:SetEmojiPanelOpen(false, false)
		self:SetQuickReplyPanelOpen(false, false)
		if (ModuleRefer.ChatModule:IsSystemToastSession(session)) then
			self.chatInputPanel:SetActive(false)
		else
			self.chatInputPanel:SetActive(true)

			-- 缓存的文本
			self:PopCurrentUnsentText()
		end
		self:ReposChatTable(scrollToEnd)
	end

	-- 消息列表
	self._noScrolling = true
	local list = ModuleRefer.ChatModule:GetSessionMessageList(self._selectedSessionId)
	self._lastMsg = nil

	local tableAtEnd = self:IsChatTableAtEnd()
    if list and list[1] then
        for i, wrap in ipairs(list) do
            local data, index = self:GetChatItemData(wrap.message)
            if data and index then
                table.insert(self._chatSessionMessageList[self._selectedSessionId], {data = data, index = index})
            end
        end

        self._lastMsg = list[1].message
    end

	self:TryInsertTimeStampItems()
    local messageCount = #self._chatSessionMessageList[self._selectedSessionId]
    self._loopListView:SetListItemCount(messageCount + 1, false)
	self._loopListView:RefreshAllShownItem()
	self:ScrollToEnd(scrollToEnd or tableAtEnd)

	if (not self._chatTablePulling and messageCount < DEFAULT_MSG_COUNT) then
		if (ModuleRefer.ChatModule:NoMoreMessage(self._selectedSessionId)) then
			return
		end
		self:InsertLoadingItem()
		self._chatTablePulling = true
		ModuleRefer.ChatModule:PullMessages(self._selectedSessionId, self._lastMsg, DEFAULT_MSG_COUNT, function(msgCount)
			self._chatTablePulling = false
			self:RemoveLoadingItem()
			if (msgCount > 0) then
				self:RefreshSelectedSession(false, true)
			end
		end, function(code)
			self:RemoveLoadingItem()
			self._chatTablePulling = false
		end)
	end
	
	self.channelTable:RefreshAllShownItem()
	self._noScrolling = false
end

--- 获取消息条目数据
---@param self ChatV2UIMediator
---@param message CS.FunPlusChat.Models.FPMessage
---@return table, number
function ChatV2UIMediator:GetChatItemData(message)
	if (not message) then return end

	if self._messageImId2Cache[message.ImId] then
		return self._messageImId2Cache[message.ImId].data, self._messageImId2Cache[message.ImId].index
	end

	local data, index = self:GetChatItemDataImp(message)
	if data and index then
		self._messageImId2Cache[message.ImId] = {data = data, index = index}
	end
	return data, index
end

---@private
---@param message CS.FunPlusChat.Models.FPMessage
function ChatV2UIMediator:GetChatItemDataImp(message)
	if message.MsgType == MessageType.Chat then
		return self:GetChatV2PlayerMessageData(message)
	elseif message.MsgType == MessageType.GameSystem then
		local extInfo = ModuleRefer.ChatModule:DecodeJson(message.Attrs)
		if extInfo.oe then
			local entity = g_Game.DatabaseManager:GetEntity(extInfo.oe.e, DBEntityType.Expedition)
			if not entity then
				return
			end
			return self:GetChatV2WorldEventMessageData(message, extInfo)
		elseif extInfo.ar then
			return self:GetChatV2LeagueRecruitMessageData(message, extInfo)
		elseif extInfo.aai then
			return self:GetChatV2LeagueAssembleMessageData(message, extInfo)
		elseif extInfo.s or extInfo.vt or extInfo.si then
			if extInfo.si then
				local overrideExtInfo = extInfo.si.aam
				overrideExtInfo.a = extInfo.si.aam.af.Abbr
				overrideExtInfo.n = extInfo.si.aam.oi.Name
				extInfo = overrideExtInfo
			end

			---@type ShareChatItemParam
			local shareParam = self:CreateChatParam(extInfo)
			if shareParam.type == ChatShareType.Pet then
				return self:GetChatV2SharePetMessageData(message, extInfo, shareParam)
			elseif shareParam.type == ChatShareType.AllianceTask then
				return self:GetChatV2ShareLeagueTaskMessageData(message, extInfo, shareParam)
			else
				return self:GetChatV2ShareCoordMessageData(message, extInfo, shareParam)
			end
		end
	end
end

---@param message CS.FunPlusChat.Models.FPMessage
---@return ChatV2PlayerMessageData, string
function ChatV2UIMediator:GetChatV2PlayerMessageData(message)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = ModuleRefer.ChatModule:DecodeJson(message.Attrs),
		translation = {
			isTranslated = message.TranslatedInfo ~= nil and message.TranslatedInfo.targetLang == ModuleRefer.ChatSDKModule:GetUserLanguage(),
			translating = false,
			showTranslated = false,
		},
		text = ModuleRefer.ChatModule:GetMessageText(message)
	}
	return data, ChatCellTemplate.Message
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@return ChatV2WorldEventMessageData, string
function ChatV2UIMediator:GetChatV2WorldEventMessageData(message, extInfo)
	local data = {
		cfgId = extInfo.oe.c
	}
	return data, ChatCellTemplate.ShareWorldEvent
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@return ChatV2LeagueRecruitMessageData, string
function ChatV2UIMediator:GetChatV2LeagueRecruitMessageData(message, extInfo)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = extInfo,
		recruitParam = {
			allianceId = extInfo.i
		}
	}
	return data, ChatCellTemplate.ShareLeagueRecruit
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@return ChatV2LeagueAssembleMessageData, string
function ChatV2UIMediator:GetChatV2LeagueAssembleMessageData(message, extInfo)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = extInfo,
	}
	return data, ChatCellTemplate.ShareLeagueAssemble
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@param shareParam ShareChatItemParam
---@return ChatV2SharePetMessageData, string
function ChatV2UIMediator:GetChatV2SharePetMessageData(message, extInfo, shareParam)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = extInfo,
		shareParam = shareParam
	}
	return data, ChatCellTemplate.SharePet
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@param shareParam ShareChatItemParam
---@return ChatV2LeagueTaskMessageData, string
function ChatV2UIMediator:GetChatV2ShareLeagueTaskMessageData(message, extInfo, shareParam)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = extInfo,
	}
	return data, ChatCellTemplate.ShareLeagueTask
end

---@param message CS.FunPlusChat.Models.FPMessage
---@param extInfo table @json
---@param shareParam ShareChatItemParam
---@return ChatV2ShareCoordMessageData, string
function ChatV2UIMediator:GetChatV2ShareCoordMessageData(message, extInfo, shareParam)
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
		uid = message.FromId,
		extInfo = extInfo,
		shareParam = shareParam
	}
	return data, ChatCellTemplate.ShareCood
end

---@return 
function ChatV2UIMediator:CreateChatParam(param)
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
    return chatParam
end

--- 获取时间戳条目数据
---@param self ChatV2UIMediator
---@param time number 时间戳
---@return table, number
function ChatV2UIMediator:GetChatTimeStampItemData(time)
	local data = {
		isLoading = false,
		isTimeStamp = true,
		isHint = false,
		time = time,
	}
	return data, ChatCellTemplate.HintAndTimestamp
end

function ChatV2UIMediator:OnBackButtonClick()
	self:CloseSelf()
end

function ChatV2UIMediator:OnChatMenuButtonClick()
	local isPinned = ModuleRefer.ChatModule:IsPinned(self._selectedSessionId)
	if (isPinned) then
		self.chatMenuItemPinText.text = I18N.Get("chat_sticky_cancel")
	else
		self.chatMenuItemPinText.text = I18N.Get("chat_sticky")
	end

	self.chatMenu:SetActive(true)
	self.fpTopOpen:PlayAll()
end

--- 发送文本消息
---@param self ChatV2UIMediator
---@param text string
---@param keepText boolean
function ChatV2UIMediator:SendText(text, keepText)
	if (Utils.IsNullOrEmpty(text)) then return end

	local session = ModuleRefer.ChatModule:GetSession(self._selectedSessionId)
	if (not session) then
		g_Logger.Error("聊天会话 %s 未找到!", self._selectedSessionId)
		return
	end

	local msg = ModuleRefer.ChatModule:CreateTextMessage(session, text)
	if (not msg) then
		g_Logger.Error("聊天文本创建失败!")
		return
	end

	ModuleRefer.ChatSDKModule:Send(msg)
	if (not keepText) then
		self.chatTextInput.text = ""
		ModuleRefer.ChatModule:SetUnsentMessage(self._selectedSessionId, nil)
	end

	local params = {}
	if session:IsGroup() then
		if session.GroupType == CS.FunPlusChat.Models.GroupType.World then
			params[FPXSDKBIDefine.ExtraKey.chat.type] = 0
		elseif session.GroupType == CS.FunPlusChat.Models.GroupType.Alliance then
			params[FPXSDKBIDefine.ExtraKey.chat.type] = 1
			params[FPXSDKBIDefine.ExtraKey.chat.id] = ModuleRefer.AllianceModule:GetAllianceId()
		end
	elseif session:IsP2P() then
		params[FPXSDKBIDefine.ExtraKey.chat.type] = 2
		params[FPXSDKBIDefine.ExtraKey.chat.id] = session.ToId
	end
	
	if table.nums(params) > 0 then
		ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.chat, params)
	end
end

function ChatV2UIMediator:OnChatSendButtonClick(text)
	local stext = text or self.chatTextInput.text
	if (not Utils.IsNullOrEmpty(stext)) then
		stext = CS.ChatSdkWrapper.RemoveRichTextTags(stext)
		stext = string.ltrim(stext)
	end
	if (Utils.IsNullOrEmpty(stext)) then return end
	self:SetQuickReplyPanelOpen(false)
	self:SetEmojiPanelOpen(false)
	self:SendText(stext)
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
end

---@param self ChatV2UIMediator
function ChatV2UIMediator:PushCurrentUnsentText()
	local unsentText = self.chatTextInput.text
	if (not Utils.IsNullOrEmpty(unsentText)) then
		ModuleRefer.ChatModule:SetUnsentMessage(self._selectedSessionId, unsentText)
	end
end

---@param self ChatV2UIMediator
function ChatV2UIMediator:PopCurrentUnsentText()
	local newText = ModuleRefer.ChatModule:GetUnsentMessage(self._selectedSessionId)
	self.chatTextInput.text = newText or ""
end

function ChatV2UIMediator:OnChannelItemClick(sessionId)
	if (Utils.IsNullOrEmpty(sessionId)) then return end
	if (self._selectedSessionId == sessionId) then return end
	local oldData = self._channelDataMap[self._selectedSessionId]
	self:PushCurrentUnsentText()
	local newData = self._channelDataMap[sessionId]
	oldData.selected = false
	oldData.showCloseSelect = true
	oldData.showOpenSelect = false
	newData.selected = true
	newData.showOpenSelect = true
	newData.showCloseSelect = false
	self._selectedSessionId = sessionId
	self:RefreshChannelList(true)
	ModuleRefer.ChatModule:SetSelectedSessionid(self._selectedSessionId)
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function ChatV2UIMediator:OnSessionListUpdated()
	self:RefreshData()
	self:RefreshUI(true)
end

---@param self ChatV2UIMediator
---@param data table
function ChatV2UIMediator:OnMessageUpdated(data)
	if (not data) then return end

	local channelData = self._channelDataMap[data.sessionId]
	local msg = ModuleRefer.ChatModule:GetMessage(data.imId)
	local session = ModuleRefer.ChatModule:GetSession(data.sessionId)
	if (not channelData or not msg or not session) then return end

	if (not ModuleRefer.ChatModule:IsWorldSession(session) and not ModuleRefer.ChatModule:IsAllianceSession(session)) then
		channelData.sortValue = msg.MsgTime
		table.sort(self._channelDataList, ModuleRefer.ChatModule.SortBySortValueDescWithPin)
	end
	self:RefreshChannelList(false,
			data.sessionId == self._selectedSessionId,
			ModuleRefer.ChatModule:IsSelfMessage(msg))
end

--- 插入加载条目
---@param self ChatV2UIMediator
function ChatV2UIMediator:InsertLoadingItem()
	self.loadingTipsMode = LoadingTipsModes.Loading
    local item = self._loopListView:GetShownItemByItemIndex(0)
    self:UpdateLoadingTip(item)
end

function ChatV2UIMediator:OnChatTableScrolling()
	if self._noScrolling then return end    
    if self._loopListView.ShownItemCount == 0 then return end
    if self.loadingTipsMode ~= LoadingTipsModes.None and self.loadingTipsMode ~= LoadingTipsModes.WaitRelease then return end

    local firstItem = self._loopListView:GetShownItemByItemIndex(0)
    if firstItem == nil then return end

    local scrollRect = self._loopListView.ScrollRect
    local pos = scrollRect.content.anchoredPosition3D
    if pos.y < -40 then
        if self.loadingTipsMode ~= LoadingTipsModes.None then
            return
        end

        self.loadingTipsMode = LoadingTipsModes.WaitRelease
        self:UpdateLoadingTip(firstItem)
        firstItem.CachedRectTransform.anchoredPosition3D = CS.UnityEngine.Vector3(0, 40, 0)
    else
        if self.loadingTipsMode ~= LoadingTipsModes.WaitRelease then
            return
        end

        self.loadingTipsMode = LoadingTipsModes.None
        self:UpdateLoadingTip(firstItem)
        firstItem.CachedRectTransform.anchoredPosition3D = CS.UnityEngine.Vector3.zero
    end
end

function ChatV2UIMediator:OnChatTableScrollEnd()
	if (self._noScrolling) then return end

    if self._loopListView.ShownItemCount == 0 then return end
    if self.loadingTipsMode ~= LoadingTipsModes.None and self.loadingTipsMode ~= LoadingTipsModes.WaitRelease then return end
    local firstItem = self._loopListView:GetShownItemByItemIndex(0)
    if firstItem == nil then return end
    self._loopListView:OnItemSizeChanged(0)
    if self.loadingTipsMode == LoadingTipsModes.None then return end
    self:InsertLoadingItem()

	-- 拉取消息
	if (not self._chatTablePulling) then
		if (ModuleRefer.ChatModule:NoMoreMessage(self._selectedSessionId)) then
            self:RemoveLoadingItem()
            self._loopListView:OnItemSizeChanged(0)
			return
		end

		self._chatTablePulling = true
		ModuleRefer.ChatModule:PullMessages(self._selectedSessionId, self._lastMsg, DEFAULT_MSG_COUNT, function(count)
			if count > 0 then
				self:RefreshSelectedSession(false, false)
			end
            self:RemoveLoadingItem()
            self._loopListView:OnItemSizeChanged(0)
			self._chatTablePulling = false
		end, function(code)
			self:RemoveLoadingItem()
            self._loopListView:OnItemSizeChanged(0)
            self._chatTablePulling = false
		end)
	end
end

--- 判断聊天窗口当前是不是在最底端
---@param self ChatV2UIMediator
---@return boolean
function ChatV2UIMediator:IsChatTableAtEnd()
    if (self._loopListView.ItemTotalCount == 0) then return true end
	return self._loopListView:GetShownItemByItemIndex(self._loopListView.ItemTotalCount - 1) ~= nil
end

--- 尝试插入时间戳条目
---@param self ChatV2UIMediator
function ChatV2UIMediator:TryInsertTimeStampItems()
	if (not self._loopListView) then return end

    local messageList = self._chatSessionMessageList[self._selectedSessionId]
    if #messageList == 0 then return end

    local firstMessage = messageList[1]
	for i = #messageList, 2, -1 do
		local dataPrev = messageList[i-1]
		local dataCur = messageList[i]
		if (dataCur.data.time and dataPrev.data.time) then
			if (dataCur.data.time - dataPrev.data.time >= TIMESTAMP_MIN_DELTA) then
				local data, index = self:GetChatTimeStampItemData(dataCur.data.time)
				table.insert(messageList, i, {
					data = data,
					index = index,
				})
			end
		end
	end

	local data, index = self:GetChatTimeStampItemData(firstMessage.data.time)
	table.insert(messageList, 1, {
        data = data,
        index = index,
    })
end

--- 跳转到会话
---@param self ChatV2UIMediator
---@param sessionId string
function ChatV2UIMediator:OnGotoSession(sessionId)
	if (self._selectedSessionId == sessionId) then return end
	self._selectedSessionId = sessionId
	self:RefreshData()
	self:RefreshChannelList(true)
end

function ChatV2UIMediator:OnMenuItemPinClick()
	self.chatMenu:SetActive(false)
	local isPinned = ModuleRefer.ChatModule:IsPinned(self._selectedSessionId)
	if (isPinned) then
		-- 取消置顶
		ModuleRefer.ChatModule:RemoveFromPinnedSessionList(self._selectedSessionId)
	else
		-- 置顶
		ModuleRefer.ChatModule:AddToPinnedSessionList(self._selectedSessionId)
	end
	self:RefreshData()
	self:RefreshChannelList(false, false)
end

function ChatV2UIMediator:OnMenuItemRemoveClick()
	self.chatMenu:SetActive(false)
	CS.FunPlusChat.FPChatSdk.RemoveSession(self._selectedSessionId)
end

function ChatV2UIMediator:OnChatMenuCloseClick()
	self.fpTopClose:PlayAll(function()
		self.chatMenu:SetActive(false)
	end)
end

--- 聊天窗口滚动到底端
---@param self ChatV2UIMediator
---@param force boolean
function ChatV2UIMediator:ScrollToEnd(force)
	if (force or self:IsChatTableAtEnd()) then
        if (self._loopListView.ItemTotalCount > 0) then
		    self._loopListView:MovePanelToItemIndex(self._loopListView.ItemTotalCount - 1, 0)
        end
	end
end

---@param self ChatV2UIMediator
---@param scrollToEnd boolean
function ChatV2UIMediator:ReposChatTable(scrollToEnd)
	if (scrollToEnd == nil) then scrollToEnd = true end
	local bottom = self._chatTableHolderOrgOffsetMin.y
	if (self.quickReplyPanel.activeInHierarchy) then
		bottom = bottom + self.quickReplyPanel.transform.rect.height
	elseif (self.emojiPanel.activeInHierarchy) then
		bottom = bottom + self.emojiPanel.transform.rect.height
	end
	if (not self.chatInputPanel.activeInHierarchy) then
		bottom = bottom - self.chatInputPanel.transform.rect.height
	end
	self.chatTableHolder.transform.offsetMin = CS.UnityEngine.Vector2(self._chatTableHolderOrgOffsetMin.x, bottom)
	self._loopListView:ResetListView(true)
	self.chatTableScrollRect.vertical = true
	if (scrollToEnd) then
		self:ScrollToEnd(true)
	end
end

function ChatV2UIMediator:OnQuickReplyButtonClick()
	if (self:SetQuickReplyPanelOpen(not self.quickReplyPanel.activeSelf)) then
		self:RefreshQuickReplyTable()
	end
end

--- 获取快捷回复文本列表
---@param self ChatV2UIMediator
---@return table<string>
function ChatV2UIMediator:GetQuickReplyTextTable()
	local session = ModuleRefer.ChatModule:GetSession(self._selectedSessionId)
	local result = {}
	if (not session) then return result end
	if (ModuleRefer.ChatModule:IsWorldSession(session)) then
		for i = 1, ConfigRefer.ConstMain:ChatQuickReplyWorldLength() do
			table.insert(result, I18N.Get(ConfigRefer.ConstMain:ChatQuickReplyWorld(i)))
		end
	elseif (ModuleRefer.ChatModule:IsAllianceSession(session)) then
		for i = 1, ConfigRefer.ConstMain:ChatQuickReplyAllianceLength() do
			table.insert(result, I18N.Get(ConfigRefer.ConstMain:ChatQuickReplyAlliance(i)))
		end
	else
		for i = 1, ConfigRefer.ConstMain:ChatQuickReplyPrivateLength() do
			table.insert(result, I18N.Get(ConfigRefer.ConstMain:ChatQuickReplyPrivate(i)))
		end
	end
	return result
end

--- 刷新快捷回复表
---@param self ChatV2UIMediator
function ChatV2UIMediator:RefreshQuickReplyTable()
	local textTable = self:GetQuickReplyTextTable()
	self.quickReplyTable:Clear()
	local session = ModuleRefer.ChatModule:GetSession(self._selectedSessionId)
	if ModuleRefer.AllianceModule:IsAllianceLeader() and ModuleRefer.ChatModule:IsWorldSession(session) then
		self.quickReplyTable:AppendData({}, 1)
	end
	for _, text in pairs(textTable) do
		local data = {
			text = I18N.Get(text),
			onClick = Delegate.GetOrCreate(self, self.OnQuickReplyItemClick),
		}
		self.quickReplyTable:AppendData(data, 0)
	end
end

--- 快捷回复条目点击
---@param self ChatV2UIMediator
---@param text string
function ChatV2UIMediator:OnQuickReplyItemClick(text)
	self:SetQuickReplyPanelOpen(false)
	self:SendText(text, true)
end

function ChatV2UIMediator:RefreshEmojiTable()
	if (self._emojiTableGenerated) then return end

	EMOJI_INDEX_END = ConfigRefer.ConstMain.ChatEmojiMaxIndex and ConfigRefer.ConstMain:ChatEmojiMaxIndex() or EMOJI_INDEX_END
	self.emojiTable:Clear()
	for i = EMOJI_INDEX_START, EMOJI_INDEX_END do
		local data = {
			sprite = string.format(EMOJI_SPRITE_FORMAT, i),
			text = string.format(EMOJI_TEXT_FORMAT, i),
			onClick = Delegate.GetOrCreate(self, self.OnEmojiItemClick),
		}
		self.emojiTable:AppendData(data)
	end

	self._emojiTableGenerated = true
end

function ChatV2UIMediator:OnEmojiButtonClick()
	if (self:SetEmojiPanelOpen(not self.emojiPanel.activeSelf)) then
		self:RefreshEmojiTable()
	end
end

function ChatV2UIMediator:OnEmojiItemClick(text)
	-- 最大长度检查
	local max = self.chatTextInput.characterLimit
	local ins = string.len(text)
	local now = string.len(self.chatTextInput.text)
	if (now + ins > max) then return end
	
	self.chatTextInput.text = self.chatTextInput.text .. text
end

--- 设置快捷回复面板开启状态
---@param self ChatV2UIMediator
---@param open boolean
---@param repos boolean
---@return boolean
function ChatV2UIMediator:SetQuickReplyPanelOpen(open, repos)
	if (repos == nil) then repos = true end
	if (self.quickReplyPanel.activeSelf == open) then return false end
	self.quickReplyPanel:SetActive(open)
	if (open) then
		self.chatTableFullscreenMask.gameObject:SetActive(true)
		if (self.emojiPanel.activeSelf) then
			self:SetEmojiPanelOpen(false, false)
		end
		g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
	else
		self.chatTableFullscreenMask.gameObject:SetActive(self.emojiPanel.activeSelf)
	end
	if (repos) then
		self:ReposChatTable()
	end
	return open
end

--- 设置表情面板开启状态
---@param self ChatV2UIMediator
---@param open boolean
---@param repos boolean
---@return boolean
function ChatV2UIMediator:SetEmojiPanelOpen(open, repos)
	if (repos == nil) then repos = true end
	if (self.emojiPanel.activeSelf == open) then return false end
	self.emojiPanel:SetActive(open)
	if (open) then
		self.chatTableFullscreenMask.gameObject:SetActive(true)
		if (self.quickReplyPanel.activeSelf) then
			self:SetQuickReplyPanelOpen(false, false)
		end
		g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
	else
		self.chatTableFullscreenMask.gameObject:SetActive(self.quickReplyPanel.activeSelf)
	end
	if (repos) then
		self:ReposChatTable()
	end
	return open
end

function ChatV2UIMediator:OnChatTableFullscreenMaskClick()
	self.chatTableFullscreenMask.gameObject:SetActive(false)
	self:SetQuickReplyPanelOpen(false)
	self:SetEmojiPanelOpen(false)
end

function ChatV2UIMediator:OnSystemToastChanged()
	if (self._selectedSessionId == ModuleRefer.ChatModule:GetSystemToastSessionId()) then
		self:RefreshSelectedSession(false, true)
	end
end

function ChatV2UIMediator:OnCloseSelf()
	self:CloseSelf()
end

return ChatV2UIMediator
