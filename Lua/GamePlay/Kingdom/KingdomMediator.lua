local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require('ModuleRefer')
local TileHighLightMap = require('TileHighLightMap')
local KingdomMapUtils = require('KingdomMapUtils')
local WaitUnitOperation = require('WaitUnitOperation')
local KingdomTouchInfoFactory = require('KingdomTouchInfoFactory')
local CameraConst = require('CameraConst')
local KingdomCameraSizeRule = require("KingdomCameraSizeRule")
local ArtResourceConsts = require('ArtResourceConsts')
local ArtResourceUtils = require('ArtResourceUtils')
local ShadowDistanceControl = require("ShadowDistanceControl")
local MapHudTransformControl = require("MapHudTransformControl")
local Utils = require("Utils")
local I18N = require("I18N")
local KingdomInteractionDefine = require("KingdomInteractionDefine")
local MapAssetNames = require("MapAssetNames")

local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper

---@class KingdomSelection
---@field X number
---@field Y number

---@class KingdomMediator
---@field staticMapData CS.Grid.StaticMapData
---@field basicCamera BasicCamera
---@field currentTile MapRetrieveResult
---@field currentSelection KingdomSelection
---@field cameraSizeRule KingdomCameraSizeRule
---@field helper CS.DragonReborn.AssetTool.GameObjectCreateHelper
---@field settingsObject CS.UnityEngine.GameObject
---@field settingsCache table
---@field waitUnitOperation WaitUnitOperation
local KingdomMediator = class("KingdomMediator")

function KingdomMediator:ctor()
    self.currentTile = nil
    self.currentSelection = { X = 0, Y = 0 }
    self.settingsCache = {}
    self.cameraSizeRule = KingdomCameraSizeRule.new()
    self.helper = GameObjectCreateHelper.Create()
    self.waitUnitOperation = WaitUnitOperation.new()
end

function KingdomMediator:Initialize()
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    
    self.cameraSizeRule:Initialize()
    self.cameraSizeRule:SetBlock(true)

    local p = KingdomInteractionDefine.InteractionPriority.KingdomMediator
    ModuleRefer.KingdomInteractionModule:AddOnPressDown(Delegate.GetOrCreate(self, self.OnKingdomPressDown), p)
    ModuleRefer.KingdomInteractionModule:AddOnClick(Delegate.GetOrCreate(self, self.OnKingdomClick), p)
    ModuleRefer.KingdomInteractionModule:AddOnRelease(Delegate.GetOrCreate(self, self.OnKingdomDragRelease), p)
    ModuleRefer.KingdomInteractionModule:AddOnLongTapStart(Delegate.GetOrCreate(self, self.OnKingdomLongTapStart), p)
    ModuleRefer.KingdomInteractionModule:AddOnLongTapEnd(Delegate.GetOrCreate(self, self.OnKingdomLongTapEnd), p)
    ModuleRefer.KingdomInteractionModule:AddOnDragStart(Delegate.GetOrCreate(self, self.OnKingdomDragStart), p)

    g_Game.EventManager:AddListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.EventManager:AddListener(EventConst.WAIT_AND_SHOW_UNIT, Delegate.GetOrCreate(self, self.WaitAndShowUnitTile))
    g_Game.EventManager:AddListener(EventConst.WAIT_SHOW_UNIT_CALLBACK, Delegate.GetOrCreate(self, self.WaitAndShowUnitTileCallback))
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:AddListener(EventConst.MAP_SET_SELECTION, Delegate.GetOrCreate(self, self.OnSetSelection))
    g_Game.EventManager:AddListener(EventConst.MAP_RESET_SELECTION, Delegate.GetOrCreate(self, self.OnResetSelection))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    local cameraSize = self.basicCamera:GetSize()
    ShadowDistanceControl.ChangeShadowCascades(CameraConst.MapShadowCascades)
    local sizeList = KingdomMapUtils.GetCameraLodData().mapCameraSizeList
    local shadowDistanceList = KingdomMapUtils.GetCameraLodData().mapShadowDistanceList
    ShadowDistanceControl.SetEnable(true)
    ShadowDistanceControl.RefreshShadow(self.basicCamera.mainCamera, cameraSize, sizeList, shadowDistanceList, CameraConst.MapShadowCascadeSizeThreshold)
end

function KingdomMediator:Release()
    ModuleRefer.KingdomInteractionModule:RemoveOnPressDown(Delegate.GetOrCreate(self, self.OnKingdomPressDown))
    ModuleRefer.KingdomInteractionModule:RemoveOnClick(Delegate.GetOrCreate(self, self.OnKingdomClick))
    ModuleRefer.KingdomInteractionModule:RemoveOnRelease(Delegate.GetOrCreate(self, self.OnKingdomDragRelease))
    ModuleRefer.KingdomInteractionModule:RemoveOnLongTapStart(Delegate.GetOrCreate(self, self.OnKingdomLongTapStart))
    ModuleRefer.KingdomInteractionModule:RemoveOnLongTapEnd(Delegate.GetOrCreate(self, self.OnKingdomLongTapEnd))
    ModuleRefer.KingdomInteractionModule:RemoveOnDragStart(Delegate.GetOrCreate(self, self.OnKingdomDragStart))

    g_Game.EventManager:RemoveListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.WAIT_AND_SHOW_UNIT, Delegate.GetOrCreate(self, self.WaitAndShowUnitTile))
    g_Game.EventManager:RemoveListener(EventConst.WAIT_SHOW_UNIT_CALLBACK, Delegate.GetOrCreate(self, self.WaitAndShowUnitTileCallback))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.MAP_SET_SELECTION, Delegate.GetOrCreate(self, self.OnSetSelection))
    g_Game.EventManager:RemoveListener(EventConst.MAP_RESET_SELECTION, Delegate.GetOrCreate(self, self.OnResetSelection))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    self:HideSelect(self.currentTile)
    self.cameraSizeRule:Release()

    self:RemoveLongTapEffect()
    self.longTapEffect = nil

    self.waitUnitOperation:Reset()
end

-- ---@param cpuLevel CS.DragonReborn.Performance.PerformanceLevelData
-- ---@param gpuLevel CS.DragonReborn.Performance.PerformanceLevelData
-- function KingdomMediator:OnPerformanceLevelChange(cpuLevel, gpuLevel)

-- end

function KingdomMediator:OnCameraSizeChanged(oldSize, newSize)
    local sizeList = KingdomMapUtils.GetCameraLodData().mapCameraSizeList
    local shadowDistanceList = KingdomMapUtils.GetCameraLodData().mapShadowDistanceList
    ShadowDistanceControl.RefreshShadow(self.basicCamera.mainCamera, newSize, sizeList, shadowDistanceList, CameraConst.MapShadowCascadeSizeThreshold)
    
    local maxSize = KingdomMapUtils.GetBasicCamera().cameraDataPerspective.maxSize
    if oldSize < maxSize and newSize >= maxSize then
        if not ModuleRefer.MapPreloadModule:BaseMapAssetsDownloadFinished() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("System_toast_increase_the_field"))
        end
    end
end

function KingdomMediator:OnCameraLodChanged(oldLod, newLod)
    self:HideSelect(self.currentTile)
end

function KingdomMediator:OnSetSelection(x, z, isTile)
    if isTile then
        local tile = KingdomMapUtils.RetrieveMap(x, z)
        self:ShowTile(tile)
    end
    self:SetSelection(x, z)
end

function KingdomMediator:OnResetSelection()
    self:HideTile()
    self:ResetSelection()
end

function KingdomMediator:OnCityStateChanged(showed)
    local scene = g_Game.SceneManager.current
    if scene:IsInMyCity() then
        self:HideSelect(self.currentTile)
    end
end

function KingdomMediator:Tick(delta)
    if self.waitUnitOperation:IsValid() then
        self.waitUnitOperation:Tick(delta)
    end
end

---@param staticMapData CS.Grid.StaticMapData
function KingdomMediator:LoadEnvironmentSettings(staticMapData, callback)
    local settingsName = MapAssetNames.GetSettingsName(staticMapData.Prefix)
    self.helper:CreateAsap(settingsName, KingdomMapUtils.GetMapSystem().Parent, function(go)
        self.settingsObject = go
        ---@type CS.Kingdom.MapSettings
        local mapSettings = self.settingsObject:GetComponent(typeof(CS.Kingdom.MapSettings))
        mapSettings:Initialize(KingdomMapUtils.GetBasicCamera().mainCamera)
        if callback then 
            callback() 
        end
    end, math.maxinteger)
end

function KingdomMediator:UnloadEnvironmentSettings()
    self.helper:CancelAllCreate()
    if Utils.IsNotNull(self.settingsObject) then
        ---@type CS.Kingdom.MapSettings
        local mapSettings = self.settingsObject:GetComponent(typeof(CS.Kingdom.MapSettings))
        mapSettings:Dispose()
        GameObjectCreateHelper.DestroyGameObject(self.settingsObject)
        self.settingsObject = nil
    end
    table.clear(self.settingsCache)
end

function KingdomMediator:GetEnvironmentSettings(type)
    if Utils.IsNotNull(self.settingsObject) then
        if type then
            local settings = self.settingsCache[type]
            if not settings then
                settings = self.settingsObject:GetComponent(type)
                self.settingsCache[type] = settings
            end
            return settings
        end
        return self.settingsObject
    end
    return nil
end


--region Interaction Effect

---@return boolean
function KingdomMediator:OnKingdomDragRelease(trans, position)
    self:RemoveLongTapEffect()
    return false
end

---@param trans CS.UnityEngine.Transform[]
---@return boolean
function KingdomMediator:OnKingdomPressDown(trans, position)
    local coord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(position, self.staticMapData)
    if not self:BorderCheck(coord) then
        return true
    end
    if KingdomMapUtils.IsNewbieState() then
        return false
    end

    if ModuleRefer.RadarModule:IsInRadar() then
        return true
    end
    if trans and #trans > 0 then
        for _, tran in ipairs(trans) do
            if ModuleRefer.SlgModule:IsMyTroopView(tran) then
                return false
            end
        end
    end
    --mist
    if not ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
        return true
    end
    return false
end

---@param trans CS.UnityEngine.Transform
---@return boolean
function KingdomMediator:OnKingdomClick(trans, position)
    self:RemoveLongTapEffect()

    g_Game.EventManager:TriggerEvent(EventConst.UI_BUTTON_CLICK_PRE, nil)

    local coord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(position, self.staticMapData)
    if not self:BorderCheck(coord) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_mist_zanweikaifang"))
        return true
    end

    -- 圈层点击
    if ModuleRefer.LandformModule:IsLandSelectMode() then
        local clickedLandformCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(coord.X, coord.Y)
        g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, clickedLandformCfgId)
        return true
    end

    if ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y) then
        ModuleRefer.MapFogModule:ResetSelectedMists()
    end

    if UNITY_DEBUG then
        local mist = ModuleRefer.MapFogModule:GetMistAt(coord.X, coord.Y)
        local territory = ModuleRefer.TerritoryModule:GetTerritoryAt(coord.X, coord.Y)
        local height = KingdomMapUtils.SampleHeight(position.x, position.z)
        local landform = ModuleRefer.TerritoryModule:GetLandCfgIdAt(coord.X, coord.Y)
        g_Logger.LogChannel('DebugInfo',string.format("World Position:(%.2f, %.2f , %.2f), Grid Coordinate:(%d , %d), Mist ID: %d, Territory ID: %d, Landform ID:%d", 
                position.x, height, position.z, 
                coord.X, coord.Y, 
                mist, territory, landform))
    end

    --3D UI
    if trans  then
		-- 大世界抓宠/情报奖励筛选
		local intDataPet = ModuleRefer.PetModule:GetWorldPetIntData()
		local intDataWR = ModuleRefer.WorldRewardInteractorModule:GetIntData()
        for _, tran in ipairs(trans) do
            ---@type CS.CustomData
            local cdata = tran.gameObject:GetComponent(typeof(CS.CustomData))
            if (cdata) then
                -- 大世界抓宠
                if (cdata.intData == intDataPet) then
                    ModuleRefer.PetModule:TryOpenCatchMenu(cdata.objectData)
                    g_Game.EventManager:TriggerEvent(EventConst.MAP_CLICK_PET, cdata.objectData)
                    return true
                end
            end

            ---@type MapUITrigger
            local triggerBehavior = tran.gameObject:GetLuaBehaviour("MapUITrigger")
            if triggerBehavior and triggerBehavior.Instance then
                triggerBehavior.Instance:InvokeTrigger()
                return true
            end
        end
    end

    --世界事件task的bubble点击屏蔽后续
    if trans then
        for _, tran in ipairs(trans) do
			local triggerBehavior = tran.parent.gameObject:GetLuaBehaviour("PvETileAsseRadarBubbleBehavior")
            if triggerBehavior and triggerBehavior.Instance then
                return true
            end
            if ModuleRefer.SlgModule:IsMyTroopView(tran) then
                return false
            end
		end        
    end
    
    return self:ChooseCoordTile(coord)
end

---@param coord CS.DragonReborn.Vector2Short
function KingdomMediator:ChooseCoordTile(coord)
    local tileX = coord.X
    local tileZ = coord.Y
    --mist
    if KingdomMapUtils.IsNewbieState() then
        ModuleRefer.MapFogModule:ResetSelectedMists() --修复野怪Tips不消失的问题
    else
        if not ModuleRefer.MapFogModule:IsFogUnlocked(tileX, tileZ) then
            ModuleRefer.MapFogModule:SetSelectedMistAt(tileX, tileZ, true)
            self:SetSelection(tileX, tileZ)
            return true
        else
            ModuleRefer.MapFogModule:ResetSelectedMists()
        end
    end

    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    
    local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
    local scene = KingdomMapUtils.GetKingdomScene()
    local lod = scene:GetLod()
    if KingdomMapUtils.InMapHighLod(lod) and not ModuleRefer.RadarModule:IsInRadar() then
        if ModuleRefer.KingdomTouchInfoModule:IsShow() then
            ModuleRefer.KingdomTouchInfoModule:Hide()
            return false
        end
        if not KingdomMapUtils.IsEmpty(tile) then
            local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ)
            ModuleRefer.KingdomTouchInfoModule:Show(touchData)
            return true
        end
    end

    if self:HasSelection() then
        if KingdomMapUtils.IsEmpty(tile) then
            self:HideTile()
            self:ResetSelection()
        elseif self:DifferentSelection(tileX, tileZ) then
            self:ShowTile(tile)
            self:SetSelection(tile.X, tile.Z)
        end
    else
        self:ShowTile(tile)
        self:SetSelection(tile.X, tile.Z)
    end

end

---@return boolean
function KingdomMediator:OnKingdomLongTapStart(trans, position)
    if KingdomMapUtils.IsNewbieState() then
        return false
    end

    self:AddLongTapEffect(position)
    return false
end

---@return boolean
function KingdomMediator:OnKingdomLongTapEnd(trans, position)
    local scene = KingdomMapUtils.GetKingdomScene()
    if KingdomMapUtils.InMapKingdomLod(scene:GetLod()) or KingdomMapUtils.IsNewbieState() then
        return false
    end

    local coord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(position, self.staticMapData)
    local tile = KingdomMapUtils.RetrieveMap(coord.X, coord.Y)
    self:ShowTile(tile)
    self:SetSelection(tile.X, tile.Z)
    self:RemoveLongTapEffect()
    return false
end

function KingdomMediator:LookAt(x, y, duration)
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
    local camera = self.basicCamera
    camera:LookAt(pos, duration)
end

---@param trans CS.UnityEngine.Transform[]
---@param position CS.UnityEngine.Vector3
---@param screenPos CS.UnityEngine.Vector3
---@return boolean
function KingdomMediator:OnKingdomDragStart(trans, position, screenPos)
    self:RemoveLongTapEffect()
    return false
end

function KingdomMediator:AddLongTapEffect(position)
    local scene = KingdomMapUtils.GetKingdomScene()
    if scene:InCityLod() then
        return
    end

    if not self.longTapEffect then
        local createHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create();
        createHelper:Create(ArtResourceUtils.GetItem(ArtResourceConsts.effect_bigmap_positontips), scene.root.transform, function (go,data)
            self.longTapEffect = go
            self.longTapEffect:SetActive(true)
            self.longTapEffect.transform.position = position
        end)
    else
        self.longTapEffect:SetActive(true)
        self.longTapEffect.transform.position = position
    end
end

function KingdomMediator:RemoveLongTapEffect()
    if self.longTapEffect then
        self.longTapEffect:SetActive(false)
    end
end

---@return MapRetrieveResult
function KingdomMediator:GetCurrentTile()
    return self.currentTile
end

---@param tile MapRetrieveResult
---@param context any
function KingdomMediator:ShowTile(tile, context)
    if not KingdomMapUtils.IsMapState() or ModuleRefer.KingdomPlacingModule:IsPlacing() then
        return
    end

    if self.currentTile ~= nil then
        self:HideSelect(self.currentTile)
        self.currentTile = nil
    end

    self.currentTile = tile
    self:ShowSelect(tile, KingdomMapUtils.GetLOD(), context)
end

function KingdomMediator:HideTile()
    if not KingdomMapUtils.IsMapState() or ModuleRefer.KingdomPlacingModule:IsPlacing() then
        return
    end

    if self.currentTile ~= nil then
        local tile = self.currentTile
        self.currentTile = nil
        self:HideSelect(tile)
    end
end

function KingdomMediator:WaitAndShowUnitTile(tileX, tileZ, lod, context)
    self.waitUnitOperation:SetData(tileX, tileZ ,lod, function(tile) self:ShowTile(tile, context) end)
end

---@param callback fun(tile:MapRetrieveResult, context:any)
function KingdomMediator:WaitAndShowUnitTileCallback(tileX, tileZ, lod, callback, context)
    if not callback then return end
    self.waitUnitOperation:SetData(tileX, tileZ ,lod, function(tile) callback(tile, context) end)
end

---@param tile MapRetrieveResult
---@param lod number
---@param context any
function KingdomMediator:ShowSelect(tile, lod, context)
    KingdomTouchInfoFactory.CreateDataFromKingdom(tile, lod, context)
    TileHighLightMap.ShowTileHighlight(tile, context)
    g_Game.EventManager:TriggerEvent(EventConst.MAP_SELECT_BUILDING, tile.entity, context)
end

function KingdomMediator:HideSelect(tile)
    if not tile then
        return
    end

    self:ResetSelection()
    TileHighLightMap.HideTileHighlight(tile)
    ModuleRefer.KingdomTouchInfoModule:Hide()
    g_Game.EventManager:TriggerEvent(EventConst.MAP_UNSELECT_BUILDING, tile.entity)
end

function KingdomMediator:HasSelection()
    return self.currentSelection.X ~= 0 and self.currentSelection.Y ~= 0
end

function KingdomMediator:DifferentSelection(x, y)
    return self.currentSelection.X ~= x or self.currentSelection.Y ~= y
end

function KingdomMediator:SetSelection(x, y)
    self.currentSelection.X = x
    self.currentSelection.Y = y
end

function KingdomMediator:ResetSelection()
    self.currentSelection.X = 0
    self.currentSelection.Y = 0
end

--endregion

function KingdomMediator:OnTerrainLoaded(x, z, lod)
    g_Game.EventManager:TriggerEvent(EventConst.MAP_TERRAIN_LOADED, x, z)
end

function KingdomMediator:GetTerrainLoadedCallback()
    return Delegate.GetOrCreate(self, self.OnTerrainLoaded)
end

---@param coord CS.DragonReborn.Vector2Short
function KingdomMediator:BorderCheck(coord)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    return 0 <= coord.X and coord.X < staticMapData.TilesPerMapX and 0 <= coord.Y and coord.Y < staticMapData.TilesPerMapZ
end

return KingdomMediator
