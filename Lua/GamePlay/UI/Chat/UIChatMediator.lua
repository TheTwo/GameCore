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

---@class UIChatMediatorOpenContext
---@field openMethod number @nil,0 - normal, 1- privateChat
---@field privateChatUid number
---@field extInfo table|nil

---@class UIChatMediator : BaseUIMediator
local UIChatMediator = class('UIChatMediator', BaseUIMediator)

local MessageType = CS.FunPlusChat.Models.MessageType
--local SessionType = CS.FunPlusChat.Models.SessionType
local GroupType = CS.FunPlusChat.Models.GroupType

local CHAT_ITEM_INDEX_INVALID = -1
local CHAT_ITEM_INDEX_OTHER = 0
local CHAT_ITEM_INDEX_SELF = 1
local CHAT_ITEM_INDEX_HINT = 2
local CHAT_ITEM_INDEX_LOADING = 3

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

--local GROUP_TYPE_GVE = GroupType.SELFDEF_110

function UIChatMediator:ctor()
	self._selectedSessionId = nil
	self._channelDataList = {}
	self._channelDataMap = {}
	self._chatTableIdMap = {}
	self._chatTablePulling = false
	---@type CS.FunPlusChat.Models.FPMessage
	self._lastMsg = nil
	self._emojiTableGenerated = false
	self._noScrolling = false
end

function UIChatMediator:OnCreate()
	DEFAULT_MSG_COUNT, TIMESTAMP_MIN_DELTA, MESSAGE_MAX_LENGTH = ModuleRefer.ChatModule:GetMainConfigs()
	g_Game.EventManager:AddListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:AddListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))
	g_Game.EventManager:AddListener(EventConst.CHAT_GOTO_SESSION, Delegate.GetOrCreate(self, self.OnGotoSession))
	g_Game.EventManager:AddListener(EventConst.CHAT_SYSTEM_TOAST_CHANGED, Delegate.GetOrCreate(self, self.OnSystemToastChanged))
	g_Game.EventManager:AddListener(EventConst.CHAT_CLOSE_PANEL, Delegate.GetOrCreate(self, self.OnCloseSelf))
    self:InitObjects()
end

function UIChatMediator:InitObjects()
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
	self.chatTable = self:TableViewPro("p_table_chat")
	---@type CS.UnityEngine.UI.ScrollRect
	self.chatTableScrollRect = self:BindComponent("p_table_chat", typeof(CS.UnityEngine.UI.ScrollRect))
	self.chatTable.OnScrollRectEndAction = Delegate.GetOrCreate(self, self.OnChatTableScrollEnd)
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

	-- 计算条目大小
	---@type UIChatSizeProvider
	self.sizeCalculator = self:LuaObject("p_size_calculator")
end


function UIChatMediator:OnShow(param)
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
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

function UIChatMediator:OnHide(param)
end

---@param param UIChatMediatorOpenContext
function UIChatMediator:OnOpened(param)
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

function UIChatMediator:OnClose(param)
	self:PushCurrentUnsentText()
	ModuleRefer.ChatModule:ClearLastUpdatedSessionId()
	self.chatTable.OnScrollRectEndAction = nil
	g_Game.EventManager:RemoveListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_GOTO_SESSION, Delegate.GetOrCreate(self, self.OnGotoSession))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_SYSTEM_TOAST_CHANGED, Delegate.GetOrCreate(self, self.OnSystemToastChanged))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_CLOSE_PANEL, Delegate.GetOrCreate(self, self.OnCloseSelf))
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_cancel)
end

--- 初始化数据
---@param self UIChatMediator
function UIChatMediator:InitData()
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
---@param self UIChatMediator
function UIChatMediator:RefreshData()
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
---@param self UIChatMediator
function UIChatMediator:EnsureSelectedData()
	local session = self._channelDataMap[self._selectedSessionId]
	if ((not session or ModuleRefer.ChatModule:IsIgnoredSession(session.session)) and self._channelDataList[1]) then
		self._selectedSessionId = self._channelDataList[1].session.SessionId
		self._channelDataList[1].selected = true
		ModuleRefer.ChatModule:SetSelectedSessionid(self._selectedSessionId)
	end
end

--- 初始化UI
---@param self UIChatMediator
function UIChatMediator:InitUI()

end

--- 刷新UI
---@param self UIChatMediator
---@param resetSelected boolean
function UIChatMediator:RefreshUI(resetSelected)
	self:RefreshChannelList(resetSelected)
end

--- 刷新频道列表
---@param self UIChatMediator
---@param selectedChanged boolean
---@param refreshSelected boolean
---@param scrollToEnd boolean
function UIChatMediator:RefreshChannelList(selectedChanged, refreshSelected, scrollToEnd)
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
---@param self UIChatMediator
function UIChatMediator:RemoveLoadingItem()
	if (self.chatTable and self.chatTable.DataCount > 0) then
		local data = self.chatTable:GetDataByIndex(0)
		if (data and data.isLoading) then
			self.chatTable:RemAt(0)
		end
	end
	self.chatTable:RefreshAllShownItem()
end

--- 刷新选定会话
---@param self UIChatMediator
---@param channelChanged boolean 切换频道
---@param scrollToEnd boolean 是否滚动到末端
function UIChatMediator:RefreshSelectedSession(channelChanged, scrollToEnd)
	if (scrollToEnd == nil) then scrollToEnd = true end

	local session = ModuleRefer.ChatModule:GetSession(self._selectedSessionId)
	if (not session) then
		g_Logger.Error("会话不存在: %s", self._selectedSessionId)
		return
	end

	-- 名称
	self.chatNameText.text = ModuleRefer.ChatModule:GetSessionName(session)

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
	if (channelChanged) then
		self.chatTable:Clear()
		if (list and list[1]) then
			for _, item in ipairs(list) do
				local data, index = self:GetChatItemData(item.message)
				if (data and index) then
					if canShowShare or not data.isShare then
						local width, height = self.sizeCalculator:GetSize(data, index)
						self.chatTable:AppendDataEx(data, width, height, index)
					end
				end
			end
			self._lastMsg = list[1].message
		end
	else
		self._lastMsg = self:MergeIntoChatList(list)
	end

	self:TryInsertTimeStampItems()
	self:ScrollToEnd(scrollToEnd or tableAtEnd)

	if (not self._chatTablePulling and self.chatTable.DataCount < DEFAULT_MSG_COUNT) then
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
---@param self UIChatMediator
---@param message CS.FunPlusChat.Models.FPMessage
---@return table, number
function UIChatMediator:GetChatItemData(message)
	if (not message) then return end
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
	}
	local text = ModuleRefer.ChatModule:GetMessageText(message)
	data.text = text
	local extInfo = ModuleRefer.ChatModule:DecodeJson(message.Attrs)

	if (message.isToast) then
		-- 系统通知
		data.isToast = true
		data.toast = message.toast
		return data, CHAT_ITEM_INDEX_OTHER
	elseif (message.MsgType == MessageType.Chat) then
		-- 普通消息
		data.isToast = false
		data.isLoading = false
		data.isTimeStamp = false
		data.isHint = false
		data.uid = message.FromId
		data.extInfo = extInfo
		data.translation = {
			isTranslated = message.TranslatedInfo ~= nil and message.TranslatedInfo.targetLang == ModuleRefer.ChatSDKModule:GetUserLanguage(),
			translating = false,
			showTranslated = false,
		}
	elseif (message.MsgType == MessageType.GameSystem) then
		-- 系统消息
		if extInfo.s or extInfo.vt then
			data.isToast = false
			data.isShare = true
			data.uid = message.FromId
			data.extInfo = extInfo
			return data, self:GetChatShareItemIndex(message)
		elseif extInfo.oe then
			local entity = g_Game.DatabaseManager:GetEntity(extInfo.oe.e, DBEntityType.Expedition)
			if not entity then
				return
			end
			data.isWorldEvent = true
			data.uid = message.FromId
			data.extInfo = extInfo
			data.cfgId = extInfo.oe.c
			data.ExpeditionEntityId = extInfo.oe.e
			return data, self:GetChatShareItemIndex(message)
		elseif extInfo.ar then
			data.isToast = false
			data.isShare = false
			data.uid = message.FromId
			data.extInfo = extInfo
			data.isAllianceRecruit = true
			data.allianceId = extInfo.i
			return data, self:GetChatShareItemIndex(message)
		elseif extInfo.si then
			data.isToast = false
			data.isShare = true
			data.uid = message.FromId
			data.extInfo = extInfo.si.aam
			data.extInfo.a = extInfo.si.aam.af.Abbr
			data.extInfo.n = extInfo.si.aam.oi.Name
			return data, self:GetChatShareItemIndex(message)
		elseif extInfo.aai then
			data.iaAllianceAssemble = true
			data.extInfo = extInfo
			return data, self:GetChatShareItemIndex(message)
		else
			local suc = text ~= nil
			data.isToast = false
			data.isLoading = false
			data.isTimeStamp = false
			data.isHint = true
			if (not suc) then
				g_Logger.TraceChannel("Chat", "系统消息解析错误: %s", extInfo)
				return
			end
			return data, CHAT_ITEM_INDEX_HINT
		end
	else
		-- 不支持的消息
		return
	end
	return data, self:GetChatItemIndex(message)
end

--- 获取本地信息条目数据
---@param self UIChatMediator
---@param text string
function UIChatMediator:GetLocalInfoItemData(text)
	local data = {
		isLoading = false,
		isTimeStamp = false,
		isHint = true,
		text = text,
	}
	return data, CHAT_ITEM_INDEX_HINT
end

--- 获取加载条目数据
---@param self UIChatMediator
---@return table, number
function UIChatMediator:GetChatLoadingItemData()
	local data = {
		isLoading = true,
	}
	return data, CHAT_ITEM_INDEX_LOADING
end

--- 获取时间戳条目数据
---@param self UIChatMediator
---@param time number 时间戳
---@return table, number
function UIChatMediator:GetChatTimeStampItemData(time)
	local data = {
		isLoading = false,
		isTimeStamp = true,
		isHint = false,
		time = time,
	}
	return data, CHAT_ITEM_INDEX_HINT
end

---@param self UIChatMediator
---@param message CS.FunPlusChat.Models.FPMessage
function UIChatMediator:GetChatItemIndex(message)
	if (not message) then return CHAT_ITEM_INDEX_INVALID end
	if (ModuleRefer.ChatModule:IsSelfMessage(message)) then
		return CHAT_ITEM_INDEX_SELF
	else
		return CHAT_ITEM_INDEX_OTHER
	end
end

---@param self UIChatMediator
---@param message CS.FunPlusChat.Models.FPMessage
function UIChatMediator:GetChatShareItemIndex(message)
	if (not message) then return CHAT_ITEM_INDEX_INVALID end
	if (ModuleRefer.ChatModule:IsSelfShareMessage(message)) then
		return CHAT_ITEM_INDEX_SELF
	else
		return CHAT_ITEM_INDEX_OTHER
	end
end

function UIChatMediator:OnBackButtonClick()
	self:CloseSelf()
end

function UIChatMediator:OnChatMenuButtonClick()
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
---@param self UIChatMediator
---@param text string
---@param keepText boolean
function UIChatMediator:SendText(text, keepText)
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

function UIChatMediator:OnChatSendButtonClick(text)
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

---@param self UIChatMediator
function UIChatMediator:PushCurrentUnsentText()
	local unsentText = self.chatTextInput.text
	if (not Utils.IsNullOrEmpty(unsentText)) then
		ModuleRefer.ChatModule:SetUnsentMessage(self._selectedSessionId, unsentText)
	end
end

---@param self UIChatMediator
function UIChatMediator:PopCurrentUnsentText()
	local newText = ModuleRefer.ChatModule:GetUnsentMessage(self._selectedSessionId)
	self.chatTextInput.text = newText or ""
end

function UIChatMediator:OnChannelItemClick(sessionId)
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

function UIChatMediator:OnSessionListUpdated()
	self:RefreshData()
	self:RefreshUI(true)
end

---@param self UIChatMediator
---@param data table
function UIChatMediator:OnMessageUpdated(data)
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
---@param self UIChatMediator
function UIChatMediator:InsertLoadingItem()
	local data, index = self:GetChatLoadingItemData()
	local width, height = self.sizeCalculator:GetSize(data, index)
	self.chatTable:InsertBeforeHeadWithOutMove(data, width, height, index)
	--Utils.TableViewProScrollToHome(self.chatTable, true)
end

function UIChatMediator:InsertNoMoreMessageItem()
	if (not self.chatTable) then return end
	if (self.chatTable.DataCount > 0) then
		local oldData = self.chatTable:GetDataByIndex(0)
		if (oldData and oldData.noMoreMessage) then return end
	end
	local data, index = self:GetLocalInfoItemData(I18N.Temp().hint_no_more_message)
	data.noMoreMessage = true
	local width, height = self.sizeCalculator:GetSize(data, index)
	self.chatTable:InsertBeforeHeadWithOutMove(data, width, height, index)
	self.chatTable:RefreshAllShownItem()
end

function UIChatMediator:OnChatTableScrollEnd()
	if (self._noScrolling) then return end

	local pos = self.chatTable.ScrollRect:GetContentTrans():GetAnchoredPos()
	--local height = self.chatTable.ScrollRect:GetContentTrans().Height

	-- 拉取消息
	if (pos.y <= 0 and not self._chatTablePulling) then
		if (ModuleRefer.ChatModule:NoMoreMessage(self._selectedSessionId)) then
			return
		end
		self:InsertLoadingItem()
		self._chatTablePulling = true
		ModuleRefer.ChatModule:PullMessages(self._selectedSessionId, self._lastMsg, DEFAULT_MSG_COUNT, function(count)
			if (count == 0) then
				self:RemoveLoadingItem()
			else
				local oldAnchordPos = self.chatTable.ScrollRect:GetContentTrans():GetAnchoredPos()
				local oldContentHeight = self.chatTable.ScrollRect:GetContentTrans().Height
				local offset = oldContentHeight - oldAnchordPos.y
				self:RefreshSelectedSession(false, false)
				local newContentHeight = self.chatTable.ScrollRect:GetContentTrans().Height
				local newAnchordPos = CS.UnityEngine.Vector2(0, newContentHeight - offset)
				self.chatTable:SetContentPos(newAnchordPos)
			end
			self._chatTablePulling = false
		end, function(code)
			self:RemoveLoadingItem()
			self._chatTablePulling = false
		end)
	end
end

--- 判断聊天窗口当前是不是在最底端
---@param self UIChatMediator
---@return boolean
function UIChatMediator:IsChatTableAtEnd()
	if (self.chatTable.DataCount == 0) then return true end
	return self.chatTable:IsDataVisable(self.chatTable.DataCount - 1, false)
end

--- 清除时间戳条目
---@param self UIChatMediator
function UIChatMediator:ClearTimeStampItems(refresh)
	if (not self.chatTable or self.chatTable.DataCount == 0) then return end
	if (refresh == nil) then refresh = true end
	for i = self.chatTable.DataCount - 1, 0, -1 do
		local data = self.chatTable:GetDataByIndex(i)
		if (data and data.isTimeStamp) then
			self.chatTable:RemAt(i)
		end
	end
	if (refresh) then
		self.chatTable:RefreshAllShownItem()
	end
end

--- 尝试插入时间戳条目
---@param self UIChatMediator
function UIChatMediator:TryInsertTimeStampItems(remove)
	if (remove) then
		self:ClearTimeStampItems(false)
	end
	if (not self.chatTable) then return end
	local pendingItems = {}
	for i = self.chatTable.DataCount - 2, 0, -1 do
		local dataPrev = self.chatTable:GetDataByIndex(i)
		local dataCur = self.chatTable:GetDataByIndex(i + 1)
		if (dataCur.time and dataPrev.time) then
			if (dataCur.time - dataPrev.time >= TIMESTAMP_MIN_DELTA) then
				local data, index = self:GetChatTimeStampItemData(dataCur.time)
				table.insert(pendingItems, {
					data = data,
					prefabIndex = index,
					index = i + 1,
				})
			end
		end
	end
	for _, item in ipairs(pendingItems) do
		local width, height = self.sizeCalculator:GetSize(item.data, item.prefabIndex)
		self.chatTable:InsertData(item.index, item.data, width, height, item.prefabIndex, -1, 0)
	end
	if (self.chatTable.DataCount == 0) then return end
	local firstData = self.chatTable:GetDataByIndex(0)
	local data, index = self:GetChatTimeStampItemData(firstData.time)
	local width, height = self.sizeCalculator:GetSize(data, index)
	self.chatTable:InsertBeforeHeadWithOutMove(data, width, height, index)
	self.chatTable:RefreshAllShownItem()
end

--- 跳转到会话
---@param self UIChatMediator
---@param sessionId string
function UIChatMediator:OnGotoSession(sessionId)
	if (self._selectedSessionId == sessionId) then return end
	self._selectedSessionId = sessionId
	self:RefreshData()
	self:RefreshChannelList(true)
end

function UIChatMediator:OnMenuItemPinClick()
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

function UIChatMediator:OnMenuItemRemoveClick()
	self.chatMenu:SetActive(false)
	CS.FunPlusChat.FPChatSdk.RemoveSession(self._selectedSessionId)
end

function UIChatMediator:OnChatMenuCloseClick()
	self.fpTopClose:PlayAll(function()
		self.chatMenu:SetActive(false)
	end)
end

--- 聊天窗口滚动到底端
---@param self UIChatMediator
---@param force boolean
function UIChatMediator:ScrollToEnd(force)
	if (force or self:IsChatTableAtEnd()) then
		Utils.TableViewProScrollToEnd(self.chatTable)
	end
end

---@param self UIChatMediator
---@param scrollToEnd boolean
function UIChatMediator:ReposChatTable(scrollToEnd)
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
	self.chatTable:InitViewRectSize(true)
	self.chatTableScrollRect.vertical = true
	if (scrollToEnd) then
		self:ScrollToEnd(true)
	end
end

function UIChatMediator:OnQuickReplyButtonClick()
	if (self:SetQuickReplyPanelOpen(not self.quickReplyPanel.activeSelf)) then
		self:RefreshQuickReplyTable()
	end
end

--- 获取快捷回复文本列表
---@param self UIChatMediator
---@return table<string>
function UIChatMediator:GetQuickReplyTextTable()
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
---@param self UIChatMediator
function UIChatMediator:RefreshQuickReplyTable()
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
---@param self UIChatMediator
---@param text string
function UIChatMediator:OnQuickReplyItemClick(text)
	self:SetQuickReplyPanelOpen(false)
	self:SendText(text, true)
end

function UIChatMediator:RefreshEmojiTable()
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

function UIChatMediator:OnEmojiButtonClick()
	if (self:SetEmojiPanelOpen(not self.emojiPanel.activeSelf)) then
		self:RefreshEmojiTable()
	end
end

function UIChatMediator:OnEmojiItemClick(text)
	-- 最大长度检查
	local max = self.chatTextInput.characterLimit
	local ins = string.len(text)
	local now = string.len(self.chatTextInput.text)
	if (now + ins > max) then return end
	
	self.chatTextInput.text = self.chatTextInput.text .. text
end

--- 设置快捷回复面板开启状态
---@param self UIChatMediator
---@param open boolean
---@param repos boolean
---@return boolean
function UIChatMediator:SetQuickReplyPanelOpen(open, repos)
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
---@param self UIChatMediator
---@param open boolean
---@param repos boolean
---@return boolean
function UIChatMediator:SetEmojiPanelOpen(open, repos)
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

function UIChatMediator:OnChatTableFullscreenMaskClick()
	self.chatTableFullscreenMask.gameObject:SetActive(false)
	self:SetQuickReplyPanelOpen(false)
	self:SetEmojiPanelOpen(false)
end

---@param self UIChatMediator
---@param list table
function UIChatMediator:MergeIntoChatList(list)
	if (not list or #list == 0) then
		return nil
	end
	self:ClearTimeStampItems(false)
	local tableIndex = self.chatTable.DataCount - 1
	local listIndex = #list
	while (listIndex > 0) do
		---@type CS.FunPlusChat.Models.FPMessage
		local listMsg = list[listIndex].message
		local dt, idx = self:GetChatItemData(listMsg)
		if (tableIndex < 0) then
			local width, height = self.sizeCalculator:GetSize(dt, idx)
			self.chatTable:InsertBeforeHeadWithOutMove(dt, width, height, idx)
			listIndex = listIndex - 1
		else
			local tableData = self.chatTable:GetDataByIndex(tableIndex)
			if (tableData.imId == listMsg.ImId) then
				tableIndex = tableIndex - 1
				listIndex = listIndex - 1
			else
				if (listMsg.MsgTime > tableData.time) then
					local width, height = self.sizeCalculator:GetSize(dt, idx)
					self.chatTable:InsertData(tableIndex + 1, dt, width, height, idx, -1, 0)
					listIndex = listIndex - 1
				else
					tableIndex = tableIndex - 1
				end
			end
		end
	end
	return list[1].message
end

function UIChatMediator:OnSystemToastChanged()
	if (self._selectedSessionId == ModuleRefer.ChatModule:GetSystemToastSessionId()) then
		self:RefreshSelectedSession(false, true)
	end
end

function UIChatMediator:OnCloseSelf()
	self:CloseSelf()
end

return UIChatMediator
