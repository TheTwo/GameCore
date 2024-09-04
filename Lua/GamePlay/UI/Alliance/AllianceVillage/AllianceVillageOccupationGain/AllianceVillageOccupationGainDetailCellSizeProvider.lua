
---@class AllianceVillageOccupationGainDetailCellSizeProvider
---@field new fun():AllianceVillageOccupationGainDetailCellSizeProvider
---@field targetText CS.UnityEngine.UI.Text
---@field layout CS.UnityEngine.UI.VerticalLayoutGroup
local AllianceVillageOccupationGainDetailCellSizeProvider = sealedClass('AllianceVillageOccupationGainDetailCellSizeProvider')

---@param data string
function AllianceVillageOccupationGainDetailCellSizeProvider:GetTableViewProDynamicCellSize(data, width, height)
    local text = self.targetText
    local settings = text:GetGenerationSettings(CS.UnityEngine.Vector2(text:GetPixelAdjustedRect().size.x, 0))
    height = text.cachedTextGeneratorForLayout:GetPreferredHeight(data, settings) / text.pixelsPerUnit
    height = height + self.layout.padding.top + self.layout.padding.bottom
    return width, height
end

return AllianceVillageOccupationGainDetailCellSizeProvider