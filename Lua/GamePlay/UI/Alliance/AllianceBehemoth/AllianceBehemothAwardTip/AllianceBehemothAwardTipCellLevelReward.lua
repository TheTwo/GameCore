
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothAwardTipCellLevelRewardData
---@field lv number
---@field lvEnd number
---@field cells ItemIconData[]

---@class AllianceBehemothAwardTipCellLevelReward:BaseTableViewProCell
---@field new fun():AllianceBehemothAwardTipCellLevelReward
---@field super BaseTableViewProCell
local AllianceBehemothAwardTipCellLevelReward = class('AllianceBehemothAwardTipCellLevelReward', BaseTableViewProCell)

AllianceBehemothAwardTipCellLevelReward.RankTopSprite = {
    "sp_activity_ranking_icon_top_1",
    "sp_activity_ranking_icon_top_2",
    "sp_activity_ranking_icon_top_3"
}

function AllianceBehemothAwardTipCellLevelReward:OnCreate(param)
    self._p_base_lv = self:Image("p_base_lv")
    self._p_base_lv_n = self:GameObject("p_base_lv_n")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_table_item = self:TableViewPro("p_table_item")
end

---@param data AllianceBehemothAwardTipCellLevelRewardData
function AllianceBehemothAwardTipCellLevelReward:OnFeedData(data)
    if data.lv and data.lvEnd and data.lvEnd > data.lv then
        self._p_base_lv:SetVisible(false)
        self._p_base_lv_n:SetVisible(true)
        self._p_text_lv.text = ("%d-%d"):format(data.lv, data.lvEnd)
    else
        if data.lv > 3 then
            self._p_base_lv:SetVisible(false)
            self._p_base_lv_n:SetVisible(true)
            self._p_text_lv.text = tostring(data.lv)
        else
            self._p_base_lv:SetVisible(true)
            self._p_base_lv_n:SetVisible(false)
            g_Game.SpriteManager:LoadSprite(AllianceBehemothAwardTipCellLevelReward.RankTopSprite[data.lv], self._p_base_lv)
        end
    end
    self._p_table_item:Clear()
    for _, v in ipairs(data.cells) do
        self._p_table_item:AppendData(v)
    end
end

return AllianceBehemothAwardTipCellLevelReward