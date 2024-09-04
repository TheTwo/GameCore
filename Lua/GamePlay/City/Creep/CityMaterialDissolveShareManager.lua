local Delegate = require("Delegate")

local CityManagerBase = require("CityManagerBase")
---@class CityMaterialDissolveShareManager:CityManagerBase
---@field super CityManagerBase
local CityMaterialDissolveShareManager = class("CityMaterialDissolveShareManager", CityManagerBase)

---@param city MyCity
---@vararg CityManagerBase
function CityMaterialDissolveShareManager:ctor(city, ...)
    CityMaterialDissolveShareManager.super.ctor(self, city, ...)
    ---@type CS.DragonReborn.City.Creep.CityMaterialDissolveShareController
    self.csController = nil
end

function CityMaterialDissolveShareManager:OnViewLoadStart()
    if not self.csController then
        self.csController = CS.DragonReborn.City.Creep.CityMaterialDissolveShareController()
    end
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityMaterialDissolveShareManager:OnViewUnloadFinish()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    if self.csController then
        self.csController:CleanUp()
        self.csController = nil
    end
end

---@param go CS.UnityEngine.GameObject
---@param delay number|nil
---@param onComplete fun()|nil
function CityMaterialDissolveShareManager:AddToTweenDissolve(go,filterToggle,endToggle,duration, from, to, delay, onComplete)
    if self.csController then
        self.csController:AddToTweenDissolve(go,filterToggle, endToggle, duration * 1000, from * 1000, to * 1000, (delay or 0) * 1000, onComplete)
    end
end

function CityMaterialDissolveShareManager:Tick(dt)
    self.csController:Tick(dt)
end

return CityMaterialDissolveShareManager