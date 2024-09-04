local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local Utils = require("Utils")
local EventConst = require("EventConst")
local AudioConsts = require("AudioConsts")

---@class UIChatHeadPopupMediator : BaseUIMediator
local UIChatHeadPopupMediator = class('UIChatHeadPopupMediator', BaseUIMediator)

-- 锚点相对目标中心移动偏移
local SCREEN_OFFSET_ANCHOR_ABOVE = CS.UnityEngine.Vector3(265, 0, 0)
local SCREEN_OFFSET_ANCHOR_BELOW = CS.UnityEngine.Vector3(265, 0, 0)
local SCREEN_OFFSET_ABOVE_EXTRA_ITEM = CS.UnityEngine.Vector3(0, 65, 0)
local SCREEN_OFFSET_BELOW_EXTRA_ITEM = CS.UnityEngine.Vector3(0, -65, 0)

function UIChatHeadPopupMediator:ctor()

end

function UIChatHeadPopupMediator:OnCreate()
    self:InitObjects()
end

function UIChatHeadPopupMediator:InitObjects()
	self.anchor = self:GameObject("p_tips_set")
	self.content = self:GameObject("content")
	self.itemChat = self:Button("p_item_chat", Delegate.GetOrCreate(self, self.OnItemChatClick))
	self.itemChatText = self:Text("p_text_chat", "chat_private")
	self.arrowTop = self:GameObject("p_icon_arrow_top")
	self.arrowBottom = self:GameObject("p_icon_arrow_bottom")
end

function UIChatHeadPopupMediator:OnShow(param)
	if (not param) then return end
	self.data = param.data
	---@type CS.UnityEngine.GameObject
	self.anchorGo = param.anchorGo
	if (Utils.IsNull(self.anchorGo)) then return end

	-- TODO: 未来条目数不确定时使用
	local extraItemCount = 0

	-- 定位到目标
	local camera = g_Game.UIManager:GetUICamera()
	---@type CS.UnityEngine.RectTransform
	local rt = self.anchorGo.transform
	local center = rt:GetScreenCenter(camera)

	-- 判断弹出位置
	local anchor
	local offset
	if (center.y <= CS.UnityEngine.Screen.height / 2) then
		-- 在上方弹出
		self.arrowTop:SetActive(false)
		self.arrowBottom:SetActive(true)
		anchor = SCREEN_OFFSET_ANCHOR_ABOVE
		offset = SCREEN_OFFSET_ABOVE_EXTRA_ITEM
	else
		-- 在下方弹出
		self.arrowTop:SetActive(true)
		self.arrowBottom:SetActive(false)
		anchor = SCREEN_OFFSET_ANCHOR_BELOW
		offset = SCREEN_OFFSET_BELOW_EXTRA_ITEM
	end
	
	local finalPos = camera:ScreenToWorldPoint(center)
	self.anchor.transform.position = finalPos
	self.anchor.transform.localPosition = self.anchor.transform.localPosition + anchor + offset * extraItemCount
end

function UIChatHeadPopupMediator:OnHide(param)
end

function UIChatHeadPopupMediator:OnOpened(param)
end

function UIChatHeadPopupMediator:OnClose(param)

end

function UIChatHeadPopupMediator:OnItemChatClick()
	-- 跳转到现有会话
	local session = ModuleRefer.ChatModule:GetPrivateSessionByUid(self.data.uid)
	if (session) then
		g_Game.EventManager:TriggerEvent(EventConst.CHAT_GOTO_SESSION, session.SessionId)

	-- 创建新会话
	else
		local nickname = ModuleRefer.ChatModule:GetNicknameFromExtInfo(self.data.extInfo, self.data.uid)
		local portrait = ModuleRefer.ChatModule:GetPortraitFromExtInfo(self.data.extInfo)
		local userInfo = CS.FunPlusChat.Models.UserInfo()
		userInfo.Avatar = string.format("{p:%s, fp:%s, ca:%s}", self.data.extInfo.p, self.data.extInfo.fp, self.data.extInfo.ca)
		-- userInfo.Avatar = tostring(portrait)
		userInfo.Nickname = nickname
		userInfo.Uid = self.data.uid
		CS.ChatSdkWrapper.CreateP2P(userInfo, function(newSession)
			g_Logger.TraceChannel("Chat", "********* New session created: %s", newSession.SessionId)
			ModuleRefer.ChatModule:SetNextGotoSessionId(newSession.SessionId)
			g_Game.EventManager:TriggerEvent(EventConst.CHAT_SESSION_LIST_UPDATED)
		end)
	end

	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)

	-- 关闭
	self:CloseSelf()
end

return UIChatHeadPopupMediator
