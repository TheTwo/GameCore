local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@class TouchMenuCellLeagueDatum : TouchMenuCellDatumBase
---@field uiCell TouchMenuCellLeague
---@field new fun(label, labelColor, appear, pattern, clickCallback):TouchMenuCellLeagueDatum
local TouchMenuCellLeagueDatum = class("TouchMenuCellLeagueDatum", TouchMenuCellDatumBase)

function TouchMenuCellLeagueDatum:ctor(label, labelColor, appear, pattern, clickCallback)
    self.label = label
    self.labelColor = labelColor
    self.appear = appear or 0
    self.pattern = pattern or 0
    self.clickCallback = clickCallback    
end

---@return TouchMenuCellLeagueDatum
function TouchMenuCellLeagueDatum:SetLabel(label)
    self.label = label
    return self
end

---@return TouchMenuCellLeagueDatum
function TouchMenuCellLeagueDatum:SetLabelColor(labelColor)
    self.labelColor = labelColor
    return self
end

---@return TouchMenuCellLeagueDatum
function TouchMenuCellLeagueDatum:SetAllianceFlag(appear, pattern)
    self.appear = appear
    self.pattern = pattern
    return self
end

---@return TouchMenuCellLeagueDatum
function TouchMenuCellLeagueDatum:SetClickCallback(clickCallback)
    self.clickCallback = clickCallback
    return self
end

function TouchMenuCellLeagueDatum:SetButtonHidden(hidden)
    self.hideButton = hidden
    return self
end

function TouchMenuCellLeagueDatum:GetPrefabIndex()
    return 8
end

return TouchMenuCellLeagueDatum