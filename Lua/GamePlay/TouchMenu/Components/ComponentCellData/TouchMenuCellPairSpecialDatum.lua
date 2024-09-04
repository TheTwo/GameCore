
local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@class TouchMenuCellPairSpecialDatum:TouchMenuCellDatumBase
---@field new fun():TouchMenuCellPairSpecialDatum
---@field super TouchMenuCellDatumBase
local TouchMenuCellPairSpecialDatum = class('TouchMenuCellPairSpecialDatum', TouchMenuCellDatumBase)

function TouchMenuCellPairSpecialDatum:ctor(leftLabel, rightLabel, spritePath)
    self.leftLabel = leftLabel
    self.rightLabel = rightLabel
    self.spritePath = spritePath
end

---@param uiCell TouchMenuCellPairSpecial
function TouchMenuCellPairSpecialDatum:BindUICell(uiCell)
    self.uiCell = uiCell
    self:UpdateUICell()
end

function TouchMenuCellPairSpecialDatum:UnbindUICell()
    self.uiCell = nil
end

---@return TouchMenuCellPairSpecialDatum
function TouchMenuCellPairSpecialDatum:SetLeftLabel(label)
    self.leftLabel = label
    return self
end

---@return TouchMenuCellPairSpecialDatum
function TouchMenuCellPairSpecialDatum:SetRightLabel(label)
    self.rightLabel = label
    return self
end

---@return TouchMenuCellPairSpecialDatum
function TouchMenuCellPairSpecialDatum:SetSpritePath(sprite)
    self.spritePath = sprite
    return self
end

function TouchMenuCellPairSpecialDatum:GetLeftLabel()
    return self.leftLabel
end

function TouchMenuCellPairSpecialDatum:GetRightLabel()
    return self.rightLabel
end

function TouchMenuCellPairSpecialDatum:GetSpritePath()
    return self.spritePath
end

function TouchMenuCellPairSpecialDatum:UpdateUICell()
    self.uiCell:UpdateLeftLabel(self:GetLeftLabel())
    self.uiCell:UpdateRightLabel(self:GetRightLabel())
    self.uiCell:UpdateSprite(self:GetSpritePath())
end

function TouchMenuCellPairSpecialDatum:GetPrefabIndex()
    return 11
end

return TouchMenuCellPairSpecialDatum