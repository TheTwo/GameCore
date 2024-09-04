local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local Utils = require("Utils")
local AudioConsts = require("AudioConsts")

---@class UIChatMessagePopupMediator : BaseUIMediator
local UIChatMessagePopupMediator = class('UIChatMessagePopupMediator', BaseUIMediator)

-- 锚点相对目标中心移动偏移
local SCREEN_OFFSET_ANCHOR_ABOVE = CS.UnityEngine.Vector3(0, 140, 0)
local SCREEN_OFFSET_ANCHOR_BELOW = CS.UnityEngine.Vector3(0, -140, 0)
local SCREEN_OFFSET_ABOVE_EXTRA_ITEM = CS.UnityEngine.Vector3(0, 65, 0)
local SCREEN_OFFSET_BELOW_EXTRA_ITEM = CS.UnityEngine.Vector3(0, -65, 0)

function UIChatMessagePopupMediator:ctor()

end

function UIChatMessagePopupMediator:OnCreate()
    self:InitObjects()
end

function UIChatMessagePopupMediator:InitObjects()
	self.anchor = self:GameObject("p_tips_set")
	self.content = self:GameObject("content")
	self.itemChat = self:Button("p_item_copy", Delegate.GetOrCreate(self, self.OnItemCopyClick))
	self.itemChatText = self:Text("p_text_copy", "chat_copy")
	self.arrowTop = self:GameObject("p_icon_arrow_top")
	self.arrowBottom = self:GameObject("p_icon_arrow_bottom")
end

function UIChatMessagePopupMediator:OnShow(param)
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

function UIChatMessagePopupMediator:OnHide(param)
end

function UIChatMessagePopupMediator:OnOpened(param)
end

function UIChatMessagePopupMediator:OnClose(param)

end

function UIChatMessagePopupMediator:OnItemCopyClick()
	Utils.CopyToClipboard(self.data.text)
	
	g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
	
	-- 关闭
	self:CloseSelf()
end

return UIChatMessagePopupMediator
