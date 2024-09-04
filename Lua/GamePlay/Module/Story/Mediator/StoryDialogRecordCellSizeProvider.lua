---@class StoryDialogRecordChatItemCellSizeProvider
---@field new fun():StoryDialogRecordChatItemCellSizeProvider
---@field targetText CS.UnityEngine.UI.Text
---@field layout CS.UnityEngine.UI.VerticalLayoutGroup
local StoryDialogRecordCellSizeProvider = sealedClass('StoryDialogRecordCellSizeProvider')

---@param data {textContent:string}
function StoryDialogRecordCellSizeProvider:GetTableViewProDynamicCellSize(data, width, height)
    local text = self.targetText
    local settings = text:GetGenerationSettings(CS.UnityEngine.Vector2(text:GetPixelAdjustedRect().size.x, 0))
    height = text.cachedTextGeneratorForLayout:GetPreferredHeight(data.textContent, settings) / text.pixelsPerUnit
    height = height + self.layout.padding.top + self.layout.padding.bottom
    return width, height
end

return StoryDialogRecordCellSizeProvider