local CityManagerBase = require("CityManagerBase")
---@class CitySoundManager:CityManagerBase
---@field new fun():CitySoundManager
local CitySoundManager = class("CitySoundManager", CityManagerBase)
local AudioConsts = require("AudioConsts")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local OnChangeHelper = require("OnChangeHelper")
local ConfigRefer = require("ConfigRefer")

function CitySoundManager:OnViewLoadFinish()
    self.soundMaps = {}
    self.upgrading = {}
    ---@type table<number, {gameObject:CS.UnityEngine.GameObject,handle:CS.DragonReborn.SoundPlayingHandle}>
    self.furnitureSoundMaps = {}
    self:SetupEvents(true)
end

function CitySoundManager:OnViewUnloadStart()
    self:SetupEvents(false)
    for _, v in pairs(self.furnitureSoundMaps) do
        g_Game.SoundManager:Stop(v.handle)
        CS.UnityEngine.Object.Destroy(v.gameObject)
    end
    for k, v in pairs(self.soundMaps) do
        g_Game.SoundManager:Stop(v.handle)
        CS.UnityEngine.Object.Destroy(v.gameObject)
    end
    self.soundMaps = nil
end

---@param building CityBuilding
function CitySoundManager:PlayUpgradingBuilding(building)
    if self.upgrading[building] then
        return
    end

    local pos = building:CenterPos()
    local go = CS.UnityEngine.GameObject(("building[%d]_upgrade"):format(building.id))
    go.transform:SetPositionAndRotation(pos, CS.UnityEngine.Quaternion.identity)
    go.transform:SetParent(self.city.CityRoot.transform)
    local handle = g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_putup, go)
    self.soundMaps[building] = {gameObject = go, handle = handle}
end

function CitySoundManager:StopUpgradingBuilding(building)
    if not self.upgrading[building] then return end

    g_Game.SoundManager:Stop(self.soundMaps[building].handle)
    CS.UnityEngine.Object.Destroy(self.soundMaps[building].gameObject)

    self.soundMaps[building] = nil
end

function CitySoundManager:PlayPutDownSound(pos)
    local go = CS.UnityEngine.GameObject("putdown")
    go.transform:SetPositionAndRotation(pos, CS.UnityEngine.Quaternion.identity)
    go.transform:SetParent(self.city.CityRoot.transform)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_putdown, go, true)
end

function CitySoundManager:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = add
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    elseif self._eventAdd and not add then
        self._eventAdd = add
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    end
end

---@param furnitureId number
---@param furniture wds.CastleFurniture
function CitySoundManager:PlayFurnitureWorkSound(furnitureId, furniture)
    if self.furnitureSoundMaps[furnitureId] then
        return
    end
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(furniture.ConfigId)
    if not lvCfg then
        return
    end
    local ft = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    if not ft then
        return
    end
    local sound = ft:WorkSoundRes()
    if sound <= 0 then
        return
    end
    local pos = furniture.Pos
    local worldPos = self.city:GetCenterWorldPositionFromCoord(pos.X, pos.Y, lvCfg:SizeX(), lvCfg:SizeY())
    local go = CS.UnityEngine.GameObject(("furniture[%d]_work"):format(furnitureId))
    go.transform:SetPositionAndRotation(worldPos, CS.UnityEngine.Quaternion.identity)
    go.transform:SetParent(self.city.CityRoot.transform)
    local handle = g_Game.SoundManager:PlayAudio(sound, go)
    self.furnitureSoundMaps[furnitureId] = {gameObject = go, handle = handle}
end

---@param furnitureId number
function CitySoundManager:StopFurnitureWorkSound(furnitureId)
    local p = self.furnitureSoundMaps[furnitureId]
    if not p then
        return
    end
    self.furnitureSoundMaps[furnitureId] = nil
    g_Game.SoundManager:Stop(p.handle)
    CS.UnityEngine.Object.Destroy(p.gameObject)
end

---@param entity wds.CastleBrief
---@param changedData table
function CitySoundManager:OnFurnitureDataChanged(entity, changedData)
    if not self.city or self.city.uid ~= entity.ID then
        return
    end
    local add,remove,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.CastleFurniture)
    if remove then
        for furnitureId, _ in pairs(remove) do
            self:StopFurnitureWorkSound(furnitureId)
        end
    end
    if add then
        for furnitureId, v in pairs(add) do
            if v.ProcessInfo and v.ProcessInfo.LeftNum > 0 then
                self:PlayFurnitureWorkSound(furnitureId, v)
            end
        end
    end
    if changed then
        for furnitureId, oldAndNew in pairs(changed) do
            local newValue = oldAndNew[2]
            if not newValue.ProcessInfo or (newValue.ProcessInfo.LeftNum <= 0 ) then
                self:StopFurnitureWorkSound(furnitureId)
            else
                if not self.furnitureSoundMaps[furnitureId] then
                    self:PlayFurnitureWorkSound(furnitureId, newValue)
                end
            end
        end
    end
end

return CitySoundManager