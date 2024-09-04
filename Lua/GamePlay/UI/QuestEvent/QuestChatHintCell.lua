local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')

local QuestChatHintCell = class('QuestChatHintCell',BaseTableViewProCell)

function QuestChatHintCell:OnCreate(param)
    self.textHint = self:Text('p_text_hint', I18N.Get("new_chapter_chat_history"))
end

function QuestChatHintCell:OnFeedData(data)

end

return QuestChatHintCell
