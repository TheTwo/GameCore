local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothInfoComponentAttrCellData
---@field icon string
---@field name string
---@field numStr string
---@field blackBg boolean
---@field numStrNext string

---@class AllianceBehemothInfoComponentAttrCell:BaseTableViewProCell
---@field new fun():AllianceBehemothInfoComponentAttrCell
---@field super BaseTableViewProCell
local AllianceBehemothInfoComponentAttrCell = class('AllianceBehemothInfoComponentAttrCell', BaseTableViewProCell)

function AllianceBehemothInfoComponentAttrCell:OnCreate(param)
    self.imgIcon = self:Image('p_icon')
    self.textLv = self:Text('p_text_lv')
    self.textNum = self:Text('p_text_num')
    self.textNum_1 = self:Text('p_text_num_1')
    self.goArrow = self:GameObject('Image_1')
    self.p_base_1 = self:GameObject("p_base_1")
    self.p_base_2 = self:GameObject("p_base_2")
end

---OnFeedData
---@param data AllianceBehemothInfoComponentAttrCellData
function AllianceBehemothInfoComponentAttrCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIcon)
    self.textLv.text = data.name
    self.textNum.text = data.numStr
    if string.IsNullOrEmpty(data.numStrNext) then
        self.textNum_1:SetVisible(false)
        self.goArrow:SetVisible(false)
    else
        self.textNum_1:SetVisible(true)
        self.goArrow:SetVisible(true)
        self.textNum_1.text = data.numStrNext
    end
    self.p_base_1:SetVisible(not data.blackBg)
    self.p_base_2:SetVisible(data.blackBg)
end

return AllianceBehemothInfoComponentAttrCell