local AllianceActivityDataProviderDefine = require("AllianceActivityDataProviderDefine")

---@class AllianceActivityCellData
local AllianceActivityCellData = class("AllianceActivityCellData")

function AllianceActivityCellData.GetSoureType()
    ---override me!!!
    return AllianceActivityDataProviderDefine.SourceType.Unknown
end

function AllianceActivityCellData:ctor(id)
    self._cellId = id
    self._cellKey = ("%s_%s"):format(self.GetSoureType(), self._cellId)
end

---@return string
function AllianceActivityCellData:GetCellDataKey()
    return self._cellKey
end

function AllianceActivityCellData:GetPrefabIndex()
    return 0
end

function AllianceActivityCellData:LastUpdateTime()
    return 0
end

---@param cell AllianceWarActivityCell
function AllianceActivityCellData:OnCellEnter(cell)
end

---@param cell AllianceWarActivityCell
function AllianceActivityCellData:OnCellExit(cell)
end

function AllianceActivityCellData:SetupEvent(add)
end

function AllianceActivityCellData:OnClickBtnPosition()
end

function AllianceActivityCellData:OnClickBtnGoto()
end

return AllianceActivityCellData