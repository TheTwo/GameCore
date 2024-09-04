local CityManagerBase = require("CityManagerBase")
---@class CityGrid:CityManagerBase
---@field new fun():CityGrid
---@field gridConfig CityGridConfig
local CityGrid = class("CityGrid", CityManagerBase)
local CityGridCell = require("CityGridCell")
local EventConst = require("EventConst")
local RectDyadicMap = require("RectDyadicMap")
local CityGridLayerMask = require("CityGridLayerMask")

function CityGrid:OnDataLoadStart()
    CityManagerBase.OnDataLoadStart(self)
    self:SwitchEditorNotice(true)
end

function CityGrid:OnDataLoadFinish()
    self:SwitchEditorNotice(false)
    CityManagerBase.OnDataLoadFinish(self)
end

function CityGrid:DoDataLoad()
    self.errorTimes = 0
    self.gridConfig = self.city.gridConfig
    self.cells = RectDyadicMap.new(self.gridConfig.cellsX, self.gridConfig.cellsY)
    ---@type table<CityGridCell, CityGridCell>
    self.hashMap = setmetatable({}, {__mode = "kv"})
    self.inited = true
    return self:DataLoadFinish()
end

function CityGrid:DoDataUnload()
    self.cells = nil
    self.gridConfig = nil
    self.hashMap = nil
    self.inited = false
end

---@param node CityNode
function CityGrid:AddCell(node)
    local gridLayer = self.city.gridLayer;
    for x = node.x, node.x + node.sizeX - 1 do
        for y = node.y, node.y + node.sizeY - 1 do
            local mask = gridLayer:Get(x, y)
            if CityGridLayerMask.IsPlacedExceptLego(mask) then
                local illegal = true
                local cell = self:GetCell(x, y)
                if CityGridLayerMask.HasBuilding(mask) and cell:IsBuilding() then
                    self:LogErrorWithEditorDialog(("Overlap other existed Building([X:%d,Y:%d,levelId:%d,sid:%d]) wanna add %s"):format(cell.x, cell.y, cell.configId, cell.tileId, node:ToString()))
                elseif CityGridLayerMask.HasResource(mask) and cell:IsResource() then
                    self:LogErrorWithEditorDialog(("Overlap other existed resource %s, wanna add %s"):format(cell:ToCityNode(false):ToString(), node:ToString()))
                elseif CityGridLayerMask.HasNpc(mask) and cell:IsNpc() then
                    self:LogErrorWithEditorDialog(("Overlap other existed npc %s, wanna add %s"):format(cell:ToCityNode(false):ToString(), node:ToString()))
                elseif CityGridLayerMask.HasCreepNode(mask) and cell:IsCreepNode() then
                    self:LogErrorWithEditorDialog(("Overlap other existed creep node %s, wanna add %s"):format(cell:ToCityNode(false):ToString(), node:ToString()))
                elseif CityGridLayerMask.HasFurniture(mask) then
                    local fur = self.city.furnitureManager:GetPlaced(x, y)
                    self:LogErrorWithEditorDialog(("Overlap other existed Furniture([X:%d,Y:%d,levelId:%d,sid:%d]) wanna add %s"):format(fur.x, fur.y, fur.configId, fur.singleId, node:ToString()))
                elseif CityGridLayerMask.IsGeneratingRes(mask) then
                    if cell == nil then
                        illegal = false
                    end
                elseif CityGridLayerMask.IsSafeAreaWall(mask) then
                    self:LogErrorWithEditorDialog(("Overlap other existed SafeAreaWall at [X:%d, Y:%d]. wanna add %s"):format(x, y, node:ToString()))
                    illegal = false
                end

                if illegal then
                    return
                end
            end
        end
    end

    local x, y = math.floor(node.x + 0.5), math.floor(node.y + 0.5)
    if not self:IsSquareValid(node.x, node.y, node.sizeX, node.sizeY) then
        g_Logger.Error(("Overflows at (X:%d,Y:%d), size (X:%d, Y:%d)"):format(node.x, node.y, node.sizeX, node.sizeY))
        return
    end
    
    local mainCell = self:CreateCell(x, y)
    if mainCell then
        self:AddCellImp(mainCell, node)
        self.hashMap[mainCell] = mainCell
        self:OnCellAdded(x, y)
    end
end

---@param cell CityGridCell
---@param node CityNode
function CityGrid:AddCellImp(cell, node)
    local x, y = math.floor(node.x + 0.5), math.floor(node.y + 0.5)
    cell:FromCityNode(node)
    
    for i = 0, node.sizeX - 1 do
        for j = 0, node.sizeY - 1 do
            self.cells:Add(x+i, y+j, cell)
        end
    end
end

---@return CityGridCell
function CityGrid:GetCell(x, y)
    if not self:IsLocationValid(x, y) then
        return nil
    end

    local cell = self.cells:Get(x, y)
    return cell
end

---@param tileId number
---@return CityGridCell
function CityGrid:FindMainCellWithTileId(tileId)
    for _,_,v in self.cells:pairs() do
        if v.tileId == tileId then
            return v
        end
    end
    return nil
end

function CityGrid:CreateCell(x, y)
    if not self:IsLocationValid(x, y) then
        return nil
    end

    if self.cells:Get(x, y) then
        g_Logger.Error(("Logic Error, gridCell data redundancy X:%d, Y:%d"):format(x, y))
        -- error("Logic Error, gridCell data redundancy")
        return nil
    end

    return CityGridCell.new(x, y)
end

---@param node CityNode
function CityGrid:UpdateCell(node, delay)
    if not self:IsLocationValid(node.x, node.y) then
        return nil
    end

    local cell = self:GetCell(node.x, node.y)
    local oldSizeX, oldSizeY = cell.sizeX, cell.sizeY
    local idChanged = cell.configId ~= node.configId
    if node.sizeX ~= oldSizeX or node.sizeY ~= oldSizeY then
        if not self:CellSizeChangeCheck(cell, node.sizeX, node.sizeY) then
            g_Logger.ErrorChannel("City", ("非法扩容 at (X:%d, Y:%d), sizeX:%d, sizeY:%d"):format(cell.x, cell.y, node.sizeX, node.sizeY))
            return
        end

        self:RemoveCellImp(cell)
        self:AddCellImp(cell, node)
        self:OnCellUpdatedSizeWithSizeChange(node.x, node.y, oldSizeX, oldSizeY, cell.sizeX, cell.sizeY)
    else
        cell:FromCityNode(node)
    end
    if idChanged then
        self:OnCellIdChanged(node.x, node.y)
    end
    self:OnCellUpdated(node.x, node.y, delay)
end

---@param cell CityGridCell
---@param sizeX number
---@param sizeY number
function CityGrid:CellSizeChangeCheck(cell, sizeX, sizeY)
    if sizeX <= 0 or sizeY <= 0 then
        return false
    end

    if sizeX <= cell.sizeX and sizeY <= cell.sizeY then
        return true
    end

    local gridLayer = self.city.gridLayer
    local XExtend = sizeX > cell.sizeX
    if XExtend then
        for x = cell.x + cell.sizeX, cell.x + sizeX - 1 do
            for y = cell.y, cell.y + cell.sizeY - 1 do
                if CityGridLayerMask.IsPlaced(gridLayer:Get(x, y)) then
                    return false
                end
            end
        end
    end

    local YExtend = sizeY > cell.sizeY
    if YExtend then
        for y = cell.y + cell.sizeY, cell.y + sizeY - 1 do
            for x = cell.x, cell.x + cell.sizeX - 1 do
                if CityGridLayerMask.IsPlaced(gridLayer:Get(x, y)) then
                    return false
                end
            end
        end
    end

    if XExtend and YExtend then
        for x = cell.x + cell.sizeX, cell.x + sizeX - 1 do
            for y = cell.y + cell.sizeY, cell.y + sizeY - 1 do
                if CityGridLayerMask.IsPlaced(gridLayer:Get(x, y)) then
                    return false
                end
            end
        end
    end

    return true
end

function CityGrid:MovingCell(oriX, oriY, newX, newY)
    local cell = self:GetCell(oriX, oriY)
    if not cell then
        error("Can't moving empty node")
    end
    oriX, oriY = cell.x, cell.y
    cell = self:RemoveCellImp(cell)
    cell.x, cell.y = newX, newY
    self.cells:Add(newX, newY, cell)
    for i = 1, #cell.children, 2 do
        self.cells:Add(cell.children[i] + cell.x, cell.children[i+1] + cell.y, cell)
    end

    self:OnCellMoving(oriX, oriY, newX, newY)
end

function CityGrid:RemoveCell(x, y)
    if not self:IsLocationValid(x, y) then
        return
    end

    local cell = self:GetCell(x, y)
    if not cell then
        return
    end

    self:RemoveCellImp(cell)
    self.hashMap[cell] = nil
    self:OnCellRemove(cell)
end

---@param cell CityGridCell
---@return CityGridCell
function CityGrid:RemoveCellImp(cell)
    if cell.children then
        for i = 1, #cell.children, 2 do
            self.cells:Delete(cell.x + cell.children[i], cell.y + cell.children[i+1])
        end
    end
    return self.cells:Delete(cell.x, cell.y)
end

function CityGrid:OnCellAdded(x, y)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_ADD, self.city, x, y)
end

function CityGrid:OnCellUpdated(x, y, delay)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_UPDATE, self.city, x, y, delay)
end

function CityGrid:OnCellIdChanged(x, y)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_ID_CHANGED, self.city, x, y)
end

function CityGrid:OnCellUpdatedSizeWithSizeChange(x, y, oldSizeX, oldSizeY, newSizeX, newSizeY)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_UPDATE_WITH_SIZE_CHANGE, self.city, x, y, oldSizeX, oldSizeY, newSizeX, newSizeY)
end

function CityGrid:OnCellRemove(cell)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_REMOVE, self.city, cell)
end

function CityGrid:OnCellMoving(oriX, oriY, newX, newY)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_ON_CELL_MOVING, self.city, oriX, oriY, newX, newY)
end

---@param vec CS.UnityEngine.Vector3
function CityGrid:GetCoordFromLocalPosition(vec, notUseFloorInt)
    local x,y
    if not notUseFloorInt then 
        x = math.floor(vec.x / self.gridConfig.unitsPerCellX) - self.gridConfig.minX
        y = math.floor(vec.z / self.gridConfig.unitsPerCellY) - self.gridConfig.minY
    else
        x = (vec.x / self.gridConfig.unitsPerCellX) - self.gridConfig.minX
        y = (vec.z / self.gridConfig.unitsPerCellY) - self.gridConfig.minY
    end
    return x, y
end

function CityGrid:IsLocationValid(x, y)
    return self.gridConfig:IsLocationValid(x, y)
end

function CityGrid:IsEmpty(x, y)
    ---@type CityGridCell
    local cell = self.cells:Get(x, y)
    return not cell
end

---@return fun():number, number, CityGridCell
function CityGrid:pairs()
    return self.cells:pairs()
end

function CityGrid:IsSquareValid(x, y, sizeX, sizeY)
    if sizeX == 0 or sizeY == 0 then
        g_Logger.ErrorChannel("City", ("SizeX or SizeY can't be zero, at (%d,%d), size:(%d,%d)"):format(x, y, sizeX, sizeY))
        return false
    end

    return self:IsLocationValid(x, y) and
        self:IsLocationValid(x + sizeX - 1, y) and
        self:IsLocationValid(x, y + sizeY - 1) and
        self:IsLocationValid(x + sizeX - 1, y + sizeY - 1)
end

function CityGrid:NeedLoadData()
    return true
end

function CityGrid:SwitchEditorNotice(flag)
    if not UNITY_EDITOR then return end

    self.showEditorDialog = flag
end

function CityGrid:LogErrorWithEditorDialog(msg)
    g_Logger.ErrorChannel("CityGrid", msg)
    
    if not self.showEditorDialog then return end
    if self.errorTimes >= 3 then return end
    self.errorTimes = self.errorTimes + 1
    local WarningToolsForDesigner = require("WarningToolsForDesigner")
    WarningToolsForDesigner.DisplayEditorDialog("地块冲突,检查配置和数据", msg)
end

return CityGrid