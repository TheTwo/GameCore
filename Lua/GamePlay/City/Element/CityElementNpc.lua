local CityElement = require("CityElement")
---@class CityElementNpc:CityElement
---@field new fun(configCell:CityElementDataConfigCell):CityElementNpc
local CityElementNpc = class("CityElementNpc", CityElement)
local ConfigRefer = require("ConfigRefer")
local CityNode = require("CityNode")
local CityGridCellDef = require("CityGridCellDef")

---@param mgr CityElementManager
---@param configCell CityElementDataConfigCell
function CityElementNpc:ctor(mgr, configCell)
    CityElement.ctor(self, mgr)
    self:FromElementDataCfg(configCell)
    self.npcConfigCell = ConfigRefer.CityElementNpc:Find(configCell:ElementId())
    self.sizeX = self.npcConfigCell:SizeX()
    self.sizeY = self.npcConfigCell:SizeY()
end

function CityElementNpc:IsNpc()
    return true
end

---@param temp boolean 是否是栈上临时对象
function CityElementNpc:ToCityNode(temp)
    if temp then
        return CityNode.Temp(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.NPC)
    else
        return CityNode.new(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.NPC)
    end
end

---@param mgr CityElementManager
function CityElementNpc:RegisterInteractPoints()
    if self.npcConfigCell then
        ---@type CityLegoBuilding
        local ownerBuilding = self.mgr.city.legoManager:GetLegoBuildingAt(self.x, self.y)
        local rangeMinX,rangeMinY,rangeMaxX,rangeMaxY
        if ownerBuilding then
            rangeMinX = ownerBuilding.x
            rangeMinY = ownerBuilding.z
            rangeMaxX = rangeMinX + ownerBuilding.sizeX
            rangeMaxY = rangeMinY + ownerBuilding.sizeZ
        end
        local rotation = 0
        local sx = self.sizeX
        local sy = self.sizeY
        for i = 1, self.npcConfigCell:RefInteractPosLength() do
            local refPointId = self.npcConfigCell:RefInteractPos(i)
            local refPointConfig = ConfigRefer.CityInteractionPoint:Find(refPointId)
            self.mgr:RegisterInteractPoints(self, refPointConfig, rotation, ownerBuilding, rangeMinX,rangeMinY,rangeMaxX,rangeMaxY, sx, sy)
        end
    end
end

function CityElementNpc:UnRegisterInteractPoints()
    self.mgr:UnRegisterInteractPoints(self)
end

return CityElementNpc