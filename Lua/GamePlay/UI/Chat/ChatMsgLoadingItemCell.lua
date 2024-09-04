local BaseTableViewProCell = require ('BaseTableViewProCell')
local Utils = require("Utils")

---@class ChatMsgLoadingItemCell : BaseTableViewProCell
local ChatMsgLoadingItemCell = class('ChatMsgLoadingItemCell', BaseTableViewProCell)

local ROTATE_VECTOR = CS.UnityEngine.Vector3(0, 0, -360)
local ROTATE_TIME = 1
local ROTATE_MODE = CS.DG.Tweening.RotateMode.LocalAxisAdd
local ROTATE_EASING = CS.DG.Tweening.Ease.Linear

function ChatMsgLoadingItemCell:ctor()
    self.param = nil
end

function ChatMsgLoadingItemCell:OnCreate(param)
	self.iconLoading = self:GameObject("icon_loading")
	if (Utils.IsNotNull(self.iconLoading)) then
		self.iconLoading.transform:DOLocalRotate(ROTATE_VECTOR, ROTATE_TIME, ROTATE_MODE):SetLoops(-1):SetEase(ROTATE_EASING)
	end
end

function ChatMsgLoadingItemCell:OnShow(param)
end

function ChatMsgLoadingItemCell:OnOpened(param)
end

function ChatMsgLoadingItemCell:OnClose(param)
	if (Utils.IsNotNull(self.iconLoading)) then
		self.iconLoading.transform:DOKill()
	end
end

function ChatMsgLoadingItemCell:OnFeedData(param)
    if (not param) then return end
	self.param = param
end

return ChatMsgLoadingItemCell;
