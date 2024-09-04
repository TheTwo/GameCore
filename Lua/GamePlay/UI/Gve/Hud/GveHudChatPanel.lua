local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local SessionType = CS.FunPlusChat.Models.SessionType
local GroupType = CS.FunPlusChat.Models.GroupType
local MessageType = CS.FunPlusChat.Models.MessageType
local Utils = require('Utils')
local UIHelper = CS.DragonReborn.UI.UIHelper
---@class GveHudChatPanel : BaseUIComponent
---@field sessionId string
local GveHudChatPanel = class('GveHudChatPanel', BaseUIComponent)

-- local DEFAULT_MSG_COUNT = 20
-- local TIMESTAMP_MIN_DELTA = 300000	-- 5分钟(ms)
local MESSAGE_MAX_LENGTH = 40

function GveHudChatPanel:ctor()
    self.panelExtended = false
    self.chatModule = ModuleRefer.ChatModule	
end

function GveHudChatPanel:OnCreate()
    
    self.statusrecordparentChatPanel = self:BindComponent('p_chat_panel', typeof(CS.StatusRecordParent))
    self.chatTable = self:TableViewPro('p_table_chat')
    self.btnOpen = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnBtnOpenClicked))
    self.inputfieldInput = self:InputField('p_input', nil, nil, Delegate.GetOrCreate(self, self.OnBtnPushClicked))
    self.btnPush = self:Button('p_btn_push', Delegate.GetOrCreate(self, self.OnBtnPushClicked))    

	self.chatBack = self:GameObject('base')	

    g_Game.EventManager:AddListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:AddListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))
end


function GveHudChatPanel:OnShow(param)
    -- DEFAULT_MSG_COUNT,TIMESTAMP_MIN_DELTA,MESSAGE_MAX_LENGTH = ModuleRefer.ChatModule:GetMainConfigs()
    self.inputfieldInput.characterLimit = MESSAGE_MAX_LENGTH
	self.inputfieldInput.placeholder.text = I18N.Get('alliance_battle_hud16')
	local cellPrefab = self.chatTable.cellPrefab[0]
	self.prefabText = cellPrefab:GetComponentInChildren(typeof(CS.DragonReborn.UI.ShrinkText))
	local cellTrans = cellPrefab:GetComponent(typeof(CS.UnityEngine.RectTransform))
	self.cellWidth = cellTrans.sizeDelta.x;
    self:RefreshData()
	self:RefreshUI(true)
end

function GveHudChatPanel:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.CHAT_MESSAGE_UPDATED, Delegate.GetOrCreate(self, self.OnMessageUpdated))
	g_Game.EventManager:RemoveListener(EventConst.CHAT_SESSION_LIST_UPDATED, Delegate.GetOrCreate(self, self.OnSessionListUpdated))	
end


function GveHudChatPanel:OnBtnOpenClicked(args)
    if self.panelExtended then
        self.panelExtended = false
        self.statusrecordparentChatPanel:Play(0)
    else
        self.panelExtended = true
        self.statusrecordparentChatPanel:Play(1)
    end

    self:RefreshData()
	self:RefreshUI()
	g_Game.EventManager:TriggerEvent(EventConst.GVE_CHAT_PANEL_STATE_CHANGED, self.panelExtended)
end
function GveHudChatPanel:OnBtnPushClicked(args)
    -- body
    if string.IsNullOrEmpty(self.sessionId) or string.IsNullOrEmpty(self.inputfieldInput.text) then        
        return
    end
    local session = self.chatModule:GetSession(self.sessionId)
	if (not session) then
		g_Logger.Error("聊天会话 %s 未找到!", self.sessionId)
		return
	end

	local msg = self.chatModule:CreateTextMessage(session, self.inputfieldInput.text)
	if (not msg) then
		g_Logger.Error("聊天文本创建失败!")
		return
	end

	ModuleRefer.ChatSDKModule:Send(msg)	
    self.inputfieldInput.text = ""
    ModuleRefer.ChatModule:SetUnsentMessage(self.sessionId, nil)
	
end

---@param data table
function GveHudChatPanel:OnMessageUpdated(data)
	if (not data) and data.sessionId ~= self.sessionId then return end
	self:RefreshData()
	self:RefreshUI()
end

function GveHudChatPanel:OnSessionListUpdated()
	self:RefreshData()
	self:RefreshUI()
end

function GveHudChatPanel:RefreshData()
    ---@type CS.FunPlusChat.Models.FPSession
    local session = nil
    for key, value in pairs(self.chatModule:GetSessionList()) do
        if value and value.SessionType == SessionType.Group and value.GroupType == GroupType.SELFDEF_110  then
            session = value
            break
        end
    end
    if session then
        self.sessionId = session.SessionId
    end
end

function GveHudChatPanel:RefreshUI()
    -- 消息列表
	-- local focusedData = self.chatTable:GetCurFocusData()
	self.chatTable:Clear()
	-- self._chatTableIdMap = {}
	local list = self.chatModule:GetSessionMessageList(self.sessionId)
	-- self._lastMsg = nil
	if (list and #list > 0 ) then
		for _, item in ipairs(list) do
			local data = self:GetChatItemData(item.message)
			local isSelfMsg = self.chatModule:IsSelfMessage(item.message)
			if (data ) then
				data.isSelf = isSelfMsg
				local height = UIHelper.CalcTextHeight(item.message.MsgStr,self.prefabText,self.cellWidth)
				self.chatTable:AppendDataEx(data,-1,height,0,0,0)
				-- self.chatTable:AppendData(data)
				-- self._chatTableIdMap[data.imId] = true
				-- if (focusedData and focusedData.imId == data.imId) then
				-- 	self.chatTable:SetVisible(data)
				-- end
			end
		end
		
		-- self._lastMsg = list[1].message
		self.btnOpen:SetVisible(true)
		self.chatBack:SetVisible(true)
	else
		self.btnOpen:SetVisible(false)
		self.chatBack:SetVisible(false)
	end
	
	Utils.TableViewProScrollToEnd(self.chatTable,true)
end

--- 获取消息条目数据
---@param self UIChatMediator
---@param message CS.FunPlusChat.Models.FPMessage
---@return table, number
function GveHudChatPanel:GetChatItemData(message)
	if (not message) then return end
	local data = {
		sessionId = message.SessionId,
		imId = message.ImId,
		time = message.MsgTime,
	}
	local text = self.chatModule:GetMessageText(message)
	data.text = text
	local extInfo = self.chatModule:DecodeJson(message.Attrs)
	if (message.MsgType == MessageType.Chat) then
		-- 普通消息
		data.isLoading = false
		data.isTimeStamp = false
		data.isHint = false
		data.uid = message.FromId
		data.extInfo = extInfo
        data.name = self.chatModule:GetNicknameFromExtInfo(extInfo, message.FromId)
	elseif (message.MsgType == MessageType.GameSystem) then
		-- 系统消息
		local suc = text ~= nil
		data.isLoading = false
		data.isTimeStamp = false
		data.isHint = true
        data.name = I18N.Temp().hint_system_message
		if (not suc) then
			g_Logger.TraceChannel("Chat", "系统消息解析错误: %s", extInfo)
			return
		end
		return data
	else
		-- 不支持的消息
		return
	end
	return data
end

return GveHudChatPanel
