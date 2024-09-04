local CityElement = require("CityElement")
---@class CityElementCreep:CityElement
---@field new fun(configCell:CityElementDataConfigCell):CityElementCreep
local CityElementCreep = class("CityElementCreep", CityElement)
local ConfigRefer = require("ConfigRefer")
local CityNode = require("CityNode")
local CityGridCellDef = require("CityGridCellDef")

---@param mgr CityElementManager
---@param configCell CityElementDataConfigCell
function CityElementCreep:ctor(mgr, configCell)
    CityElement.ctor(self, mgr)
    self:FromElementDataCfg(configCell)
    self.creepConfigCell = ConfigRefer.CityElementCreep:Find(configCell:ElementId())
    self.sizeX = self.creepConfigCell:SizeX()
    self.sizeY = self.creepConfigCell:SizeY()
    self.ServiceGroupId = self.creepConfigCell:ServiceGroupId()
end

---@param temp boolean 是否是栈上临时对象
function CityElementCreep:ToCityNode(temp)
    if temp then
        return CityNode.Temp(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.CREEP_NODE)
    else
        return CityNode.new(self.x, self.y, self.sizeX, self.sizeY, self.id, self.configId, CityGridCellDef.ConfigType.CREEP_NODE)
    end
end

return CityElementCreep