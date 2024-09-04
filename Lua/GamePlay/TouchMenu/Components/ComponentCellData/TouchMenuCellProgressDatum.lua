local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellProgressDatum:TouchMenuCellDatumBase
---@field new fun(imageHeader, titleText, progress, commonTimerData, subImage, showProgressNumber,customProgressNumber):TouchMenuCellProgressDatum
local TouchMenuCellProgressDatum = class("TouchMenuCellProgressDatum", TouchMenuCellDatumBase)
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")

function TouchMenuCellProgressDatum:ctor(imageHeader, titleText, progress, commonTimerData, subImage, showProgressNumber,customProgressNumber)
    self.imageHeader = imageHeader
    self.titleText = titleText
    self.progress = progress
    self.commonTimerData = commonTimerData
    self.subImage = subImage
    self.showProgressNumber = showProgressNumber
    self.customProgressNumber = customProgressNumber
    self.dynamicTitle = self:IsDynamic(titleText)
    self.dynamicProgress = self:IsDynamic(progress)
    self.gotoCallback = nil
    self.creepBuffIcon = nil
    self.creepBuff = nil
    self.onClickCreepBuffIcon = nil
end

function TouchMenuCellProgressDatum:IsDynamic(element)
    return type(element) == "function"
end

---@return TouchMenuCellProgressDatum
function TouchMenuCellProgressDatum:SetCommonTimerData(commonTimerData)
    self.commonTimerData = commonTimerData
    return self
end

---@return TouchMenuCellProgressDatum
function TouchMenuCellProgressDatum:SetSubImage(image)
    self.subImage = image
    return self
end

---@return TouchMenuCellProgressDatum
function TouchMenuCellProgressDatum:SetShowProgressNumber(show)
    self.showProgressNumber = show
    return self
end

---@return TouchMenuCellProgressDatum
function TouchMenuCellProgressDatum:SetGoto(callback)
    self.gotoCallback = callback
    return self
end

---@param uiCell TouchMenuCellProgress
function TouchMenuCellProgressDatum:BindUICell(uiCell)
    self.uiCell = uiCell
    if self.dynamicProgress or self.dynamicTitle then
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
    end
    uiCell:UpdateHeader(self.imageHeader, self:GetTitle())
    uiCell:UpdateProgress(self:GetProgress(), self.showProgressNumber,self.customProgressNumber)
    uiCell:UpdateCommonTimer(self.commonTimerData)
    uiCell:UpdateSubImage(self.subImage)
    uiCell:UpdateGoto(self.gotoCallback)
    uiCell:UpdateCreepBuff(self.creepBuffIcon, self.creepBuff)
end

function TouchMenuCellProgressDatum:GetTitle()
    if self.dynamicTitle then
        return self.titleText()
    end
    return self.titleText
end

function TouchMenuCellProgressDatum:GetProgress()
    if self.dynamicProgress then
        return self.progress()
    end
    return self.progress
end

function TouchMenuCellProgressDatum:UnbindUICell()
    self.uiCell = nil
    if self.dynamicProgress then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function TouchMenuCellProgressDatum:GetPrefabIndex()
    return 5
end

function TouchMenuCellProgressDatum:OnTick()
    if not self.uiCell then
        return
    end
    if self.dynamicTitle then
        self.uiCell:UpdateHeader(self.imageHeader, self:GetTitle())
    end
    if self.dynamicProgress then
        self.uiCell:UpdateProgress(self:GetProgress(), self.showProgressNumber,self.customProgressNumber)
    end
end

---@param onClick fun(clickTrans:CS.UnityEngine.RectTransform, datum:TouchMenuCellProgressDatum)
function TouchMenuCellProgressDatum:SetCreepBufferCount(icon, count, onClick)
    self.creepBuffIcon = icon
    self.creepBuff = count
    self.onClickCreepBuffIcon = onClick
    return self
end

return TouchMenuCellProgressDatum