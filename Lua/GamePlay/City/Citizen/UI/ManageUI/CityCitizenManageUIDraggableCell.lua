local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityCitizenManageUIDraggableCellData
---@field index number
---@field citizenData CityCitizenData
---@field citizenWork CityCitizenWorkData
---@field OnSelected fun(data:CityCitizenManageUIDraggableCellData)
---@field OnRecall fun(data:CityCitizenManageUIDraggableCellData)
---@field OnClickRecover fun(data:CityCitizenManageUIDraggableCellData)
---@field OnBeginDrag fun(data:CityCitizenManageUIDraggableCellData, go:CS.UnityEngine.GameObject, event:CS.UnityEngine.EventSystems.PointerEventData):boolean
---@field OnDrag fun(data:CityCitizenManageUIDraggableCellData, go:CS.UnityEngine.GameObject, event:CS.UnityEngine.EventSystems.PointerEventData)
---@field OnEndDrag fun(data:CityCitizenManageUIDraggableCellData, go:CS.UnityEngine.GameObject, event:CS.UnityEngine.EventSystems.PointerEventData)

---@class CityCitizenManageUIDraggableCell:BaseTableViewProCell
---@field new fun():CityCitizenManageUIDraggableCell
---@field super BaseTableViewProCell
local CityCitizenManageUIDraggableCell = class('CityCitizenManageUIDraggableCell', BaseTableViewProCell)

function CityCitizenManageUIDraggableCell:ctor()
    BaseTableViewProCell.ctor(self)
    ---@type boolean
    self._inDrag = false
    ---@type CityCitizenManageUIDraggableCellData
    self._data = nil
end

---@param component CommonCitizenCellComponent
function CityCitizenManageUIDraggableCell:BindDrag(component)
    component:BindDrag(Delegate.GetOrCreate(self, self.OnBeginDrag)
            , Delegate.GetOrCreate(self, self.OnDrag)
            , Delegate.GetOrCreate(self, self.OnEndDrag)
            , true
    )
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIDraggableCell:OnFeedData(data)
    self._data = data
end

function CityCitizenManageUIDraggableCell:OnBeginDrag(go, event)
    if not self._data.OnBeginDrag then return end
    if self._data.OnBeginDrag(self._data, go, event) then
        self._inDrag = true
    else
        self._inDrag = false
    end
end

function CityCitizenManageUIDraggableCell:OnDrag(go, event)
    if not self._data.OnDrag then return end
    if self._inDrag then
        self._data.OnDrag(self._data, go, event)
    end
end

function CityCitizenManageUIDraggableCell:OnEndDrag(go, event)
    if not self._data.OnEndDrag then return end
    if self._inDrag then
        self._data.OnEndDrag(self._data, go, event)
        self._inDrag = false
    end
end

return CityCitizenManageUIDraggableCell
