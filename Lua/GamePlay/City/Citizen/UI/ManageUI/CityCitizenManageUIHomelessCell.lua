local Delegate = require("Delegate")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")

local CityCitizenManageUIDraggableCell = require("CityCitizenManageUIDraggableCell")

---@class CityCitizenManageUIHomelessCell:CityCitizenManageUIDraggableCell
---@field new fun():CityCitizenManageUIHomelessCell
---@field super CityCitizenManageUIDraggableCell
local CityCitizenManageUIHomelessCell = class('CityCitizenManageUIHomelessCell', CityCitizenManageUIDraggableCell)

function CityCitizenManageUIHomelessCell:OnCreate(_)
    ---@type CommonCitizenCellComponent
    self._child_item_resident = self:LuaObject("child_item_resident")
    self:BindDrag(self._child_item_resident)
end

function CityCitizenManageUIHomelessCell:OnFeedData(data)
    CityCitizenManageUIDraggableCell.OnFeedData(self, data)
    ---@type CommonCitizenCellComponentParameter
    local cellData = {}
    cellData.citizenData = data.citizenData
    cellData.citizenWork = data.citizenWork
    cellData.allowShowBuffDetail = true
    cellData.onClickSelf = Delegate.GetOrCreate(self, self.OnClickSelf)
    cellData.onClickRecover = Delegate.GetOrCreate(self, self.OnClickRecover)
    if self._data.OnRecall then
        cellData.onClickRecall = Delegate.GetOrCreate(self, self.OnReCall)
    else
        cellData.onClickRecall = nil
    end
    self._child_item_resident:FeedData(cellData)
end

function CityCitizenManageUIHomelessCell:Select(_)
    self._child_item_resident:SetSelected(true)
end

function CityCitizenManageUIHomelessCell:UnSelect(_)
    self._child_item_resident:SetSelected(false)
end

function CityCitizenManageUIHomelessCell:OnClickSelf()
    self._data.OnSelected(self._data)
end

function CityCitizenManageUIHomelessCell:OnClickRecover()
    if self._data.OnClickRecover then
        self._data.OnClickRecover(self._data)
    end
end

function CityCitizenManageUIHomelessCell:OnReCall()
    if self._data.OnRecall then
        self._data.OnRecall(self._data)
    end
end

return CityCitizenManageUIHomelessCell