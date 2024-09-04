local BaseTableViewProCell = require('BaseTableViewProCell')

local QuestChatLoadingCell = class('QuestChatLoadingCell',BaseTableViewProCell)

function QuestChatLoadingCell:OnCreate(param)
    self.animtriggerVxTriggerLoop2 = self:AnimTrigger('vx_trigger_loop2')
end

function QuestChatLoadingCell:OnFeedData(data)

end

return QuestChatLoadingCell
