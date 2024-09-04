local NpcServiceObjectType = require("NpcServiceObjectType")

local CityTileAssetPolluted = require("CityTileAssetPolluted")
---@class CityTileAssetNpc:CityTileAssetPolluted
---@field new fun():CityTileAssetNpc
---@field super CityTileAssetPolluted
local CityTileAssetNpc = class("CityTileAssetNpc", CityTileAssetPolluted)
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local DBEntityPath = require("DBEntityPath")
---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")

function CityTileAssetNpc:ctor()
    CityTileAssetPolluted.ctor(self)
    self.allowSelected = true
    ---@type CityTrigger
    self.cityTrigger = nil
    self.markAsNoInteractable = false
    self._idleAni = string.Empty
    self._attatchVfxMatName = nil
    ---@type CS.UnityEngine.Material
    self._extraLoadedMat = nil
    ---@type CS.UnityEngine.Renderer[]
    self._loadedRenders = nil
    ---@type CityTileAssetSafeAreaDoorComp
    self._npcAsDoorComp = nil
    self._cityUid = nil
    self._regDoorTempId = nil
    self._rangeEventRegId = nil
end

function CityTileAssetNpc:OnTileViewInit()
    CityTileAssetNpc.super.OnTileViewInit(self)
    self._cityUid = self:GetCity().uid
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, Delegate.GetOrCreate(self, self.OnPlayInteractAudio))
    if self:IsOpenDoorNpc() then
        local cell = self.tileView.tile:GetCell()
        self._regDoorTempId = self:GetCity().safeAreaWallMgr:RegisterDummyDoorGridEvent(cell.x, cell.y, cell.sizeX, cell.sizeY)
    end
    local exploreMgr = self:GetCity().cityExplorerManager
    local elementId = self.tileView.tile:GetCell():UniqueId()
    local needReg, worldPos, radius = exploreMgr:NpcNeedRegRangeEventAndParam(elementId)
    if needReg then
        self._rangeEventRegId = elementId
        exploreMgr:RegNpcRangeEvent(elementId, worldPos, radius)
    end
end

function CityTileAssetNpc:OnTileViewRelease()
    if self._rangeEventRegId then
        self:GetCity().cityExplorerManager:UnRegNpcRangeEvent(self._rangeEventRegId)
    end
    self._rangeEventRegId = nil
    CityTileAssetNpc.super.OnTileViewRelease(self)
    if self._regDoorTempId then
        self:GetCity().safeAreaWallMgr:UnregisterDummyDoorGridEvent(self._regDoorTempId)
    end
    self._cityUid = nil
    self._regDoorTempId = nil
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, Delegate.GetOrCreate(self, self.OnPlayInteractAudio))
end

---@param entity wds.Player
---@param changedData table
function CityTileAssetNpc:OnNpcDataChanged(entity, changedData)
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
    local npcId = self.tileView.tile:GetCell().tileId
    local changed = changedData[npcId]
    if not changed then
        return
    end
    local prefabName = self:GetPrefabName()
    if prefabName ~= self.prefabName then
        self:Hide()
        self:Show()
    end
end

function CityTileAssetNpc:GetPrefabName()
    self._idleAni = string.Empty
    if self:SkipForSLGAsset() then
        return string.Empty
    end

    local cell = self.tileView.tile:GetCell()
    if cell == nil then
        g_Logger.Error("fatal error")
        return string.Empty
    end

    local element = ConfigRefer.CityElementData:Find(cell.configId)
    if element == nil then
        g_Logger.Error(("Can't find config row id : %d in CityElementData"):format(cell.configId))
        return string.Empty
    end

    local npcCell = ConfigRefer.CityElementNpc:Find(element:ElementId())
    if npcCell == nil then
        g_Logger.Error(("Can't find config row id : %d in CityTileAssetNpc"):format(element:ElementId()))
        return string.Empty
    end
    self._idleAni = npcCell:ModelAni()
    if npcCell:NoInteractable() then
        self.markAsNoInteractable = true
    end

    local city = self:GetCity()
    if city:IsMyCity() then
        local finalModel = ArtResourceUtils.GetItem(npcCell:FinalModel())
        if not string.IsNullOrEmpty(finalModel) then
            local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[cell.configId]
            if ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData) then
                if npcCell:FinalNoInteractable() then
                    self.markAsNoInteractable = true
                end
                return finalModel
            end
        end
    end

    local mdlId = npcCell:Model()
    return ArtResourceUtils.GetItem(mdlId)
end

function CityTileAssetNpc:SkipForSLGAsset()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        local element = self:GetCity().elementManager:GetElementById(cell.configId)
        return element ~= nil and element.battleState
    end
    return false
end

function CityTileAssetNpc:GetScale()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then
        g_Logger.Error("fatal error")
        return 1
    end

    local element = ConfigRefer.CityElementData:Find(cell.configId)
    if element == nil then
        g_Logger.Error(("Can't find config row id : %d in CityElementData"):format(cell.configId))
        return 1
    end

    local npcCell = ConfigRefer.CityElementNpc:Find(element:ElementId())
    if npcCell == nil then
        g_Logger.Error(("Can't find config row id : %d in CityTileAssetNpc"):format(element:ElementId()))
        return 1
    end
    local city = self:GetCity()
    if city:IsMyCity() then
        local finalModel,scale = ArtResourceUtils.GetItemAndScale(npcCell:FinalModel())
        if not string.IsNullOrEmpty(finalModel) then
            local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[cell.configId]
            if ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData) then
                return scale
            end
        end
    end
    local _,scale = ArtResourceUtils.GetItemAndScale(npcCell:Model())
    return scale or 1
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetNpc:OnAssetLoaded(go, userdata)
    CityTileAssetPolluted.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    self._loadedRenders = go:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer), true)
    self:SetupAttachRenderMat()
    local cell = self.tileView.tile:GetCell()
    local cfg = ConfigRefer.CityElementNpc:Find(ConfigRefer.CityElementData:Find(cell.configId):ElementId())
    if cfg:IsHuman() then
        local city = self:GetCity()
        local cellCenterPos = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
        local dir = cfg:Dir()
        local rotation = Quaternion.Euler(CS.UnityEngine.Vector3(dir:X(), dir:Y(), dir:Z()))
        go.transform:SetPositionAndRotation(cellCenterPos, rotation)
    end

    if not cfg:NoInteractable() then
        ---@type CS.UnityEngine.Collider
        local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
        if Utils.IsNotNull(collider) then
            collider.enabled = not self.markAsNoInteractable
            local trigger = go:AddMissingLuaBehaviour("CityTrigger")
            trigger.Instance:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCellTile), self.tileView.tile, false)
            self.cityTrigger = trigger.Instance
            self.tileView:WriteBlackboard(self.tileView.Key.MainAssetBounds, collider.bounds, true)
        end
    else
        ---@type CS.UnityEngine.Collider
        local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
        if Utils.IsNotNull(collider) then
            collider.enabled = false
        end
    end
    if not string.IsNullOrEmpty(self._idleAni) then
        ---@type CS.UnityEngine.Animator
        local animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator), true)
        if Utils.IsNotNull(animator) then
            animator:CrossFade(self._idleAni, 0.25)
        end
    end
    if self._regDoorTempId then
        local be = go:AddMissingLuaBehaviour("CityTileAssetSafeAreaDoorComp")
        if Utils.IsNotNull(be) then
            self._npcAsDoorComp = be.Instance
            if self._npcAsDoorComp then
                local mgr = self:GetCity().safeAreaWallMgr
                local openStatus = mgr:GetDoorOpenStatus(self._regDoorTempId)
                self._npcAsDoorComp:SetOpenStatus(openStatus)
            end
        end
    end
end

function CityTileAssetNpc:OnClickCellTile()
    if self.markAsNoInteractable then
        return false
    end
    return CityTileAssetPolluted.OnClickCellTile(self)
end

function CityTileAssetNpc:OnAssetUnload()
    self._npcAsDoorComp = nil
    self:ClearUpOldAttachMaterial()
    self._loadedRenders = nil
    if self.cityTrigger then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.cityTrigger = nil
    end
    CityTileAssetPolluted.OnAssetUnload(self)
end

function CityTileAssetNpc:IsMine(id)
    local cell = self.tileView.tile:GetCell()
    return cell.tileId == id
end

function CityTileAssetNpc:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end
    return self:GetCity().elementManager:IsPolluted(cell.tileId)
end

function CityTileAssetNpc:OnSlgAssetUpdate(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeElement then return end
    
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil and cell.tileId == id then
        self:ForceRefresh()
    end
end

function CityTileAssetNpc:ClearUpOldAttachMaterial()
    local lastMat = self._extraLoadedMat
    if lastMat and self._loadedRenders then
        for renderIdx = 0, self._loadedRenders.Length - 1 do
            local renderer = self._loadedRenders[renderIdx]
            if Utils.IsNotNull(renderer) then
                local materials = renderer.sharedMaterials
                if materials then
                    for i = materials.Length - 1, 0, -1 do
                        if materials[i] == lastMat then
                            renderer:ReduceMaterial(i)
                        end
                    end
                end
            end
        end
    end
    if Utils.IsNotNull(self._extraLoadedMat) then
        CS.UnityEngine.Object.Destroy(self._extraLoadedMat)
    end
    if not string.IsNullOrEmpty(self._attatchVfxMatName) then
        g_Game.MaterialManager.manager:UnloadMaterial(self._attatchVfxMatName)
    end
    self._extraLoadedMat = nil
    self._attatchVfxMatName = string.Empty
end

function CityTileAssetNpc:SetupAttachRenderMat()
    if not self._extraLoadedMat then return end
    if not self._loadedRenders then return end
    for renderIdx = 0, self._loadedRenders.Length - 1 do
        local renderer = self._loadedRenders[renderIdx]
        local materials = renderer.materials
        local newMaterials = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Material), materials.Length + 1)
        newMaterials[materials.Length] = self._extraLoadedMat
        for i = 0, materials.Length - 1 do
            newMaterials[i] = materials[i]
        end
        renderer.materials = newMaterials
    end
end

---@return CS.UnityEngine.Material
function CityTileAssetNpc:AttachRenderMat(materialName)
    if self._attatchVfxMatName == materialName then return end
    self:ClearUpOldAttachMaterial()
    self._attatchVfxMatName = materialName
    local baseMat = g_Game.MaterialManager.manager:LoadMaterial(materialName)
    if Utils.IsNotNull(baseMat) then
        self._extraLoadedMat = CS.UnityEngine.Object.Instantiate(baseMat)
    end
    self:SetupAttachRenderMat()
    return self._extraLoadedMat
end

function CityTileAssetNpc:OnDoorOpenStatusChanged(cityUid, doorId, status)
    if not self._npcAsDoorComp then return end
    if not self._cityUid or self._cityUid ~= cityUid then
        return
    end
    if not self._regDoorTempId or self._regDoorTempId ~= doorId then
        return
    end
    if not self._npcAsDoorComp then return end
    self._npcAsDoorComp:SetOpenStatus(status)
end

function CityTileAssetNpc:OnPlayInteractAudio(cityUid, elementId)
    if not self._cityUid or self._cityUid ~= cityUid then
        return
    end
    local cell = self.tileView.tile:GetCell()
    if cell:UniqueId() ~= elementId then return end
    local element = ConfigRefer.CityElementData:Find(cell.configId)
    if not element then return end
    local npcConfig = ConfigRefer.CityElementNpc:Find(element:ElementId())
    if not npcConfig then return end
    local audio = npcConfig:InteractAudio()
    if audio == 0 then return end
    self:PlayAudioOnGo(audio)
end

function CityTileAssetNpc:IsOpenDoorNpc()
    local elementId = self.tileView.tile:GetCell():UniqueId()
    local zoneId = self:GetCity().zoneManager:GetOpenNpcLinkZoneId(elementId)
    return zoneId and zoneId ~= 0
end

function CityTileAssetNpc:PlayAudioOnGo(audioId)
    if Utils.IsNull(self.go) then return false end
    g_Game.SoundManager:PlayAudio(audioId, self.go)
    return true
end

return CityTileAssetNpc