
---@class AllianceBuildingDetailTextCellProvider
---@field new fun():AllianceBuildingDetailTextCellProvider
---@field targetText CS.UnityEngine.UI.Text
local AllianceBuildingDetailTextCellProvider = class('AllianceBuildingDetailTextCellProvider')

---@param data AllianceManageGroupLogDateDetailCellData|string
function AllianceBuildingDetailTextCellProvider:GetTableViewProDynamicCellSize(data, width, height)
    local text = self.targetText
    local settings = text:GetGenerationSettings(CS.UnityEngine.Vector2(text:GetPixelAdjustedRect().size.x, 0))
    if type(data) == 'string' then
        height = text.cachedTextGeneratorForLayout:GetPreferredHeight(data, settings) / text.pixelsPerUnit
    else
        height = text.cachedTextGeneratorForLayout:GetPreferredHeight(data.preBuildText, settings) / text.pixelsPerUnit
    end
    local szie = text.rectTransform.sizeDelta
    szie.y = height
    text.rectTransform.sizeDelta = szie
    return width, height
end

return AllianceBuildingDetailTextCellProvider