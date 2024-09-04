local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class AllianceManageGroupLogDateDetailCellSizeProvider
---@field new fun():AllianceManageGroupLogDateDetailCellSizeProvider
---@field targetText CS.UnityEngine.UI.Text
local AllianceManageGroupLogDateDetailCellSizeProvider = class('AllianceManageGroupLogDateDetailCellSizeProvider')

---@param data AllianceManageGroupLogDateDetailCellData
function AllianceManageGroupLogDateDetailCellSizeProvider:GetTableViewProDynamicCellSize(data, width, height)
    local text = self.targetText
    local settings = text:GetGenerationSettings(CS.UnityEngine.Vector2(text:GetPixelAdjustedRect().size.x, 0))
    height = text.cachedTextGeneratorForLayout:GetPreferredHeight(data.preBuildText, settings) / text.pixelsPerUnit
    return width, height
end

return AllianceManageGroupLogDateDetailCellSizeProvider