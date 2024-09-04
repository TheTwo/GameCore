local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")

---@class TouchMenuCellPairDatum:TouchMenuCellDatumBase
---@field new fun(leftLabel, rightLabel, spritePath, hintCallback,hintImage,blackSprite, gotoCallback):TouchMenuCellPairDatum
local TouchMenuCellPairDatum = class("TouchMenuCellPairDatum", TouchMenuCellDatumBase)

function TouchMenuCellPairDatum:ctor(leftLabel, rightLabel, spritePath, hintCallback, hintImage, blackSprite, gotoCallback)
    self.leftLabel = leftLabel
    self.rightLabel = rightLabel
    self.spritePath = spritePath
    self.hintCallback = hintCallback
    self.hintImage = hintImage or "sp_common_icon_details_02"
    self.blackSprite = blackSprite
    self.gotoCallback = gotoCallback
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetLeftLabel(label)
    self.leftLabel = label
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetRightLabel(label)
    self.rightLabel = label
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetSpritePath(sprite)
    self.spritePath = sprite
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetHintCallback(callback)
    self.hintCallback = callback
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetGotoCallback(callback)
    self.gotoCallback = callback
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetHintImage(image)
    self.hintImage = image
    return self
end

---@return TouchMenuCellPairDatum
function TouchMenuCellPairDatum:SetBlackSprite(blackSprite)
    self.blackSprite = blackSprite
    return self
end

function TouchMenuCellPairDatum:GetLeftLabel()
    return self.leftLabel
end

function TouchMenuCellPairDatum:GetRightLabel()
    return self.rightLabel
end

function TouchMenuCellPairDatum:GetSpritePath()
    return self.spritePath
end

function TouchMenuCellPairDatum:GetBlackSpritePath()
    return self.blackSprite
end

function TouchMenuCellPairDatum:ShowHintButton()
    return type(self.hintCallback) == "function"
end

function TouchMenuCellPairDatum:ShowGotoButton()
    return type(self.gotoCallback) == "function"
end

function TouchMenuCellPairDatum:OnClickHintButton()
    self.hintCallback()
end

function TouchMenuCellPairDatum:OnClickGotoButton()
    self.gotoCallback()
end

---@param uiCell TouchMenuCellPair
function TouchMenuCellPairDatum:BindUICell(uiCell)
    self.uiCell = uiCell
    self:UpdateUICell()
end

function TouchMenuCellPairDatum:UnbindUICell()
    self.uiCell = nil
end

function TouchMenuCellPairDatum:UpdateUICell()
    self.uiCell:UpdateLeftLabel(self:GetLeftLabel())
    self.uiCell:UpdateRightLabel(self:GetRightLabel())
    self.uiCell:UpdateSprite(self:GetSpritePath())
    self.uiCell:UpdateBlackSprite(self:GetBlackSpritePath())
    self.uiCell:DisplayHintButton(self:ShowHintButton())
    self.uiCell:DisplayGotoButton(self:ShowGotoButton())
end

function TouchMenuCellPairDatum:GetPrefabIndex()
    return 0
end

return TouchMenuCellPairDatum