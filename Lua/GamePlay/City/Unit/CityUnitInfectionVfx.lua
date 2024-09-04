local Utils = require("Utils")
local Delegate = require("Delegate")

---@class CityUnitInfectionVfx
---@field new fun(trans:CS.UnityEngine.Transform, prefab:string):CityUnitInfectionVfx
local CityUnitInfectionVfx = class('CityUnitInfectionVfx')

function CityUnitInfectionVfx.InitPoolRootOnce()
    if Utils.IsNotNull(CityUnitInfectionVfx._goCreator) then
        return
    end
    CityUnitInfectionVfx._goCreator = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("CityUnitInfectionVfxPool")
end

---@param trans CS.UnityEngine.Transform
---@param prefab string
function CityUnitInfectionVfx:ctor(trans, prefab)
    self._trans = trans
    self._assetPath = prefab
    ---@type CS.UnityEngine.GameObject
    self._go = nil
    self._assetReady = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._resHandle = CityUnitInfectionVfx._goCreator:Create(prefab, trans, Delegate.GetOrCreate(self, self.OnAssetReady))
end

---@param vfx CityUnitInfectionVfx
function CityUnitInfectionVfx.Delete(vfx)
    if Utils.IsNotNull(vfx._resHandle) then
        vfx._resHandle:Delete()
        return
    end
end

---@param trans CS.UnityEngine.Transform
---@return CityUnitInfectionVfx
function CityUnitInfectionVfx.GetOrCreate(trans, prefab)
    return CityUnitInfectionVfx.new(trans, prefab)
end

function CityUnitInfectionVfx:OnAssetReady(go)
    if Utils.IsNull(go) then
        return
    end
    self._go = go
    self._assetReady = true
end

function CityUnitInfectionVfx:SetStatus(status)
    
end

return CityUnitInfectionVfx