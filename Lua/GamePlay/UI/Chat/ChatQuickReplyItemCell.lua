local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class ChatQuickReplyItemCell : BaseTableViewProCell
local ChatQuickReplyItemCell = class('ChatQuickReplyItemCell', BaseTableViewProCell)

function ChatQuickReplyItemCell:ctor()
    self.param = nil
end

function ChatQuickReplyItemCell:OnCreate(param)
	self.text = self:Text("p_text_quick_reply")
	self.button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

function ChatQuickReplyItemCell:OnShow(param)
end

function ChatQuickReplyItemCell:OnOpened(param)
end

function ChatQuickReplyItemCell:OnClose(param)
end

function ChatQuickReplyItemCell:OnFeedData(param)
    if (not param) then return end
	self.data = param
	self.text.text = self.data.text
end

function ChatQuickReplyItemCell:OnClick()
	if (self.data.onClick) then
		self.data.onClick(self.data.text)
	end
end

return ChatQuickReplyItemCell;
