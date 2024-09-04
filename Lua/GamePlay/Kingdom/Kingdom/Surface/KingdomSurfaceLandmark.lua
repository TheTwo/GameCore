local KingdomSurface = require("KingdomSurface")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local KingdomEntityDataWrapperFactory = require("KingdomEntityDataWrapperFactory")
local ModuleRefer = require("ModuleRefer")
local KingdomRefreshData = require("KingdomRefreshData")
local EventConst = require("EventConst")
local ObjectType = require("ObjectType")
local KingdomDelayInvoker = require("KingdomDelayInvoker")
local MapConfigCache = require("MapConfigCache")

local MapUtils = CS.Grid.MapUtils


---@class KingdomSurfaceLandmark : KingdomSurface
---@field settings CS.Kingdom.MapHUDSettings
---@field refreshData KingdomRefreshData
---@field mapBriefs table<number, wds.MapEntityBrief>
---@field mapBriefsInSight table<number, boolean>
---@field lastBriefs table<number, boolean>
---@field currentBriefs table<number, boolean>
---@field lastPrefabNames table<number, string>
---@field dataRemoveLod number
---@field delayInvoker KingdomDelayInvoker
---@field cameraGridMinX number
---@field cameraGridMinZ number
---@field cameraGridMaxX number
---@field cameraGridMaxZ number
---@field lastSize number
---@field lastLod number
---@field dataChanged boolean
local KingdomSurfaceLandmark = class("KingdomSurfaceLandmark", KingdomSurface)

function KingdomSurfaceLandmark:ctor()
    self.factory = KingdomEntityDataWrapperFactory.new()
    self.refreshData = KingdomRefreshData.new()
    self.mapBriefs = {}
    self.mapBriefsInSight = {}
    self.lastBriefs = {}
    self.currentBriefs = {}
    self.lastPrefabNames = {}
    self.delayInvoker = KingdomDelayInvoker.new(self.refreshData)
end

function KingdomSurfaceLandmark:Initialize(mapSystem, hudManager)
    KingdomSurface.Initialize(self, mapSystem, hudManager)

    self.refreshData:Initialize(hudManager, self.staticMapData)

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
    
    g_Game.EventManager:AddListener(EventConst.ON_UNLOCK_WORLD_FOG, Delegate.GetOrCreate(self, self.OnFogUnlocked))
end

function KingdomSurfaceLandmark:Dispose()
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnEntityRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnEntityChanged))
    
    g_Game.EventManager:RemoveListener(EventConst.ON_UNLOCK_WORLD_FOG, Delegate.GetOrCreate(self, self.OnFogUnlocked))

    self.refreshData:Dispose()
    self.settings = nil
end

function KingdomSurfaceLandmark:ClearUnits()
    self:Leave()
end

function KingdomSurfaceLandmark:Tick()
    self:Cull()
    
    if self.refreshData:IsDataRefreshed() then
        self.refreshData:UpdateData()
        self.refreshData:ClearRefreshes()
    end

    if self.refreshData:IsMaterialChanged() then
        self.refreshData:UpdateMaterials()
        self.refreshData:ClearMaterial()
    end

    if self.refreshData:IsDataRemoved() then
        self.refreshData:Remove()
        self.refreshData:ClearRemoves()
    end

    self.refreshData:Refresh()
    self.dataChanged = false
end

function KingdomSurfaceLandmark:Cull()
    if not KingdomMapUtils.InMapKingdomLod() or not self.mapSystem or not self.settings then
        return
    end

    local lod = self.mapSystem.Lod
    local lodChanged = lod ~= self.lastLod
    local oldLod = self.lastLod
    local newLod = lod
    self.lastLod = lod

    local cameraBox = self.mapSystem.CameraBox
    local cMinX, cMinY, cMaxX, cMaxY = MapUtils.CalculateWorldMinMaxXYPositionToCoord(cameraBox, self.staticMapData)
    local minX, minZ, maxX, maxZ = MapConfigCache.CalculateLandmarkRange(cMinX, cMinY, cMaxX, cMaxY, lod)
    local viewChanged = minX ~= self.cameraGridMinX or
            minZ ~= self.cameraGridMinZ or
            maxX ~= self.cameraGridMaxX or
            maxZ ~= self.cameraGridMaxZ
    self.cameraGridMinX = minX
    self.cameraGridMinZ = minZ
    self.cameraGridMaxX = maxX
    self.cameraGridMaxZ = maxZ

    if not viewChanged and not lodChanged and not self.dataChanged then
        return
    end

    local size = self.mapSystem.CameraSize
    local oldSize = self.lastSize
    local newSize = size
    self.lastSize = size

    if lodChanged or oldSize and math.abs(newSize - oldSize) > self.settings.LodCameraSizeChangeThreshold then
        if not self.delayInvoker:IsEmpty() then
            self.delayInvoker:InvokeAll()
        end
    end

    table.clear(self.currentBriefs)
    MapConfigCache.CollectLandmarks(self.cameraGridMinX, self.cameraGridMinZ, self.cameraGridMaxX, self.cameraGridMaxZ, lod, self.currentBriefs)

    if lodChanged then
        ModuleRefer.MapHUDModule:InitializeMaterialStates()
    end

    for vid, _ in pairs(self.lastBriefs) do
        if not self.currentBriefs[vid] then
            local brief = self.mapBriefs[vid]
            if brief then
                self:HideLandmark(brief, lodChanged, oldLod)
            end
        end
    end

    for vid, _ in pairs(self.currentBriefs) do
        local brief = self.mapBriefs[vid]
        if brief then
            if not self.lastBriefs[vid] then
                self:ShowLandmark(brief, lodChanged, newLod)
            elseif lodChanged then
                self:LodChangeLandmark(brief, oldLod, newLod)
            end
        else
            self.currentBriefs[vid] = nil
        end
    end

    self.currentBriefs, self.lastBriefs = self.lastBriefs, self.currentBriefs

    if lodChanged then
        if not self.delayInvoker:IsEmpty() then
            local fadeDuration = ModuleRefer.MapHUDModule:GetFadeDuration()
            self.delayInvoker:Start(fadeDuration)
        end
    end
end

function KingdomSurfaceLandmark:OnEnterHighLod()
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapHUDSettings))
    self.refreshData:InitMaterials()
    self:ResetCameraRange()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function KingdomSurfaceLandmark:OnLeaveHighLod()
    self:Leave()
end

function KingdomSurfaceLandmark:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceLandmark:Leave()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    if not self.delayInvoker:IsEmpty() then
        self.delayInvoker:InvokeAll()
    end
    self.refreshData:UpdateData()
    self.refreshData:UpdateMaterials()
    self.refreshData:Refresh()

    self.refreshData:ClearRemoves()
    self.refreshData:ClearRefreshes()
    self.refreshData:ClearMaterial()
    self.refreshData:UpdateData()
    self.refreshData:UpdateMaterials()
    self.refreshData:Refresh()

    table.clear(self.lastPrefabNames)
    table.clear(self.mapBriefs)
    table.clear(self.mapBriefsInSight)
    table.clear(self.lastBriefs)
    table.clear(self.currentBriefs)
end

function KingdomSurfaceLandmark:ResetCameraRange()
    self.cameraGridMinX = 0
    self.cameraGridMinZ = 0
    self.cameraGridMaxX = 0
    self.cameraGridMaxZ = 0
    self.lastLod = 0
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceLandmark:OnEntityAdded(typeId, entity)
    local lod = KingdomMapUtils.GetLOD()
    if not KingdomMapUtils.InMapKingdomLod(lod) then
        return
    end

    self:Refresh(entity.Infos.Briefs)
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceLandmark:OnEntityRemoved(typeId, entity)
    --local lod = KingdomMapUtils.GetLOD()
    --if not KingdomMapUtils.InMapKingdomLod(lod) then
    --    return
    --end
    --
    --self.mapBriefs[entity.ID] = nil
    --
    --for id, _ in pairs(entity.Infos.Briefs) do
    --    self.refreshData.removes:Add(id)
    --end
    --self.dataRemoveLod = entity.BasicInfo.Lod
    --self.dataRemoved = true
end

---@param entity wds.MapEntityInfos
function KingdomSurfaceLandmark:OnEntityChanged(entity)
    local lod = KingdomMapUtils.GetLOD()
    if not KingdomMapUtils.InMapKingdomLod(lod) then
        return
    end

    self:OnEntityRemoved(entity.TypeHash, entity)
    self:OnEntityAdded(entity.TypeHash, entity)
end

---@param brief wds.MapEntityBrief
function KingdomSurfaceLandmark.FilterBrief(brief)
    if KingdomMapUtils.CheckHideByFixedConfig(brief.CfgId) then
        return false
    end
    if brief
        and brief.ObjectType == ObjectType.SlgVillage
        and brief.IsAllianceCenter
        and ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId) then
        return false
    end
    return true
end

---@param briefs table<number, wds.MapEntityBrief>
function KingdomSurfaceLandmark:Refresh(briefs)
    ---@param brief wds.MapEntityBrief
    for _, brief in pairs(briefs) do
        if not KingdomSurfaceLandmark.FilterBrief(brief) then
            goto continue
        end

        --for test
        --if brief.ObjectId ~= 10247037030441 then
        --    goto continue
        --end

        self.mapBriefs[brief.VID] = brief
        
        ::continue::
    end
    self.dataChanged = true
end

---@param brief wds.MapEntityBrief
function KingdomSurfaceLandmark:ShowLandmark(brief, lodChanged, lod)
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
    if wrapper then
        local id = brief.ObjectId
        local vid = brief.VID
        local prefabName = wrapper:GetLodPrefab(brief, lod)
        local position = wrapper:GetCenterPosition(brief)
        self.refreshData:CreateHUD(id, prefabName, position, lod)
        wrapper:FeedData(self.refreshData, brief)
        wrapper:OnShow(self.refreshData, self.delayInvoker, lod, brief)
        self.mapBriefsInSight[vid] = true
    end
end

---@param brief wds.MapEntityBrief
function KingdomSurfaceLandmark:HideLandmark(brief, lodChanged, lod)
    local vid = brief.VID
    if lodChanged then
        local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
        if wrapper then
            wrapper:OnHide(self.refreshData, self.delayInvoker, lod, brief)
        end
    else
        self.refreshData:RemoveHUD(brief.ObjectId)
    end
    self.mapBriefsInSight[vid] = nil
end

function KingdomSurfaceLandmark:LodChangeLandmark(brief, oldLod, newLod)
    local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
    if wrapper then
        wrapper:OnLodChanged(self.refreshData, self.delayInvoker, oldLod, newLod, brief)
    end
end


function KingdomSurfaceLandmark:OnFogUnlocked()
    local lod = KingdomMapUtils.GetLOD()
    self:Refresh(self.mapBriefs, lod)
end

function KingdomSurfaceLandmark:OnIconClick(id)
    for vid, _ in pairs(self.mapBriefsInSight) do
        local brief = self.mapBriefs[vid]
        if brief.ObjectId == id then
            local wrapper = KingdomEntityDataWrapperFactory.GetDataWrapper(brief.ObjectType)
            if wrapper then
                wrapper:OnIconClick(brief)
                g_Game.EventManager:TriggerEvent(EventConst.MAP_CLICK_ICON_HIGH, brief)
                return true
            end
        end
    end
end


return KingdomSurfaceLandmark
