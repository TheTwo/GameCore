local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@class TouchMenuCellSkillDatum : TouchMenuCellDatumBase
---@field new fun(label,labelColor, skillIds,clickCallback):TouchMenuCellSkillDatum
local TouchMenuCellSkillDatum = class("TouchMenuCellSkillDatum", TouchMenuCellDatumBase)

function TouchMenuCellSkillDatum:ctor(label,labelColor, skillIds,clickCallback)
    self.label = label
    self.labelColor = labelColor
    self.skillIds = skillIds
    self.clickCallback = clickCallback
end

---@return TouchMenuCellSkillDatum
function TouchMenuCellSkillDatum:SetLabel(label)
    self.label = label
    return self
end

---@return TouchMenuCellSkillDatum
function TouchMenuCellSkillDatum:SetLabelColor(labelColor)
    self.labelColor = labelColor
    return self
end

---@return TouchMenuCellSkillDatum
function TouchMenuCellSkillDatum:SetSkillIds(skillIds)
    self.skillIds = skillIds
    return self
end

---@return TouchMenuCellSkillDatum
function TouchMenuCellSkillDatum:SetClickCallback(clickCallback)
    self.clickCallback = clickCallback
    return self
end

function TouchMenuCellSkillDatum:GetPrefabIndex()
    return 14
end

return TouchMenuCellSkillDatum