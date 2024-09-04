local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class TMCellRewardPair : BaseTableViewProCell
local TMCellRewardPair = class("TMCellRewardPair", BaseTableViewProCell)

function TMCellRewardPair:OnCreate()
    self.p_text_item = self:Text("p_text_item")
    self.p_text_item_content = self:Text("p_text_item_content")
    self.p_icon_item_original_1 = self:Image("p_icon_item_original_1")
end

---@param data TMCellRewardPairDatum
function TMCellRewardPair:OnFeedData(data)
    self.data = data
    self.p_text_item.text = data.leftLabel
    self.p_text_item_content.text = data.rightLabel
    g_Game.SpriteManager:LoadSprite(data.icon, self.p_icon_item_original_1)
end

return TMCellRewardPair