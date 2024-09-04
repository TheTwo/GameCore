local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
---@class TouchMenuCellPairDynamicDatum:TouchMenuCellPairDatum
---@field new fun():TouchMenuCellPairDynamicDatum
local TouchMenuCellPairDynamicDatum = class("TouchMenuCellPairDynamicDatum", TouchMenuCellPairDatum)
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")

function TouchMenuCellPairDynamicDatum:ctor(getLeftLabel, getRightLabel, getSpritePath, hintCallback, hintImage, getBlackSpritePath, needTick, isFrameTick)
    self.getLeftLabel = getLeftLabel
    self.getRightLabel = getRightLabel
    self.getSpritePath = getSpritePath
    self.getBlackSpritePath = getBlackSpritePath
    
    self.dynamicLeftLabel = self:IsDynamic(getLeftLabel)
    self.dynamicRightLabel = self:IsDynamic(getRightLabel)
    self.dynamicSprite = self:IsDynamic(getSpritePath)
    self.dynamicBlackSprite = self:IsDynamic(getBlackSpritePath)
    
    self.needTick = needTick
    self.isFrameTick = isFrameTick

    local leftLabel = self.dynamicLeftLabel and getLeftLabel() or getLeftLabel
    local rightLabel = self.dynamicRightLabel and getRightLabel() or getRightLabel
    local spritePath = self.dynamicSprite and getSpritePath() or getSpritePath
    local blackSpritePath = self.dynamicBlackSprite and getBlackSpritePath() or getBlackSpritePath
    TouchMenuCellPairDatum.ctor(self, leftLabel, rightLabel, spritePath, hintCallback, hintImage, blackSpritePath)
end

---@return TouchMenuCellPairDynamicDatum
function TouchMenuCellPairDynamicDatum:SetTick(needTick)
    self.needTick = needTick
    return self
end

function TouchMenuCellPairDynamicDatum:IsDynamic(element)
    return type(element) == "function"
end

function TouchMenuCellPairDynamicDatum:GetLeftLabel()
    if self.dynamicLeftLabel then
        return self.getLeftLabel()
    end
    return TouchMenuCellPairDatum.GetLeftLabel(self)
end

function TouchMenuCellPairDynamicDatum:GetRightLabel()
    if self.dynamicRightLabel then
        return self.getRightLabel()
    end
    return TouchMenuCellPairDatum.GetRightLabel(self)
end

function TouchMenuCellPairDynamicDatum:GetSpritePath()
    if self.dynamicSprite then
        return self.getSpritePath()
    end
    return TouchMenuCellPairDatum.GetSpritePath(self)
end

---@param uiCell TouchMenuCellPair
function TouchMenuCellPairDynamicDatum:BindUICell(uiCell)
    TouchMenuCellPairDatum.BindUICell(self, uiCell)
    if not self.needTick then return end

    if self.isFrameTick then
        self.timer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.UpdateUICellTick), 1, -1)
    else
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.UpdateUICellTick), 1, -1)
    end
end

function TouchMenuCellPairDynamicDatum:UnbindUICell()
    TouchMenuCellPairDatum.UnbindUICell(self)
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function TouchMenuCellPairDynamicDatum:UpdateUICellTick()
    if self.dynamicLeftLabel then
        self.uiCell:UpdateLeftLabel(self:GetLeftLabel())
    end
    if self.dynamicRightLabel then
        self.uiCell:UpdateRightLabel(self:GetRightLabel())
    end
    if self.dynamicSprite then
        self.uiCell:UpdateSprite(self:GetSpritePath())
    end
    if self.dynamicBlackSprite then
        self.uiCell:UpdateBlackSprite(self:GetBlackSpritePath())
    end
end

return TouchMenuCellPairDynamicDatum