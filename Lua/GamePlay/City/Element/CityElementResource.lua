local CityElement = require("CityElement")
---@class CityElementResource:CityElement
---@field new fun():CityElementResource
local CityElementResource = class("CityElementResource", CityElement)
local ConfigRefer = require("ConfigRefer")
local CityNode = require("CityNode")
local CityGridCellDef = require("CityGridCellDef")

---@param temp boolean 是否是栈上临时对象
function CityElementResource:ToCityNode(temp)
    if temp then
        return CityNode.Temp(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.RESOURCE)
    else
        return CityNode.new(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.RESOURCE)
    end
end

function CityElementResource:IsResource()
    return true
end

function CityElementResource.CreateResourceFromElementData(mgr, configCell)
    local ret = CityElementResource.new(mgr)
    ret:FromElementDataCfg(configCell)
    ret.resourceConfigCell = ConfigRefer.CityElementResource:Find(configCell:ElementId())
    ret.resCfgId = ret.resourceConfigCell:Id()
    ret.resType = ret.resourceConfigCell:Type()
    ret.sizeX = ret.resourceConfigCell:SizeX()
    ret.sizeY = ret.resourceConfigCell:SizeY()
    return ret
end

function CityElementResource.CreateResourceFromManual(mgr, id, x, y, cfgId)
    local ret = CityElementResource.new(mgr)
    ret:FromManualData(id, x, y)
    ret.resourceConfigCell = ConfigRefer.CityElementResource:Find(cfgId)
    ret.resCfgId = ret.resourceConfigCell:Id()
    ret.resType = ret.resourceConfigCell:Type()
    ret.sizeX = ret.resourceConfigCell:SizeX()
    ret.sizeY = ret.resourceConfigCell:SizeY()
    return ret
end

function CityElementResource:RegisterInteractPoints()
    local hasPoint = false
    if self.resourceConfigCell then
        local rotation = 0
        local sx = self.sizeX
        local sy = self.sizeY
        ---@type CityLegoBuilding
        local ownerBuilding = self.mgr.city.legoManager:GetLegoBuildingAt(self.x, self.y)
        local rangeMinX,rangeMinY,rangeMaxX,rangeMaxY
        if ownerBuilding then
            rangeMinX = ownerBuilding.x
            rangeMinY = ownerBuilding.z
            rangeMaxX = rangeMinX + ownerBuilding.sizeX
            rangeMaxY = rangeMinY + ownerBuilding.sizeZ
        end
        for i = 1, self.resourceConfigCell:RefInteractPosLength() do
            local refPointId = self.resourceConfigCell:RefInteractPos(i)
            local refPointConfig = ConfigRefer.CityInteractionPoint:Find(refPointId)
            local add = self.mgr:RegisterInteractPoints(self, refPointConfig, rotation, ownerBuilding, rangeMinX,rangeMinY,rangeMaxX,rangeMaxY, sx, sy)
            if add then hasPoint = true end
        end
    end
    if not hasPoint then
        self.mgr.city.cityInteractPointManager:MarkElementNoInteractPoint(self.id)
    end
end

function CityElementResource:UnRegisterInteractPoints()
    self.mgr.city.cityInteractPointManager:UnMarkElementNoInteractPoint(self.id)
    self.mgr:UnRegisterInteractPoints(self)
end

return CityElementResource