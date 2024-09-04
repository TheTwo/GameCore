local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class ChatEmojiItemCell : BaseTableViewProCell
local ChatEmojiItemCell = class('ChatEmojiItemCell', BaseTableViewProCell)

function ChatEmojiItemCell:ctor()
    self.param = nil
end

function ChatEmojiItemCell:OnCreate(param)
	self.icon = self:Image("p_icon_emoji")
	self.button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

function ChatEmojiItemCell:OnShow(param)
end

function ChatEmojiItemCell:OnOpened(param)
end

function ChatEmojiItemCell:OnClose(param)
end

function ChatEmojiItemCell:OnFeedData(param)
    if (not param) then return end
	self.data = param
	g_Game.SpriteManager:LoadSprite(self.data.sprite, self.icon)
end

function ChatEmojiItemCell:OnClick()
	if (self.data.onClick) then
		self.data.onClick(self.data.text)
	end
end

return ChatEmojiItemCell;
