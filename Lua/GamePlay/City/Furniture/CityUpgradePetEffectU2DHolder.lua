---@class CityUpgradePetEffectU2DHolder
---@field new fun(manager, furnitureId, info):CityUpgradePetEffectU2DHolder
local CityUpgradePetEffectU2DHolder = class("CityUpgradePetEffectU2DHolder")
local ManualResourceConst = require("ManualResourceConst")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@param manager CityFurnitureManager
---@param furnitureId number
---@param info CityPetCountdownUpgradeTimeInfo
function CityUpgradePetEffectU2DHolder:ctor(manager, furnitureId, info)
    self.manager = manager
    self.furnitureId = furnitureId
    self.info = info
    self.city = self.manager.city
end

function CityUpgradePetEffectU2DHolder:Create()
    self.remainTime = self.manager:GetPetEffectU2DRemainTime()
    self.handle = self.city.createHelper:Create(ManualResourceConst.ui3d_toast_city_buff, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnCreated))
    return self.handle
end

---@param go CS.UnityEngine.GameObject
function CityUpgradePetEffectU2DHolder:OnCreated(go, userdata, handle)
    if Utils.IsNull(go) then return end

    go:SetLayerRecursively("City")
    local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture then
        local position = self.city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY)
        go.transform:SetPositionAndRotation(position, CS.UnityEngine.Quaternion.identity)
    end
    local behaviour = go:GetLuaBehaviour("CityPetDecreaseUpgradeTime")
    if Utils.IsNotNull(behaviour) then
        ---@type CityPetDecreaseUpgradeTime
        local luaComp = behaviour.Instance
        luaComp:ShowInfo(self.info)
    end
    self.remainTime = self.manager:GetPetEffectU2DRemainTime()
end

function CityUpgradePetEffectU2DHolder:Dispose()
    self.handle:Delete()
end

return CityUpgradePetEffectU2DHolder