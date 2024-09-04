local CityManagerBase = require("CityManagerBase")
---@class CitySlgLifeBarManager:CityManagerBase
---@field new fun():CitySlgLifeBarManager
---@field handleMap table<CitySlgLifeBarUnit, CitySlgLifeBarUnit>
---@field dirtyMap table<CitySlgLifeBarUnit, CitySlgLifeBarUnit>
---@field removeMap table<number, number>
local CitySlgLifeBarManager = class("CitySlgLifeBarManager", CityManagerBase)
local Delegate = require("Delegate")
local Utils = require("Utils")
local CitySlgLifeBarUnit = require("CitySlgLifeBarUnit")
local ModuleRefer = require("ModuleRefer")

---@param city City
function CitySlgLifeBarManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self:ClearIdPool()
end

function CitySlgLifeBarManager:OnViewLoadStart()
    self.handleMap = {}
    self.dirtyMap = {}
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CitySlgLifeBarManager:OnViewUnloadFinish()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    if Utils.IsNotNull(self.controller) then
        self.controller:UnloadAll()
    end
    self.controller = nil
    -- self.city.createHelper:Delete(self.assetHandle)
    self.assetHandle = nil
end

---@param go CS.UnityEngine.GameObject
function CitySlgLifeBarManager:OnControllerLoaded(go, userdata)
    if Utils.IsNull(go) then
        -- g_Logger.Error("SLG血条绘制器加载失败")
        return
    end
    -- self.controller = nil
end

function CitySlgLifeBarManager:OnTick()
    if self.dirty and Utils.IsNotNull(self.controller) then
        for _, id in pairs(self.removeMap) do
            self.controller:Remove(id)
        end
        table.clear(self.removeMap)

        for _, unit in pairs(self.dirtyMap) do
            self.controller:AddOrUpdate()
        end
        table.clear(self.dirtyMap)
        self.dirty = false
    end
end

function CitySlgLifeBarManager:ClearIdPool()
    self.id = 0
end

function CitySlgLifeBarManager:NextId()
    self.id = self.id + 1
    return self.id
end

function CitySlgLifeBarManager:AddUnit(x, y, cur, max, active)
    local unitBar = CitySlgLifeBarUnit.new(self, x, y, cur, max, active)
    self.handleMap[unitBar] = unitBar
    self.dirtyMap[unitBar] = unitBar
    self.dirty = true
    return unitBar
end

function CitySlgLifeBarManager:RemoveUnit(handler)
    if not handler then return end
    if not self.handleMap[handler] then return end
    
    self.handleMap[handler] = nil
    self:MarkRemove(handler.id)
end

---@param building CityBuilding
function CitySlgLifeBarManager:AddUnitByBuilding(building)
    local troop = ModuleRefer.SlgModule.troopManager:FindBuldingCtrlByViewId(building.id)
    local cur = troop ~= nil and 100 or 1
    local max = troop ~= nil and 100 or 1
    return self:AddUnit(building.x, building.y, cur, max, building.battleState or cur < max)
end

---@param furniture CityFurniture
function CitySlgLifeBarManager:AddUnitByFurniture(furniture)
    
end

function CitySlgLifeBarManager:MarkDirty(unit)
    if not self.handleMap[unit] then
        return
    end
    self.dirtyMap[unit] = unit
    self.dirty = true
end

function CitySlgLifeBarManager:MarkRemove(id)
    self.removeMap[id] = id
    self.dirty = true
end

return CitySlgLifeBarManager