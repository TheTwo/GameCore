local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local NM = ModuleRefer.NotificationModule
local Utils = require("Utils")

---@class ChatChannelItemCell : BaseTableViewProCell
local ChatChannelItemCell = class('ChatChannelItemCell', BaseTableViewProCell)

local I18N_ALLIANCE_ONLINE = "chat_alliance_online"
local ANIM_SHOW_SELECT = "anim_vx_ui_chat_open"
local ANIM_CLOSE_SELECT = "anim_vx_ui_chat_close"

function ChatChannelItemCell:ctor()
    self.param = nil
end

function ChatChannelItemCell:OnCreate(param)
	self.button = self:Button("", Delegate.GetOrCreate(self, self.OnSelfClick))
	self.groupNormal = self:GameObject("p_group_normal")
	self.groupSelected = self:GameObject("p_group_select")
    self.textName = self:Text("p_text_name")
	self.textNameSelected = self:Text("p_text_name_select")
	self.textOnline = self:Text("p_text_online")
	self.textOnlineSelected = self:Text("p_text_online_select")
	self.textOffline = self:Text("p_text_offline")
	self.textOfflineSelected = self:Text("p_text_offline_select")
	---@type PlayerInfoComponent
	self.playerIcon = self:LuaObject("p_head_player")
	---@type CommonAllianceLogoComponent
	self.allianceIcon = self:LuaObject("p_league_logo")
	self.otherIcon = self:Image("p_icon_logo")
	---@type NotificationNode
	self.redDot = self:LuaObject("child_reddot_default")
	self.iconPinned = self:GameObject("p_icon_top")
	self.iconPinnedSelected = self:GameObject("p_icon_top_select")
	self.iconMute = self:GameObject("p_icon_disturb")
	self.iconMuteSelected = self:GameObject("p_icon_disturb_select")
	self.onRefreshAllianceOnlineCountDelegate = nil
	self.onRefreshPlayerOnlineStatusDelegate = nil
end

function ChatChannelItemCell:OnShow(param)
end

function ChatChannelItemCell:OnOpened(param)
end

function ChatChannelItemCell:OnClose(param)
	if (self.onRefreshAllianceOnlineCountDelegate) then
		g_Game:RemoveSecondTicker(self.onRefreshAllianceOnlineCountDelegate)
		self.onRefreshAllianceOnlineCountDelegate = nil
	end
	if (self.onRefreshPlayerOnlineStatusDelegate) then
		g_Game:RemoveSecondTicker(self.onRefreshPlayerOnlineStatusDelegate)
		self.onRefreshPlayerOnlineStatusDelegate = nil
	end
end

function ChatChannelItemCell:OnFeedData(param)
    if (not param) then return end
	self.param = param
	self.toast = param.toast
	---@type CS.FunPlusChat.Models.FPSession
	self.session = param.session
	self.groupNormal:SetActive(not param.selected)
	self.groupSelected:SetActive(param.selected)
	self.showOpenSelect = param.showOpenSelect
	self.showCloseSelect = param.showCloseSelect
	if (self.toast) then
		self.textName.text = I18N.Get("toast_chat")
	else
		self.textName.text = ModuleRefer.ChatModule:GetSessionName(param.session)
	end
	self.textNameSelected.text = self.textName.text
	self.iconPinned:SetActive(param.pinned)
	self.iconPinnedSelected:SetActive(param.pinned)
	self.iconMute:SetActive(param.muted)
	self.iconMuteSelected:SetActive(param.muted)
	self.textOnline.gameObject:SetActive(false)
	self.textOnlineSelected.gameObject:SetActive(false)
	self.textOffline.gameObject:SetActive(false)
	self.textOfflineSelected.gameObject:SetActive(false)
	self.playerIcon.CSComponent.gameObject:SetActive(false)
	self.otherIcon.gameObject:SetActive(false)
	self.allianceIcon.CSComponent.gameObject:SetActive(false)
	self.textName.gameObject:SetActive(true)
	self.textNameSelected.gameObject:SetActive(true)

	-- 系统通知
	if (ModuleRefer.ChatModule:IsSystemToastSession(self.session)) then
		self.otherIcon.gameObject:SetActive(true)
		g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetSystemToastSpriteName(), self.otherIcon)

	-- 世界
	elseif (ModuleRefer.ChatModule:IsWorldSession(self.session)) then
		self.otherIcon.gameObject:SetActive(true)
		g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetWorldSpriteName(), self.otherIcon)

	-- 联盟
	elseif (ModuleRefer.ChatModule:IsAllianceSession(self.session)) then
		self.textOnline.gameObject:SetActive(true)
		self.textOnlineSelected.gameObject:SetActive(true)
		self.textOffline.gameObject:SetActive(false)
		self.textOfflineSelected.gameObject:SetActive(false)
		self.allianceIcon.CSComponent.gameObject:SetActive(true)
        local allianceBasicInfo = ModuleRefer.AllianceModule:GetMyAllianceBasicInfo()

		if not allianceBasicInfo then
            g_Logger.Error("allianceBasicInfo is nil")
        end
		
		self.allianceIcon:FeedData(allianceBasicInfo and allianceBasicInfo.Flag or nil)

		self.onRefreshAllianceOnlineCountDelegate = Delegate.GetOrCreate(self, self.RefreshAllianceOnlineCount)
		g_Game:AddSecondTicker(self.onRefreshAllianceOnlineCountDelegate)
		self:RefreshAllianceOnlineCount()

	-- 私聊
	elseif (ModuleRefer.ChatModule:IsPrivateSession(self.session)) then
		self.playerIcon.CSComponent.gameObject:SetActive(true)
		---@type wds.PortraitInfo
		local portraitInfo = wds.PortraitInfo.New()
		portraitInfo.PlayerPortrait = 0
		portraitInfo.PortraitFrameId = 0
		portraitInfo.CustomAvatar = nil
		local avatars = self.session.Avatars
		local msg = self.session.Msg
		local isFeedData = false
		CS.FunPlusChat.FPChatSdk.GetUserInfo(self.session.ToId, function (code, info)
			if code == 0 then
				local extInfo = ModuleRefer.ChatModule:DecodeJson(info.ExtInfo)
				if extInfo then
					if extInfo.p then
						portraitInfo.PlayerPortrait = extInfo.p
					end
					if extInfo.fp then
						portraitInfo.PortraitFrameId = extInfo.fp
					end
					if extInfo.ca then
						portraitInfo.CustomAvatar = extInfo.ca
					else
						portraitInfo.CustomAvatar = nil
					end
					isFeedData = true
					self.playerIcon:FeedData(portraitInfo)
				end
				-- if not string.IsNullOrEmpty(extInfo) then
				-- 	local pattern = "(\"%a+\"):(.+)"
				-- 	local stringList = string.split(extInfo, ",")
				-- 	for i = 1, #stringList do
				-- 		local key , value = string.match(stringList[i], pattern)
				-- 		if not string.IsNullOrEmpty(key) and not string.IsNullOrEmpty(value) then
				-- 			if string.find(key, "\"p\"") then
				-- 				portraitInfo.PlayerPortrait = tonumber(value)
				-- 			elseif string.find(key, "\"fp\"") then
				-- 				portraitInfo.PortraitFrameId = tonumber(value)
				-- 			elseif string.find(key, "\"ca\"") then
				-- 				portraitInfo.CustomAvatar = string.sub(value, 2, string.len(value) - 2)
				-- 			end
				-- 		end
				-- 	end
				-- 	isFeedData = true
				-- 	self.playerIcon:FeedData(portraitInfo)
				-- end
			end
		end)
		if not isFeedData then
			if (msg) then
				local attrs = msg.Attrs
				if not string.IsNullOrEmpty(attrs) then
					local pattern = "(\"%a+\"):(.+)"
					local stringList = string.split(attrs, ",")
					for i = 1, #stringList do
						local key , value = string.match(stringList[i], pattern)
						if not string.IsNullOrEmpty(key) and not string.IsNullOrEmpty(value) then
							if string.find(key, "\"p\"") then
								portraitInfo.PlayerPortrait = tonumber(value)
							elseif string.find(key, "\"fp\"") then
								portraitInfo.PortraitFrameId = tonumber(value)
							elseif string.find(key, "\"ca\"") then
								if string.EndWith(value, "}") then
									portraitInfo.CustomAvatar = string.sub(value, 2, string.len(value) - 2)
								else
									portraitInfo.CustomAvatar = string.sub(value, 2, string.len(value) - 1)
								end
							end
						end
					end
				end
			elseif avatars then
				local avatar = avatars[0]
				if avatar then
					if not string.IsNullOrEmpty(avatar) then
						local pattern = "(%a+):(.+)"
						local stringList = string.split(avatar, ",")
						for i = 1, #stringList do
							local key , value = string.match(stringList[i], pattern)
							if not string.IsNullOrEmpty(key) and not string.IsNullOrEmpty(value) then
								if string.find(key, "p") == 1 then
									portraitInfo.PlayerPortrait = tonumber(value)
								elseif string.find(key, "fp") == 1 then
									portraitInfo.PortraitFrameId = tonumber(value)
								elseif string.find(key, "ca") == 1 then
									portraitInfo.CustomAvatar = string.sub(value, 1, string.len(value) - 1)
								end
							end
						end
					end
				end
			end
			self.playerIcon:FeedData(portraitInfo)
		end
		-- local avatars = self.session.Avatars
		-- if (avatars) then
		-- 	local first = avatars[0]
		-- 	if (not Utils.IsNullOrEmpty(first)) then
		-- 		local iconId = tonumber(first)
		-- 		if (iconId) then
		-- 			self.playerIcon:FeedData({
		-- 				iconId = iconId
		-- 			})
		-- 		end
		-- 	end
		-- end
		
		self.onRefreshPlayerOnlineStatusDelegate = Delegate.GetOrCreate(self, self.RefreshPlayerOnlineStatus)
		g_Game:AddSecondTicker(self.onRefreshPlayerOnlineStatusDelegate)
		self:RefreshPlayerOnlineStatus()
	end

	-- 红点
	local node = ModuleRefer.ChatModule:GetSessionRedDot(self.session.SessionId)
	if (node) then
		NM:AttachToGameObject(node, self.redDot.go)
	end

	-- 动效
	if (self.showOpenSelect) then
		--g_Logger.Trace("*** showOpenSelect %s", self.session.SessionId)
		self.groupSelected:SetActive(true)
		self.iconMuteSelected:SetActive(true)
		self.textName.gameObject:SetActive(false)
		self.textNameSelected.gameObject:SetActive(true)
		self.iconPinnedSelected:SetActive(true)
		self.textOnlineSelected.gameObject:SetActive(true)
		self.textOfflineSelected.gameObject:SetActive(true)
		---@type CS.UnityEngine.Animation
		local anim = self.groupSelected:GetComponent(typeof(CS.UnityEngine.Animation))
		if (Utils.IsNotNull(anim)) then
			anim:Play(ANIM_SHOW_SELECT)
		end
	elseif (self.showCloseSelect) then
		--g_Logger.Trace("*** showCloseSelect %s", self.session.SessionId)
		self.groupSelected:SetActive(false)
		self.iconMuteSelected:SetActive(false)
		self.textName.gameObject:SetActive(true)
		self.textNameSelected.gameObject:SetActive(false)
		self.iconPinnedSelected:SetActive(false)
		self.textOnlineSelected.gameObject:SetActive(false)
		self.textOfflineSelected.gameObject:SetActive(false)
		-- ---@type CS.UnityEngine.Animation
		-- local anim = self.groupSelected:GetComponent(typeof(CS.UnityEngine.Animation))
		-- if (Utils.IsNotNull(anim)) then
		-- 	anim:Play(ANIM_CLOSE_SELECT)
		-- end
	end
end

function ChatChannelItemCell:OnSelfClick()
	if (self.param.onClick) then
		self.param.onClick(self.param.session.SessionId)
	end
end

--- 刷新联盟在线人数
---@param self ChatChannelItemCell
function ChatChannelItemCell:RefreshAllianceOnlineCount()
	local online, _ = ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount()
	local text = I18N.GetWithParams(I18N_ALLIANCE_ONLINE, online)
	self.textOnline.text = text
	self.textOnlineSelected.text = text
end

--- 刷新玩家在线状态
--- @param self ChatChannelItemCell
function ChatChannelItemCell:RefreshPlayerOnlineStatus()
	
end

return ChatChannelItemCell;
