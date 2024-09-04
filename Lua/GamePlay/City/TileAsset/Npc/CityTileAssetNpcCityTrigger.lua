local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local DBEntityPath = require("DBEntityPath")
local NpcServiceObjectType = require("NpcServiceObjectType")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcCityTrigger:CityTileAsset
---@field new fun():CityTileAssetNpcCityTrigger
---@field super CityTileAsset
local CityTileAssetNpcCityTrigger = class('CityTileAssetNpcCityTrigger', CityTileAsset)

function CityTileAssetNpcCityTrigger:ctor()
    CityTileAsset.ctor(self)
    self._prefab = string.Empty
    self._useIsHumanTrigger = false
end

function CityTileAssetNpcCityTrigger:OnTileViewInit()
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcDataChanged))
end

function CityTileAssetNpcCityTrigger:OnTileViewRelease()
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcDataChanged))
end

function CityTileAssetNpcCityTrigger:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetNpcCityTrigger:GetPrefabName()
    if self:ShouldShow() then
        return self._prefab
    end
    return string.Empty
end

function CityTileAssetNpcCityTrigger:ShouldShow()
    local city = self:GetCity()
    if city:IsMyCity() then
        local x,y = self.tileView.tile.x,self.tileView.tile.y
        if city:IsFogMask(x, y) then
            return false
        end
        local elementId = self.tileView.tile:GetCell().configId
        local eleCfg = ConfigRefer.CityElementData:Find(elementId)
        if not eleCfg then
            return false
        end
        local npcCfg = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
        if not npcCfg or npcCfg:NoInteractable() then
            return false
        end
        if city:IsInSingleSeExplorerMode() and npcCfg:NoInteractableInSEExplore() then
            return false
        end
        local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[elementId]
        if not npcData then
            return false
        end
        if npcCfg:FinalNoInteractable() and ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData, true) then
            return false
        end
        local explorerMgr = city.cityExplorerManager
        if not explorerMgr then
            return false
        end
        if explorerMgr:IsInSingleSeExplorerZone(x, y) then
            if not city:IsInSingleSeExplorerMode() then
                return false
            end
        end
        if npcCfg:IsHuman() then
            self._prefab = ArtResourceUtils.GetItem(ArtResourceConsts.city_npc_capsule_city_trigger)
            self._useIsHumanTrigger = true
        else
            self._prefab = ArtResourceUtils.GetItem(ArtResourceConsts.city_npc_box_city_trigger)
            self._useIsHumanTrigger = false
        end
        return true
    end
    return false
end

---@param go CS.UnityEngine.GameObject
---@param userdata any
function CityTileAssetNpcCityTrigger:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local city = self:GetCity()
    local cell = self.tileView.tile:GetCell()
    go.transform.position = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
    local npcCfg = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
    local artResource = ConfigRefer.ArtResource:Find(npcCfg:Model())
    if npcCfg:IsHuman() then
        ---@type CS.UnityEngine.CapsuleCollider
        local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.CapsuleCollider))
        if Utils.IsNotNull(collider) then
            collider.height = artResource:CapsuleHeight()
            collider.radius = artResource:CapsuleRadius()
            local center = collider.center
            center.y = artResource:CapsuleYOffset()
            collider.center = center
        end
    else
        ---@type CS.UnityEngine.BoxCollider
        local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.BoxCollider))
        if Utils.IsNotNull(collider) then
            local colliderSize = collider.size
            colliderSize.y = artResource:CapsuleHeight()
            colliderSize.x = city.gridConfig.unitsPerCellX * cell.sizeX
            colliderSize.z = city.gridConfig.unitsPerCellY * cell.sizeY
            collider.size = colliderSize
            local center = collider.center
            center.y = artResource:CapsuleYOffset()
            collider.center = center
        end
    end
    ---@type CityTrigger
    local cityTrigger = go.transform:GetLuaBehaviourInChildren("CityTrigger").Instance
    if cityTrigger then
        cityTrigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCityTrigger), self.tileView.tile, false)
    end
end

function CityTileAssetNpcCityTrigger:OnClickCityTrigger(_)
    local city = self:GetCity()
    local cell = self.tileView.tile:GetCell()
    local elementId = cell:UniqueId()
    local isOpenDoorNpc, _ = city.zoneManager:IsSingleExplorerOpenNpcLink(elementId)
    if isOpenDoorNpc then
        return true
    end
    local eleConfig = ConfigRefer.CityElementData:Find(cell.configId)
    local elePos = eleConfig:Pos()
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig)--CityTileAsset.SuggestCellCenterPositionWithHeight(city, cell, 0, true)

    ---@type ClickNpcEventContext
    local context = {}
    context.cityUid = city.uid
    context.elementConfigID = cell.configId
    context.targetPos = pos
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
    return true
end

---@param entity wds.Player
---@param changedData table
function CityTileAssetNpcCityTrigger:OnNpcDataChanged(entity, changedData)
    if not entity or not entity.SceneInfo or not changedData then
        return
    end
    if not self.tileView or not self.tileView.tile then
        return
    end
    local city = self:GetCity()
    if not city or not city:IsMyCity() then
        return
    end
    if entity.SceneInfo.CastleBriefId ~= city.uid then
        return
    end
    local npcId = self.tileView.tile:GetCell().configId
    local changed = changedData[npcId]
    if not changed then
        return
    end
    local eleCfg = ConfigRefer.CityElementData:Find(npcId)
    if not eleCfg then
        return
    end
    local npcCfg = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
    if not npcCfg then
        return
    end
    if npcCfg:FinalNoInteractable() then
        self:Refresh()
    end
end

return CityTileAssetNpcCityTrigger

