
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothCageOccupationGainDetailItemCell:BaseTableViewProCell
---@field new fun():AllianceBehemothCageOccupationGainDetailItemCell
---@field super BaseTableViewProCell
local AllianceBehemothCageOccupationGainDetailItemCell = class('AllianceBehemothCageOccupationGainDetailItemCell', BaseTableViewProCell)

function AllianceBehemothCageOccupationGainDetailItemCell:OnCreate(param)
    self._p_text_a = self:Text("p_text")
    self._p_text_a_1 = self:Text("p_text_1")
    self._p_icon_a = self:Image("p_icon")
end

---@param data {strLeft:string, strRight:string, icon:string}
function AllianceBehemothCageOccupationGainDetailItemCell:OnFeedData(data)
    self._p_text_a.text = data.strLeft
    self._p_text_a_1.text = data.strRight
    if string.IsNullOrEmpty(data.icon) then
        self._p_icon_a:SetVisible(false)
    else
        self._p_icon_a:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_a)
    end
end

return AllianceBehemothCageOccupationGainDetailItemCell