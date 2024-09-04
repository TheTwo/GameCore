
local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@class TouchMenuCellBehemothDeviceDatum:TouchMenuCellDatumBase
---@field new fun():TouchMenuCellBehemothDeviceDatum
---@field super TouchMenuCellDatumBase
local TouchMenuCellBehemothDeviceDatum = class('TouchMenuCellBehemothDeviceDatum', TouchMenuCellDatumBase)

function TouchMenuCellBehemothDeviceDatum:GetPrefabIndex()
    return 16
end

---@return string
function TouchMenuCellBehemothDeviceDatum:GetLabel()
    return self._label
end

---@param labelStr string
function TouchMenuCellBehemothDeviceDatum:SetLabel(labelStr)
    self._label = labelStr
    return self
end

---@return AllianceBehemothHeadCellData
function TouchMenuCellBehemothDeviceDatum:GetBehemothHeadCellData()
    return self._cellData
end

---@param cellData AllianceBehemothHeadCellData
function TouchMenuCellBehemothDeviceDatum:SetBehemothHeadCellData(cellData)
    self._cellData = cellData
    return self
end

function TouchMenuCellBehemothDeviceDatum:HasCallback()
    return self._callback ~= nil
end

function TouchMenuCellBehemothDeviceDatum:OnClickGoto()
    if self._callback then
        return self._callback(self.context)
    end
end

---@field callback fun(context:any):boolean
---@field context any
function TouchMenuCellBehemothDeviceDatum:SetClickGotoCallback(callback, context)
    self._callback = callback
    self._context = context
    return self
end

return TouchMenuCellBehemothDeviceDatum