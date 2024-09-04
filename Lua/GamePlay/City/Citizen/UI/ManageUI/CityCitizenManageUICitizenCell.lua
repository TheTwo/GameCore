local Delegate = require("Delegate")

local CityCitizenManageUIDraggableCell = require("CityCitizenManageUIDraggableCell")

---@class CityCitizenManageUICitizenCell:CityCitizenManageUIDraggableCell
---@field new fun():CityCitizenManageUICitizenCell
---@field super CityCitizenManageUIDraggableCell
local CityCitizenManageUICitizenCell = class('CityCitizenManageUICitizenCell', CityCitizenManageUIDraggableCell)

function CityCitizenManageUICitizenCell:ctor()
    CityCitizenManageUIDraggableCell.ctor(self)
end

function CityCitizenManageUICitizenCell:OnCreate(_)
    ---@type CommonCitizenCellComponent
    self._child_item_resident = self:LuaObject("child_item_resident")
    self:BindDrag(self._child_item_resident)
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUICitizenCell:OnFeedData(data)
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

function CityCitizenManageUICitizenCell:Select(_)
    self._child_item_resident:SetSelected(true)
end

function CityCitizenManageUICitizenCell:UnSelect(_)
    self._child_item_resident:SetSelected(false)
end

function CityCitizenManageUICitizenCell:OnClickSelf()
    self._data.OnSelected(self._data)
end

function CityCitizenManageUICitizenCell:OnClickRecover()
    if self._data.OnClickRecover then
        self._data.OnClickRecover(self._data)
    end
end

function CityCitizenManageUICitizenCell:OnReCall()
    if self._data.OnRecall then
        self._data.OnRecall(self._data)
    end
end

return CityCitizenManageUICitizenCell

