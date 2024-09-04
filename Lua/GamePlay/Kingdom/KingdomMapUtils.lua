local ListInt32 = CS.System.Collections.Generic.List(typeof(CS.System.Int32))
local Screen = CS.UnityEngine.Device.Screen
local Vector3 = CS.UnityEngine.Vector3
local MapUtils = CS.Grid.MapUtils
local Range2Int = CS.DragonReborn.Range2Int
local CameraConst = require('CameraConst')
local Layers = require("Layers")
local MapConfigCache = require("MapConfigCache")

local DBEntityType = require('DBEntityType')
local CameraUtils = require('CameraUtils')
local MapRetrieveResult = require("MapRetrieveResult")
local ConfigRefer =  require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local KingdomConstant = require("KingdomConstant")
local Utils = require("Utils")
local LodMapping = require("LodMapping")
local SceneType = require("SceneType")

local MapTerrainMask = CS.UnityEngine.LayerMask.GetMask("MapTerrain")

---@class KingdomMapUtils
local KingdomMapUtils =
{
    decoListCache = ListInt32(),
}

function KingdomMapUtils.ClearCityPools()
    g_Game.GameObjectPoolManager:Clear("City")
    g_Game.GameObjectPoolManager:Clear("CityCitizenManager")
    g_Game.GameObjectPoolManager:Clear("CityExplorerManagers")
    g_Game.GameObjectPoolManager:Clear("CityRoomBuilding")
    g_Game.GameObjectPoolManager:Clear("CityUnitInfectionVfxPool")
    g_Game.GameObjectPoolManager:Clear("CityUnitPathLinePool")
    g_Game.GameObjectPoolManager:Clear("QualityLevelLoader")
end

function KingdomMapUtils.ClearKingdomPools()
    local PoolUsage = require("PoolUsage")
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem then
        mapSystem:ClearTileViewPool()
    end
    g_Game.GameObjectPoolManager:Clear(PoolUsage.Map)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.MapHexChunk)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.MapRoad)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.MapSymbolRoad)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.MapSymbolWater)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.MapTerritoryArea)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.Kingdom)
    g_Game.GameObjectPoolManager:Clear(PoolUsage.Troop)
    g_Game.GameObjectPoolManager:Clear("ObjectTile")
    g_Game.EntityPoolManager:Clear("TroopViewManager")
    g_Game.EntityPoolManager:Clear("EntityTile")
    g_Game.EntityPoolManager:Clear("SkillEffectPool")
end

---@return CS.Grid.MapSystem
function KingdomMapUtils.GetMapSystem()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end

    local mapSystem = scene.mapSystem
    return mapSystem
end

---@return CS.Grid.StaticMapData
function KingdomMapUtils.GetStaticMapData()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end

    local staticMapData = scene.staticMapData
    return staticMapData
end

---@return CS.Territory.TerritorySystem
function KingdomMapUtils.GetTerritorySystem()
    return ModuleRefer.TerritoryModule.territorySystem
end

---@return KingdomCustomHexChunkAccessModule
function KingdomMapUtils.GetCustomHexChunkAccess()
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end
    return scene.customHexChunkAccess
end

---@return BasicCamera
function KingdomMapUtils.GetBasicCamera()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end

    local basicCamera = scene.basicCamera
    return basicCamera
end

---@return MapMarkCamera
function KingdomMapUtils.GetMapMarkCamera()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end

    local mapMarkCamera = scene.mapMarkCamera
    return mapMarkCamera
end

---@return KingdomScene
function KingdomMapUtils.GetKingdomScene()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end
    return scene
end

---@return KingdomSceneState
function KingdomMapUtils.GetKingdomState()
    local scene = KingdomMapUtils.GetKingdomScene()
    if not scene or not scene.stateMachine then
        return nil
    end
    return scene.stateMachine:GetCurrentState()
end

function KingdomMapUtils.CheckMapID(id, baseID)
    return id - baseID < 100000
end

---@return CameraLodData
function KingdomMapUtils.GetCameraLodData()
    return KingdomMapUtils.GetKingdomScene().cameraLodData
end

---@return CameraPlaneData
function KingdomMapUtils.GetCameraPlaneData()
    return KingdomMapUtils.GetKingdomScene().cameraPlaneData
end

function KingdomMapUtils.GetKingdomMapSettings(type)
    local scene = KingdomMapUtils.GetKingdomScene()
    if not scene or not scene.stateMachine or not scene.mediator then
        return nil
    end
    return scene.mediator:GetEnvironmentSettings(type)
end

---@return MapRetrieveResult
function KingdomMapUtils.GetCurrentTile()
    local scene = KingdomMapUtils.GetKingdomScene()
    if not scene or not scene.mediator then
        return nil
    end
    return scene.mediator:GetCurrentTile()
end

function KingdomMapUtils.InNewbieScene()
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end
    return scene:GetName() == "NewbieScene"
end

function KingdomMapUtils.IsMapState()
    if  KingdomMapUtils.GetKingdomScene() == nil then return false end
    local sceneSM = KingdomMapUtils.GetKingdomState()
    return sceneSM and sceneSM:GetName() == require("KingdomSceneStateMap").Name or KingdomMapUtils.InNewbieScene()
end

function KingdomMapUtils.IsNewbieState()
    local NewbieState = require("NewbieState")
    return g_Game.StateMachine:IsCurrentState(NewbieState.Name)
end

function KingdomMapUtils.IsCityState()
    if  KingdomMapUtils.GetKingdomScene() == nil then return false end
    local sceneSM = KingdomMapUtils.GetKingdomState()
    return sceneSM and sceneSM:GetName() == require("KingdomSceneStateInCity").Name
end

---@param coord CS.DragonReborn.Vector2Short
---@return MapRetrieveResult
function KingdomMapUtils.RetrieveMap(tileX, tileZ)
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem == nil then
        return nil
    end

    KingdomMapUtils.decoListCache:Clear()

    mapSystem:RetrieveDecorations(tileX, tileZ, KingdomMapUtils.decoListCache)
    local globalOffset = mapSystem.GlobalOffset
    local offset = CS.Grid.MapUtils.CalculateWorldPositionToCoord(globalOffset, mapSystem.StaticMapData)

    local unitExists, range, unit = mapSystem:RetrieveUnitAt(tileX - offset.X, tileZ - offset.Y)
    local entity
    local playerUnit
    local sizeX = 1
    local sizeY = 1
    if unitExists then
        entity = g_Game.DatabaseManager:GetEntity(unit.Y, unit.X) 
        playerUnit = ModuleRefer.MapUnitModule:GetPlayerUnitData(unit.Y, unit.X)
        if entity and entity.TypeHash == DBEntityType.Expedition then
            sizeX = 1
            sizeY = 1
        else
            sizeX = range.xMax - range.xMin + 1
            sizeY = range.yMax - range.yMin + 1
            tileX = range.xMin
            tileZ = range.yMin
        end
    end
    return MapRetrieveResult.new(tileX + offset.X, tileZ + offset.Y, KingdomMapUtils.decoListCache, entity, playerUnit, sizeX, sizeY)

end

---@param tileX number
---@param tileZ number
---@return string
function KingdomMapUtils.CoordToXYString(tileX, tileZ)
    --if UNITY_EDITOR then
    --    local tid = ModuleRefer.TerritoryModule:GetTerritoryAt(tileX, tileZ)
    --    local mid = ModuleRefer.MapFogModule:GetMistAt(tileX, tileZ)
    --    return string.format("X:%d,Y:%d (tid=%d,mid=%d)", tileX, tileZ, tid, mid)
    --end
    return string.format("X:%d,Y:%d", tileX, tileZ)
end

---@param worldPosition CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function KingdomMapUtils.WorldToUIPosition(worldPosition)
    local screenPosition = KingdomMapUtils.WorldToScreenPosition(worldPosition)
    local uiCamera = g_Game.UIManager:GetUICamera()
    return uiCamera:ScreenToWorldPoint(screenPosition)
end

---@param worldPosition CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function KingdomMapUtils.WorldToScreenPosition(worldPosition)
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    local screenPosition = basicCamera.mainCamera:WorldToScreenPoint(worldPosition)
    screenPosition.z = 0
    return screenPosition
end

---@param range CS.DragonReborn.Range2Int
---@param camera CS.UnityEngine.Camera
---@param staticMapData CS.Grid.StaticMapData
---@param cameraLodData CameraLodData
function KingdomMapUtils.CalculateRangeToCameraSizeAndPosition(range, camera, staticMapData, cameraLodData)
    local coord = range.Center
    local lookAtPosition = MapUtils.CalculateCoordToTerrainPosition(coord.X, coord.Y, KingdomMapUtils.GetMapSystem())
    local rangeSizeX = (range.xMax - range.xMin) * staticMapData.UnitsPerTileX
    local rangeSizeY = (range.yMax - range.yMin) * staticMapData.UnitsPerTileZ
    local rangeSize = math.max(rangeSizeX, rangeSizeY)
    local cameraSize = rangeSize / math.tan(math.angle2radian(camera.fieldOfView / 2))
    cameraSize = math.max(cameraLodData.mapCameraMistTaskSize, cameraSize)
    return cameraSize, lookAtPosition
end

---@param coords table<CS.DragonReborn.Vector2Short>
---@param camera CS.UnityEngine.Camera
---@param staticMapData CS.Grid.StaticMapData
---@param cameraLodData CameraLodData
function KingdomMapUtils.CalculateCoordinatesToCameraSizeAndPosition(coords, camera, staticMapData, cameraLodData)
    local xMin, yMin, xMax, yMax
    ---@param coord CS.DragonReborn.Vector2Short
    for _, coord in ipairs(coords) do
        if coord then
            if not xMin or coord.X < xMin then
                xMin = coord.X
            end
            if not yMin or coord.Y < yMin then
                yMin = coord.Y
            end
            if not xMax or coord.X > xMax then
                xMax = coord.X
            end
            if not yMax or coord.Y > yMax then
                yMax = coord.Y
            end
        end
    end
    local range = Range2Int()
    range.xMin = xMin
    range.yMin = yMin
    range.xMax = xMax
    range.yMax = yMax
    return KingdomMapUtils.CalculateRangeToCameraSizeAndPosition(range, camera, staticMapData, cameraLodData)
end

function KingdomMapUtils.FocusCamera(anchorPosition, transition, callback)
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    if not basicCamera then
        return
    end

    local size = ConfigRefer.ConstMain:ChooseCameraDistance() or KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    if transition then
        KingdomMapUtils.prevCameraSize = basicCamera:GetSize()
        KingdomMapUtils.prevCameraEnableDragging = basicCamera.enableDragging
        KingdomMapUtils.prevCameraEnablePinch = basicCamera.enablePinch

        basicCamera.enableDragging = false
        basicCamera.enablePinch = false
        
        basicCamera:ZoomToWithAnchor(size, anchorPosition, KingdomConstant.CameraFocusDuration, function()
            basicCamera.enableDragging = true
            basicCamera.enablePinch = true
            if callback ~= nil then callback() end
        end)
    else
        basicCamera:LookAt(anchorPosition, 0)
        basicCamera:SetSize(size)
    end
end

function KingdomMapUtils.MoveAndZoomCamera(worldPosition, size, moveDuration, zoomDuration, moveEndCallback, zoomEndCallback)
    if not worldPosition  then
        return
    end
    
    moveDuration = moveDuration or 0.3
    zoomDuration = zoomDuration or 0.3
    
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    if not basicCamera then
        return
    end

    basicCamera:ForceGiveUpTween()
    basicCamera.enableDragging = false
    basicCamera.enablePinch = false

    local scene3DUI = Layers.Scene3DUI
    local camera = basicCamera.mainCamera
    basicCamera:LookAt(worldPosition, moveDuration, function()
        if moveEndCallback then
            moveEndCallback()
        end

        if KingdomMapUtils.InSymbolMapLod() then
            if Utils.IsNotNull(camera) then
                ModuleRefer.KingdomTransitionModule:DisableCullingMask(camera, scene3DUI)
                ModuleRefer.KingdomTransitionModule:DisableTransition()
            end

            local coord = MapUtils.CalculateWorldPositionToCoord(worldPosition, KingdomMapUtils.GetStaticMapData())
            KingdomMapUtils.GetMapSystem():ForceLoadHeightMap(coord.X, coord.Y)
        end
        
        basicCamera:ZoomTo(size, zoomDuration, function()
            if Utils.IsNotNull(camera) then
                ModuleRefer.KingdomTransitionModule:EnableCullingMask(camera, scene3DUI)
                ModuleRefer.KingdomTransitionModule:EnableTransition()
            end

            if basicCamera then
                basicCamera.enableDragging = true
                basicCamera.enablePinch = true
            end
            if zoomEndCallback then
                zoomEndCallback()
            end
        end)
    end)
end

--- 坐标跳转
---@param x number
---@param y number
---@param sceneType number @SceneType
function KingdomMapUtils.GotoCoordinate(x, y, sceneType, callback)
    if not sceneType then
        sceneType = SceneType.SlgBigWorld
    end
    
    if (sceneType == SceneType.SlgBigWorld) then
        local gotofun = function()
            local rx, rz = KingdomMapUtils.ParseCoordinate(x, y)
            local worldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(rx, rz, KingdomMapUtils.GetMapSystem())
            KingdomMapUtils.GetBasicCamera():LookAt(worldPos, 0)
            if callback then callback() end
        end
        if (not KingdomMapUtils.IsMapState()) then
            -- 出城加跳转
            KingdomMapUtils.GetKingdomScene():LeaveCity(gotofun)
        else
            -- 直接跳转
            gotofun()
        end
    elseif (sceneType == SceneType.Home) then
        local myCity = ModuleRefer.CityModule.myCity
        require("CityUtils").TryLookAtToCityCoord(myCity, x, y, 0, callback)
    end
end

---@param screenPosition CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function KingdomMapUtils.ScreenToWorldPosition(screenPosition, noClamp)
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    local ray = basicCamera:GetRayFromScreenPosition(screenPosition, noClamp)
    local pos = CameraUtils.GetHitPointOnMeshCollider(ray, MapTerrainMask)
    if not pos then
        pos = CameraUtils.GetHitPointLinePlane(ray,CameraConst.PLANE)
    end
    return pos
end

---@param layoutId number
---@return number
---@return number
---@return number
function KingdomMapUtils.GetLayoutSize(layoutId)
    local layoutConfig = ConfigRefer.MapBuildingLayout:Find(layoutId)
    if not layoutConfig then
        return 1, 1, 0
    end
    local row = layoutConfig:Layout(1)
    local sizeX = string.len(row)
    local sizeY = layoutConfig:LayoutLength()
    local margin = layoutConfig:Margin()
    return sizeX, sizeY, margin
end

---@param layoutId number
---@return number
function KingdomMapUtils.GetLayoutMargin(layoutId)
    local layoutConfig = ConfigRefer.MapBuildingLayout:Find(layoutId)
    if not layoutConfig then
        return 0
    end
    return layoutConfig:Margin()
end

---@return CS.UnityEngine.Vector3
function KingdomMapUtils.GetCameraAnchorPosition()
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    local screenCenterPos = Vector3(Screen.width / 2, Screen.height / 2, 0)
    local anchorPosition = basicCamera:GetPlaneHitPoint(screenCenterPos)
    -- local basicCamera = KingdomMapUtils.GetBasicCamera().mainCamera
    -- local nearPlaneDown = basicCamera.nearClipPlane * math.tan(math.rad(basicCamera.fieldOfView / 2)) * (-basicCamera.transform.up)
    -- local bottomMiddle = basicCamera.transform.position + basicCamera.transform.forward * basicCamera.nearClipPlane + nearPlaneDown
    -- local ray = CS.UnityEngine.Ray(bottomMiddle, CS.UnityEngine.Vector3.down)
    -- local layerMask = CS.UnityEngine.LayerMask.GetMask("MapTerrain", "CityStatic")
    -- local anchorPosition = CameraUtils.GetHitPointOnMeshCollider(ray, layerMask)
    return anchorPosition
end

---@return CS.DragonReborn.Vector2Short
function KingdomMapUtils.GetCameraAnchorCoordinate()
    local anchorPosition = KingdomMapUtils.GetCameraAnchorPosition()
    return MapUtils.CalculateWorldPositionToCoord(anchorPosition, KingdomMapUtils.GetStaticMapData())
end

function KingdomMapUtils.GetCameraAnchorTerrainPosition()
    local screenCenterPos = Vector3(Screen.width * 0.5, Screen.height * 0.5, 0)
    return KingdomMapUtils.ScreenToWorldPosition(screenCenterPos, true)
end

---@return CS.UnityEngine.Vector3
---@return CS.DragonReborn.Vector2Short
function KingdomMapUtils.GetCameraAnchorTerrainCoordinate()
    local anchorPosition = KingdomMapUtils.GetCameraAnchorTerrainPosition()
    return anchorPosition, MapUtils.CalculateWorldPositionToCoord(anchorPosition, KingdomMapUtils.GetStaticMapData())
end

---@return number
function KingdomMapUtils.GetCameraMinSize()
    if KingdomMapUtils.IsMapState() then
        return KingdomMapUtils.GetKingdomScene().cameraLodData:GetSizeByLod(0)
    end
    return 1300
end

---@param worldX number
---@param worldZ number
---@return number
function KingdomMapUtils.SampleHeight(worldX, worldZ)
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem then
        return mapSystem:GetTerrainHeight(worldX, worldZ)
    end
    return 0
end

function KingdomMapUtils.DirtyMapMark()
    local markCamera = KingdomMapUtils.GetMapMarkCamera()
    if markCamera then
        markCamera:SetDirty()
    end
end

---@return CS.DragonReborn.AABB
function KingdomMapUtils.GetCameraBox()
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if scene == nil then
        return nil
    end

    local cameraBox = scene.mapFoundation:GetCameraBox()
    return cameraBox
end

---@param tile MapRetrieveResult
function KingdomMapUtils.IsEmpty(tile)
    if tile.entity  or tile.playerUnit then
        return false
    else
        if ModuleRefer.MapCreepModule:CreepExistsAt(tile.X, tile.Z) then
            return false
        end
        return true
    end
end

function KingdomMapUtils.GetLOD()
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if not mapSystem then
        return 0
    end
    return mapSystem.Lod
end

function KingdomMapUtils.GetServerLOD()
    local lod = KingdomMapUtils.GetLOD()
    local serverLod = LodMapping.ParseLod(lod)
    return serverLod
end

function KingdomMapUtils.InCityLod(lod)
    return lod == 0
end

function KingdomMapUtils.InMapNormalLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod == KingdomConstant.NormalLod
end

function KingdomMapUtils.InMapLowLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod == KingdomConstant.LowLod
end

function KingdomMapUtils.InMapMediumLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod == KingdomConstant.MediumLod
end

function KingdomMapUtils.IsInMapMediumOrHigherLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod >= KingdomConstant.MediumLod
end

function KingdomMapUtils.InMapHighLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod == KingdomConstant.HighLod
end

function KingdomMapUtils.InMapVeryHighLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod == KingdomConstant.VeryHighLod
end

function KingdomMapUtils.InMapKingdomLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod >= KingdomConstant.HighLod
end

function KingdomMapUtils.InMapIconLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return KingdomConstant.LowLod <= lod and lod < KingdomConstant.SymbolLod
end

function KingdomMapUtils.InSymbolMapLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return lod >= KingdomConstant.SymbolLod
end

function KingdomMapUtils.InSymbolMapDetailLod(lod)
    lod = lod or KingdomMapUtils.GetLOD()
    return KingdomConstant.SymbolLod <= lod and lod <= KingdomConstant.VeryHighLod
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(configID, lod)
    local iconLod = MapConfigCache.GetFixedIconLod(configID)
    return iconLod <= lod
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckIconLodByFixedConfig(configID, lod)
    local iconLod = MapConfigCache.GetFixedIconLod(configID)
    local hiddenLod = MapConfigCache.GetFixedHiddenLod(configID)
    return (iconLod == 0 or iconLod <= lod) and (hiddenLod == 0 or lod < hiddenLod)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckTextLodByFixedConfig(configID, lod)
    return KingdomMapUtils.CheckNameLodByFixedConfig(configID, lod) or KingdomMapUtils.CheckLevelLodByFixedConfig(configID, lod)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckNameLodByFixedConfig(configID, lod)
    local nameLod = MapConfigCache.GetFixedNameLod(configID)
    local hiddenLod = MapConfigCache.GetFixedHiddenLod(configID)
    return (hiddenLod == 0 or lod < hiddenLod) and (lod < nameLod or nameLod == 0)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckLevelLodByFixedConfig(configID, lod)
    local hiddenLod = MapConfigCache.GetFixedHiddenLod(configID)
    return hiddenLod == 0 or lod < hiddenLod
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckLevelOnlyLodByFixedConfig(configID, lod)
    local nameLod = MapConfigCache.GetFixedNameLod(configID)
    local hiddenLod = MapConfigCache.GetFixedHiddenLod(configID)
    return (nameLod == 0 or nameLod <= lod) and lod < hiddenLod
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckHideByFixedConfig(configID)
    return MapConfigCache.GetFixedHideShow(configID)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckIsEnterOrHigherIconLodFlexible(configID, lod)
    local iconLod = MapConfigCache.GetFlexibleIconLod(configID)
    return iconLod <= lod
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckIconLodByFlexibleConfig(configID, lod)
    local iconLod = MapConfigCache.GetFlexibleIconLod(configID)
    local hiddenLod = MapConfigCache.GetFlexibleHiddenLod(configID)
    return (iconLod == 0 or iconLod <= lod) and (hiddenLod == 0 or lod < hiddenLod)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckTextLodByFlexibleConfig(configID, lod)
    return KingdomMapUtils.CheckNameLodByFlexibleConfig(configID, lod) or KingdomMapUtils.CheckLevelLodByFlexibleConfig(configID, lod)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckNameLodByFlexibleConfig(configID, lod)
    local nameLod = MapConfigCache.GetFlexibleNameLod(configID)
    local hiddenLod = MapConfigCache.GetFlexibleHiddenLod(configID)
    return lod < hiddenLod and (lod < nameLod or nameLod == 0)
end

---@param configID number
---@param lod number
function KingdomMapUtils.CheckLevelLodByFlexibleConfig(configID, lod)
    local hiddenLod = MapConfigCache.GetFlexibleHiddenLod(configID)
    return lod < hiddenLod
end

function KingdomMapUtils.MapTypeChanged(oldLod, newLod)
    return KingdomMapUtils.InSymbolMapLod(oldLod) ~= KingdomMapUtils.InSymbolMapLod(newLod)
    --local symbolLod = KingdomConstant.SymbolLod
    --local prevLod = symbolLod - 1
    --return oldLod == symbolLod and newLod == prevLod or oldLod == prevLod and newLod == symbolLod
end

function KingdomMapUtils.LodSwitched(oldLod, newLod, targetLod)
    if not oldLod or not newLod or not targetLod then
        return 0
    end
    if oldLod < targetLod and newLod >= targetLod then
        return 1
    elseif oldLod >= targetLod and newLod < targetLod then
        return -1    
    end
    return 0
end


---@param camera BasicCamera
function KingdomMapUtils.Border(camera, staticMapData, marginLeft, marginRight, marginBottom, marginTop)
    if camera == nil or staticMapData == nil then
        return
    end
    
    local sizeX, sizeZ = staticMapData.UnitsPerMapX, staticMapData.UnitsPerMapZ
    local centerX, centerZ = 0.5 * sizeX, 0.5 * sizeZ
    CameraUtils.ClampToBorder(camera, centerX, centerZ, sizeX, sizeZ, marginLeft, marginRight, marginBottom, marginTop)
end

---@param entityID number
---@return boolean
function KingdomMapUtils.IsMapEntitySelected(entityID)
    if not KingdomMapUtils.IsMapState() then
        return false
    end
    local currentTile = KingdomMapUtils.GetKingdomScene().mediator:GetCurrentTile()
    if currentTile and currentTile.entity then
        return currentTile.entity.ID == entityID
    end
    return false
end

---@param buildingPos wds.Vector3F
---@return number
---@return number
function KingdomMapUtils.ParseBuildingPos(buildingPos)
    if buildingPos then
        return math.floor(buildingPos.X), math.floor(buildingPos.Y)
    end
    return 0, 0
end

---@param x number
---@param z number
---@return number
---@return number
function KingdomMapUtils.ParseCoordinate(x, z)
    return math.floor(x), math.floor(z)
end

---@param creepData wds.PlayerMapCreep
---@return number,number,boolean @ recommendPower,costPPP,isSE
function KingdomMapUtils.CalcPower4CreepTumor(creepData)  
    local creepConfig = ConfigRefer.SlgCreepTumor:Find(creepData.CfgId)
    local recommendPower = 0
    local costPPP = 0
    local isSE = false
    if creepConfig and creepConfig:CenterType() == require("SlgCreepTumorCenterType").SLG then            
        ---防御塔式菌毯核心
        recommendPower = 0            
        local length = creepConfig:CenterSlgArmiesLength()
        for i = 1, length do
            local monsterId = creepConfig:CenterSlgArmies(i)
            local monsterCfg = ConfigRefer.KmonsterData:Find(monsterId)
            if monsterCfg then
                recommendPower = recommendPower + monsterCfg:RecommendPower()                
            end
        end            
    elseif creepConfig then
        ---副本式菌毯核心
        isSE = true
        --creepConfig:CenterSeInstance @MapInstance
        local mapInstId = creepConfig:CenterSeInstance()
        local mapCfg = ConfigRefer.MapInstance:Find(mapInstId)
        if mapCfg then
            recommendPower = mapCfg:Power()
            costPPP = mapCfg:CostPPP()
        end
    end
    return recommendPower,costPPP,isSE
end

---@param entity wds.Troop | wds.MapMob | wds.MobileFortress | wds.ResourceField | wds.Village | wds.PlayerMapCreep | wds.SlgInteractor 
---@return boolean, number,number,number @isSE,needPower, recommendPower, costPPP
function KingdomMapUtils.CalcRecommendPower(entity)    
    local isSE = false
    local needPower = -1
    local recommendPower = -1
    local costPPP = -1
    if not entity then
        return isSE, needPower, recommendPower,costPPP
    elseif entity.TypeHash == DBEntityType.ResourceField then
        --资源田
        local resourceCfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
        if resourceCfg ~= nil then
            recommendPower = 0
            for i = 1, resourceCfg:InitTroopsLength() do
                local monsterId = resourceCfg:InitTroops(i)
                local monsterCfg = ConfigRefer.KmonsterData:Find(monsterId)
                if monsterCfg then
                    recommendPower = recommendPower + monsterCfg:RecommendPower()
                end
            end
        end
    elseif entity.TypeHash == DBEntityType.Village then
        -- todo get all troop power
        recommendPower = -1
        costPPP = 0
    elseif entity.TypeHash == wds.PlayerMapCreep.TypeHash then
        ---菌毯核心
        recommendPower,costPPP,isSE = KingdomMapUtils.CalcPower4CreepTumor(entity)
    elseif entity.TypeHash == DBEntityType.SlgInteractor then
        ---Slg交互物:SE入口       
        local configId = entity.Interactor and entity.Interactor.ConfigID or -1
        local conf = (configId > 0) and ConfigRefer.Mine:Find(configId) or nil
        local mapInstId = conf and conf:MapInstanceId() or nil
        if mapInstId > 0 then
            local mapCfg = ConfigRefer.MapInstance:Find(mapInstId)   
            if mapCfg then         
                isSE = true
                recommendPower = mapCfg:Power() 
                costPPP = mapCfg:CostPPP()
            end
        end
    elseif entity.TypeHash == DBEntityType.MapMob then
        ---Slg怪物        
        local monsterCfg = entity.MobInfo and ConfigRefer.KmonsterData:Find(entity.MobInfo.MobID) or nil
        if monsterCfg then
            recommendPower = monsterCfg:RecommendPower()
            costPPP = monsterCfg:CostPPP()
        end
    elseif entity.TypeHash == DBEntityType.Troop or entity.TypeHash == DBEntityType.MobileFortress then
        ---部队        
        recommendPower = ModuleRefer.SlgModule:GetTroopPowerByDBData(entity)         
    end

    if needPower > 0 or recommendPower > 0 then       
        if needPower <= 0 then
            needPower = recommendPower * ConfigRefer.ConstMain:BattlePowerParamMin()
        end
    end
    return isSE, needPower, recommendPower,costPPP
end

function KingdomMapUtils.GetSEMapInstanceIdInEntity(entity)
    if not entity then return 0,0 end
    local tid = 0   
    if entity.TypeHash == wds.PlayerMapCreep.TypeHash then
        ---菌毯核心
        local creepConfig = ConfigRefer.SlgCreepTumor:Find(entity.CreepTumorInfo.CfgId)
        if creepConfig then
            ---副本式菌毯核心                              
            tid = creepConfig:CenterSeInstance()                
        end
    elseif entity.TypeHash == DBEntityType.SlgInteractor then
        ---Slg交互物:SE入口            
        local configId = entity.Interactor and entity.Interactor.ConfigID or -1
        local conf = (configId > 0) and ConfigRefer.Mine:Find(configId) or nil
        if conf then
            tid = conf:MapInstanceId()
        end            
    end
    return tid
end

function KingdomMapUtils.GetSEPetCatchInfoByPetId(uniqueName)
    local petInfo = ModuleRefer.PetModule:GetWorldPetData(uniqueName)
    local petWildId = petInfo.data.ConfigId or 0                                  
    return ModuleRefer.PetModule:GetSeMapIdByPetWildId(petWildId)     
end

function KingdomMapUtils.GetSEPetCatchInfoByPosition(position)
    local tid = 0
    local petCompId = nil
    local has, list = ModuleRefer.PetModule:HasPetInWorld(position)
    if has then
        petCompId = list[1].id                  
        tid = KingdomMapUtils.GetSEPetCatchInfoByPetId(petCompId)   
    end
    return tid,petCompId
end

function KingdomMapUtils.GetSEInfoInPosition(position)
    local tid = 0
    local petCompId = 0
    local petCatch = false

    ---@type wds.SlgInteractor 
    local entity = ModuleRefer.SlgModule:GetKingdomEntityByPosWS(position)
    if not entity then
        tid,petCompId = KingdomMapUtils.GetSEPetCatchInfoByPosition(position)
        petCatch = true
    else
       tid = KingdomMapUtils.GetSEMapInstanceIdInEntity(entity)
    end    
    return tid,petCompId,petCatch
end

---@param entity wds.Village|wds.BehemothCage|wds.Pass|{MapStates:{StateWrapper2:{CreepInfected:boolean}}}
function KingdomMapUtils.IsMapEntityCreepInfected(entity)
    if entity and entity.MapStates and entity.MapStates.StateWrapper2 then
        return entity.MapStates.StateWrapper2.CreepInfected
    end
    return false
end

---@param brief wds.MapEntityBrief
function KingdomMapUtils.IsMapEntityBriefCreepInfected(brief)
    return (brief.ExtStateMask & wds.MapEntityExtStateMask.MapEntityExtStateMask_CreepInfected) ~= 0
end

---@param state boolean
function KingdomMapUtils.SwitchRenderFeature(type, name, state)
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    if basicCamera then
        local camera = basicCamera.mainCamera
        local feature = camera:GetCameraRendererFeature(type, name)
        if feature then
            feature:SetActive(state)
        end
    end
end

function KingdomMapUtils.ShowMapDecorations()
    CS.Grid.MapUtils.EnableSimpleMeshRenderingSystem(true)
end

function KingdomMapUtils.HideMapDecorations()
    CS.Grid.MapUtils.EnableSimpleMeshRenderingSystem(false)
end

function KingdomMapUtils.SetGlobalCityMapParamsId(isMap)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    if isMap then
        MapUtils.SetGlobalCityMapParamsId(staticMapData.UnitsPerTileX)
    else
        MapUtils.SetGlobalCityMapParamsId(0.19)
    end
end

return KingdomMapUtils
