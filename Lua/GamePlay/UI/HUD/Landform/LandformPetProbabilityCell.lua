local BaseTableViewProCell = require ('BaseTableViewProCell')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')

---@class LandformPetProbabilityCellData
---@field colorKey string
---@field imagePath string
---@field content string
---@field probability string

---@class LandformPetProbabilityCell:BaseTableViewProCell
---@field new fun():LandformPetProbabilityCell
---@field super BaseTableViewProCell
local LandformPetProbabilityCell = class('LandformPetProbabilityCell', BaseTableViewProCell)

function LandformPetProbabilityCell:OnCreate()
    self.imgQuality = self:Image('p_qualiity')
    self.txtContent = self:Text('p_text_content')
    self.txtProbability = self:Text('p_text_probability')
end

---@param data LandformPetProbabilityCellData
function LandformPetProbabilityCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.imagePath, self.imgQuality)
    self.txtContent.text = data.content
    self.txtProbability.text = data.probability

    if data.colorKey and ColorConsts[data.colorKey] then
        local color = UIHelper.TryParseHtmlString(ColorConsts[data.colorKey])
        self.txtProbability.color = color
    end
end

return LandformPetProbabilityCell