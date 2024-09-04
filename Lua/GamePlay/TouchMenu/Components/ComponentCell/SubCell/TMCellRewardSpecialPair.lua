local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class TMCellRewardSpecialPair : BaseTableViewProCell
local TMCellRewardSpecialPair = class("TMCellRewardSpecialPair", BaseTableViewProCell)

function TMCellRewardSpecialPair:OnCreate()
    self.p_text_item = self:Text("p_text")
    self.p_text_item_content = self:Text("p_text_1")
    self.p_icon_item_original_1 = self:Image("p_icon")
end

---@param data TMCellRewardPairDatum
function TMCellRewardSpecialPair:OnFeedData(data)
    self.data = data
    self.p_text_item.text = data.leftLabel
    self.p_text_item_content.text = data.rightLabel
    if string.IsNullOrEmpty(data.icon) then
        self.p_icon_item_original_1:SetVisible(false)
    else
        self.p_icon_item_original_1:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(data.icon, self.p_icon_item_original_1)
    end
end

return TMCellRewardSpecialPair