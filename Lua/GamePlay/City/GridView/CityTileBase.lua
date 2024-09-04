---@class CityTileBase
---@field new fun():CityTileBase
---@field tileView CityTileView
---@field gridView CityGridView
---@field x number
---@field y number
local CityTileBase = class("CityTileBase")
local CityUtils = require("CityUtils")
local CityConst = require("CityConst")
local Rect = require("Rect")

---@class CityCellBase
---@field new fun():CityCellBase
---@field IsBuilding fun(self:CityCellBase):boolean
---@field IsFurniture fun(self:CityCellBase):boolean
---@field IsResource fun(self:CityCellBase):boolean
---@field IsNpc fun(self:CityCellBase):boolean
---@field IsCreepNode fun(self:CityCellBase):boolean
---@field IsSafeAreaDoor fun(self:CityCellBase):boolean
---@field IsSafeAreaWall fun(self:CityCellBase):boolean
---@field GetZoneRecoverCfg fun(self:CityCellBase):CityZoneRecoverConfigCell

function CityTileBase:ctor(gridView, x, y)
    self.gridView = gridView
    self.x = x
    self.y = y
    self.cameraSize = self:GetCameraSize()
    self.priority = self:GetPriority()
    self.inMoveState = false
end

function CityTileBase:Show()
    if self.tileView == nil then
        self.tileView = self:CreateTileView()
        self.tileView:SetTile(self)
    end
    
    self.tileView:Show()
end

function CityTileBase:Hide()
    if self.tileView ~= nil then
        self.tileView:Hide()
    end
end

function CityTileBase:Refresh(force)
    if self.tileView then
        self.tileView:Refresh(force)
    end
end

function CityTileBase:CreateTileView()
    return self.gridView.viewFactory:Create(self:GetCell())
end

---@param tileView CityTileView
function CityTileBase:DestroyTileView(tileView, force)
    if tileView then
        tileView:Release(force);
        return self.gridView.viewFactory:Destroy(tileView)
    end
end

---@param pos CS.UnityEngine.Vector3
function CityTileBase:UpdatePosition(pos)
    self.pos = pos
    if self.tileView then
        self.tileView:UpdatePosition(pos)
    end
end

function CityTileBase:MoveEase(offset)
    self.pos = self.pos + offset
    if self.tileView then
        self.tileView:MoveEase(offset)
    end
end

function CityTileBase:SetParent(trans)
    if self.tileView then
        self.tileView:SetParent(trans)
    end
end

function CityTileBase:ResetParent()
    if self.tileView then
        self.tileView:ResetParent()
    end
end

function CityTileBase:GetRoot()
    if self.tileView then
        return self.tileView.root
    end
end

function CityTileBase:GetRotRoot()
    if self.tileView then
        return self.tileView.rotRoot
    end
end

function CityTileBase:Release(force)
    self:ReleaseView(force)

    self.x = nil
    self.y = nil
    self.pos = nil
    self.gridView = nil
end

function CityTileBase:ReleaseView(force)
    if self.tileView then
        self:Hide()
        self:DestroyTileView(self.tileView, force)
        self.tileView = nil
    end
end

---@return City|MyCity
function CityTileBase:GetCity()
    return self.gridView.city
end

function CityTileBase:GetCameraSize()
    ---override this
    return 0
end

function CityTileBase:GetPriority()
    ---override this
    return 0
end

function CityTileBase:Moveable()
    ---override this
    return false
end

---@return CityGridCell|CityFurniture|CitySafeAreaWallDoor|CityWorkProduceResGenUnit
function CityTileBase:GetCell()
    ---override this
    return nil
end

function CityTileBase:SetSelected(flag)
    if self.tileView then
        self.tileView:SetSelected(flag)
    end
end

function CityTileBase:GetWorldCenter()
    return CityUtils.GetCityCellCenterPos(self:GetCity(), self:GetCell())
end

function CityTileBase:IsPolluted()
    local cell = self:GetCell()
    if not cell then return false end

    local city = self:GetCity()
    if cell.IsFurniture and cell:IsFurniture() then
        return city.furnitureManager:IsPolluted(cell.singleId)
    elseif cell.IsBuilding and cell:IsBuilding() then
        return city.buildingManager:IsPolluted(cell.tileId)
    elseif cell.IsElement and cell:IsElement() then
        return city.elementManager:IsPolluted(cell.configId)
    elseif cell.IsSafeAreaWall and cell:IsSafeAreaWall() then
        return city.safeAreaWallMgr:IsPolluted(cell:UniqueId())
    elseif cell.IsSafeAreaDoor and cell:IsSafeAreaDoor()then
        return city.safeAreaWallMgr:IsPolluted(cell:UniqueId())
    end
    
    return false
end

function CityTileBase:OnMoveBegin()
    self.inMoveState = true
    if self.tileView then
        self.tileView:OnMoveBegin()
    end
end

function CityTileBase:OnMoveEnd()
    self.inMoveState = false
    if self.tileView then
        self.tileView:OnMoveEnd()
    end
end

function CityTileBase:GetTouchInfoData()
    local data = self:GetTouchInfoDataImp()
    if data == nil then return nil end

    return require("CityCreepCircleMenuPostProcessor").PostData(self, data)
end

---@private
---@return TouchMenuUIDatum
function CityTileBase:GetTouchInfoDataImp()
    local cell = self:GetCell()
    if cell:IsFurniture() then
        return require("CityFurnitureCircleMenuHelper").GetTouchInfoData(self)
    elseif cell:IsCreepNode() then
        return require("CityCreepNodeCircleMenuHelper").GetTouchInfoData(self)
    end
    return nil
end

function CityTileBase:SizeX()
    local cell = self:GetCell()
    return cell.sizeX
end

function CityTileBase:SizeY()
    local cell = self:GetCell()
    return cell.sizeY
end

function CityTileBase:Quaternion()
    local cell = self:GetCell()
    local direction = cell.direction or 0
    return CityConst.Quaternion[direction]
end

function CityTileBase:IsRoofHide()
    return false
end

function CityTileBase:BlockTriggerExecute()
    return false
end

function CityTileBase:GetRect()
    return Rect.new(self.x, self.y, self:SizeX(), self:SizeY())
end

function CityTileBase:GetNotMovableReason()
    return string.Empty
end

function CityTileBase:IsInner()
    return false
end

function CityTileBase:Inited()
    return self.gridView ~= nil
end

function CityTileBase:GetLegoBuilding()
    local city = self:GetCity()
    if not city then return nil end

    return city.legoManager:GetLegoBuildingAt(self.x, self.y)
end

return CityTileBase