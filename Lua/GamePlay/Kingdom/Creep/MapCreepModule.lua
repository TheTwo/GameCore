local BaseModule = require("BaseModule")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local EventConst = require("EventConst")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")
local I18N = require("I18N")
local KingdomConstant = require("KingdomConstant")
local UIMediatorNames = require("UIMediatorNames")
local OnChangeHelper = require("OnChangeHelper")
local PoolUsage = require("PoolUsage")
local MapCreepCleaningContainer = require("MapCreepCleaningContainer")
local ItemPopType = require("ItemPopType")
local MapCreepUtils = require("MapCreepUtils")
local MapCreepLineManager = require("MapCreepLineManager")
local DBEntityViewType = require("DBEntityViewType")

local MapUtils = CS.Grid.MapUtils
local MapCreepMask = CS.Kingdom.MapCreepMask
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local Vector3 = CS.UnityEngine.Vector3
local Up = CS.UnityEngine.Vector3.up
local One = CS.UnityEngine.Vector3.one
local HashSetLong = CS.System.Collections.Generic.HashSet(typeof(CS.System.Int64))


---@class MapCreepModule : BaseModule
---@field creepMask CS.Kingdom.MapCreepMask
---@field settings CS.Kingdom.MapCreepSettings
---@field isDirty boolean
---@field isShow boolean
---@field basicCamera BasicCamera
---@field staticMapData CS.Grid.StaticMapData
---@field isCleaning boolean
---@field isDragging boolean
---@field initialCreepData wds.SlgCreepTumor
---@field cleanItemConfigID number
---@field cleanedCreeps table @CS.System.Collections.Generic.HashSet(typeof(CS.System.Int64))
---@field cleaningContainers MapCreepCleaningContainer
---@field dragPosition CS.UnityEngine.Vector3
---@field vfxLife number
---@field gridMeshHandle CS.DragonReborn.AssetTool.PooledGameObjectHandle
---@field gridMesh CS.GridMapBuildingMesh
---@field rewardMessageSet table<number, wrpc.PushRewardRequest>
---@field cameraMinSize number
---@field cameraMaxSize number
local MapCreepModule = class("MapCreepModule", BaseModule)
local MASK_SIZE = 512
local MinBloomScatter = 0.3
local MaxBloomScatter = 0.9

function MapCreepModule:OnRegister()
    self.creepMask = MapCreepMask()
    self.gridMeshHandle = PooledGameObjectHandle(PoolUsage.Map)
    self.vfxHandle = PooledGameObjectHandle(PoolUsage.Map)
    self.rewardMessageSet = {}
    ---@type table<number, number> @mobEntityId->CreepTumorEntityId
    self.mobToCreepCenter = {}
end

function MapCreepModule:OnRemove()
    self.creepMask = nil
    self.gridMeshHandle = nil
    self.vfxHandle = nil
    table.clear(self.mobToCreepCenter)
end

function MapCreepModule:Setup()
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()

    self.isShow = true
    self.isDirty = true

    local lodData = KingdomMapUtils.GetCameraLodData()
    self.cameraMinSize = lodData:GetSizeByLod(KingdomConstant.KingdomLodMin - 1)
    self.cameraMaxSize = lodData:GetSizeByLod(KingdomConstant.SymbolLod - 1)
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapCreepSettings))

    self.isCleaning = false
    self.cleaningContainers = MapCreepCleaningContainer.new()
    self.cleanedCreeps = HashSetLong()

    local settingsRoot = KingdomMapUtils.GetKingdomScene().mediator:GetEnvironmentSettings()
    self.creepMask:Initialize(MASK_SIZE, settingsRoot, KingdomMapUtils.GetStaticMapData(), KingdomMapUtils.GetMapSystem().GlobalOffset)
    self.creepLineMgr = MapCreepLineManager.new()
    self.creepLineMgr:Init()

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON, Delegate.GetOrCreate(self, self.ExitCreepCleaning))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_START, Delegate.GetOrCreate(self, self.OnDragStart))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_END, Delegate.GetOrCreate(self, self.OnDragEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_PESTICIDE_DRAG, Delegate.GetOrCreate(self, self.OnDrag))
    g_Game.EventManager:AddListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.OnTouchInfoClosed))
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnSizeChanged))

    g_Game.DatabaseManager:AddViewNewByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnAddOrUpdateCreep))
    g_Game.DatabaseManager:AddViewDestroyByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnRemoveCreep))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SlgCreepTumor.CreepTumorInfo.MsgPath, Delegate.GetOrCreate(self, self.OnChangeCreep))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SlgCreepTumor.CreepTumorInfo.CreepMobId.MsgPath, Delegate.GetOrCreate(self, self.OnCreepTumorMobChanged))

    self.creepLineMgr:SetupEvents(true)

    self.isDirty = true
end

function MapCreepModule:ShutDown()
    if self.creepLineMgr then
        self.creepLineMgr:SetupEvents(false)
        self.creepLineMgr:Release()
        self.creepLineMgr = nil
    end
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON, Delegate.GetOrCreate(self, self.ExitCreepCleaning))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_START, Delegate.GetOrCreate(self, self.OnDragStart))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_END, Delegate.GetOrCreate(self, self.OnDragEnd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_PESTICIDE_DRAG, Delegate.GetOrCreate(self, self.OnDrag))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.OnTouchInfoClosed))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnSizeChanged))

    g_Game.DatabaseManager:RemoveViewNewByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnAddOrUpdateCreep))
    g_Game.DatabaseManager:RemoveViewDestroyByType(DBEntityViewType.ViewSlgCreepTumorForMap, Delegate.GetOrCreate(self, self.OnRemoveCreep))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SlgCreepTumor.CreepTumorInfo.MsgPath, Delegate.GetOrCreate(self, self.OnChangeCreep))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SlgCreepTumor.CreepTumorInfo.CreepMobId.MsgPath, Delegate.GetOrCreate(self, self.OnCreepTumorMobChanged))

    self:ExitCreepCleaning()
    self:HideCreep()
    self:ReleaseVfx()

    self.cleaningContainers = nil
    self.cleanedCreeps = nil
    table.clear(self.rewardMessageSet)
    table.clear(self.mobToCreepCenter)

    self.creepMask:Dispose()
    
    self.settings = nil
end

function MapCreepModule:Tick(dt)
    if not KingdomMapUtils.IsMapState() then
        return
    end

    if self.vfxLife and self.vfxLife > 0 then
        self.vfxLife = self.vfxLife - dt
    end
    
    if self.isShow then
        if self.isDirty then
            self.creepMask:PrepareMaskData()
        end

        local mapSystem = KingdomMapUtils.GetMapSystem()
        if mapSystem.CullUpdated or self.isDirty then
            local cameraBox = mapSystem.RealCameraBox
            local texMask = self.creepMask:Cull(cameraBox)
            mapSystem:SetTerrainCreepRenderTexture(cameraBox, texMask)
        end

        self.isDirty = false
    end
    self.creepLineMgr:Tick(dt)
end

function MapCreepModule:OnTouchInfoClosed()
    self.creepMask:DisableHighlight()
    self.isDirty = true
end

function MapCreepModule:OnLodChanged(oldLod, newLod)
    self.isShow  = self:CanShowCreep(newLod)
end

function MapCreepModule:OnSizeChanged(oldSize, newSize)
    local lod = KingdomMapUtils.GetLOD()
    if self:CanShowCreep(lod) then
        local ratio = math.clamp01((newSize - self.cameraMinSize) / (self.cameraMaxSize - self.cameraMinSize))
        local scatter = math.lerp(self.settings.MaxBloomScatter, self.settings.MinBloomScatter, ratio)
        self.creepMask:SetScatter(scatter)
        self.isDirty = true
    end
end

function MapCreepModule:SetDirty()
    self.isDirty = true
end

function MapCreepModule:CanShowCreep(lod)
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod)
end

---@param entity wds.SlgCreepTumorInfo
function MapCreepModule:BuildUpdateCreepInfo(id, entity)
    local centerSize = nil
    local patchSize = {}
    local circles = {}
    local pathes = {}
    local centerConfig = ConfigRefer.SlgCreepCenter:Find(entity.CfgId)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(centerConfig:CenterBuildingLayout())
    centerSize = layout and layout.SizeX
    local inCleanSkip = self.cleaningContainers.idList[id] or {}
    for i, info in ipairs(entity.Circles) do
        local circleConfig = ConfigRefer.SlgCreepOuter:Find(info.BlockConfigId)
        if not centerSize then
            centerSize = circleConfig:Size()
        end
        patchSize[#patchSize + 1] = circleConfig:Size()
        circles[#circles + 1] = i
        local blocks = {}
        pathes[#pathes + 1] = blocks
        local blockId = 0
        for _, value in ipairs(info.Blocks) do
            local removeInCleaningValue = value
            for bitPos = 0, 63 do
                if inCleanSkip[i-1] and inCleanSkip[i-1][blockId] then
                    removeInCleaningValue = removeInCleaningValue & (~(1 << bitPos))
                end
                blockId = blockId + 1
            end
            blocks[#blocks + 1] = removeInCleaningValue
        end
    end
    return centerSize, patchSize, circles, pathes
end

---@param entity wds.SlgCreepTumor
function MapCreepModule:OnAddOrUpdateCreep(entity, _, refCount)
    if refCount > 1 then return end
    for key, value in pairs(self.mobToCreepCenter) do
        if value == entity.ID then
            self.mobToCreepCenter[key] = nil
            break
        end
    end
    if entity.CreepTumorInfo.CreepMobId ~= 0 then
        self.mobToCreepCenter[entity.CreepTumorInfo.CreepMobId] = entity.ID
    end
    local buildingPosX,buildingPosY = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local centerSize, patchSize, circles, pathes = self:BuildUpdateCreepInfo(entity.ID, entity.CreepTumorInfo)
    if not centerSize then return end
    self.creepMask:UpdateCreep(entity.ID, buildingPosX, buildingPosY, centerSize, patchSize, circles, pathes)
    self.isDirty = true
end

---@param entity wds.SlgCreepTumor
function MapCreepModule:OnRemoveCreep(entity, _, refCount)
    if refCount > 1 then return end
    for key, value in pairs(self.mobToCreepCenter) do
        if value == entity.ID then
            self.mobToCreepCenter[key] = nil
            break
        end
    end
    self.creepMask:RemoveCreep(entity.ID)
    self.isDirty = true
end

---@param entity wds.SlgCreepTumor
function MapCreepModule:OnCreepTumorMobChanged(entity)
    for key, value in pairs(self.mobToCreepCenter) do
        if value == entity.ID then
            self.mobToCreepCenter[key] = nil
            break
        end
    end
    if entity.CreepTumorInfo.CreepMobId ~= 0 then
        self.mobToCreepCenter[entity.CreepTumorInfo.CreepMobId] = entity.ID
    end
end

function MapCreepModule:OnChangeCreep(entity, _)
    self:OnAddOrUpdateCreep(entity, nil, 1)
end

function MapCreepModule:HideCreep()
    local mapSystem = KingdomMapUtils.GetMapSystem()
    mapSystem:SetTerrainCreepRenderTexture(mapSystem.CameraBox, nil)
end

function MapCreepModule:EnableHighlight(uniqueId)
    self.creepMask:EnableHighlight(uniqueId)
    self.isDirty = true
end

---@param tile MapRetrieveResult
function MapCreepModule:CheckCanClean(showToast)
    local item = ModuleRefer.CityCreepModule:GetAvailableSweeperItem()
    if not item then
        if showToast then ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("slgjuntan_tishi3")) end
        return false
    end
    
    return true
end

local ListOfColorType = CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Color))
local ListOfColor = ListOfColorType()

---@param go CS.UnityEngine.GameObject
local function OnGridMeshLoaded(go, data)
    if Utils.IsNotNull(go) then
        local staticMapData = KingdomMapUtils.GetStaticMapData()
        local creepData = ModuleRefer.MapCreepModule.initialCreepData
        
        ---@type CS.GridMapBuildingMesh
        local gridMesh = go:GetComponent(typeof(CS.GridMapBuildingMesh))
        
        local creepConfig = ConfigRefer.SlgCreepCenter:Find(creepData.CreepTumorInfo.CfgId)
        local circleBlockConfig = ConfigRefer.SlgCreepOuter:Find(creepConfig:OuterBlocks(1))
        local patchSize = circleBlockConfig:Size()
        local unitX, unitZ = staticMapData.UnitsPerTileX, staticMapData.UnitsPerTileZ
        local ret = {}
        for i = 1, patchSize * patchSize do
            table.insert(ret, 0)
        end
        local _, yesColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#C9D469DD")
        ListOfColor:Clear()
        ListOfColor:Add(yesColor)
        gridMesh:Initialize(patchSize, patchSize, unitX, unitZ, ret, ListOfColor, 100)
        ModuleRefer.MapCreepModule.gridMesh = gridMesh
    end
end

---@param creepData wds.SlgCreepTumor
function MapCreepModule:StartSweepClean(creepData)
    self.isCleaning = true
    self.initialCreepData = creepData
    self.cleanedCreeps:Clear()
    
    self.gridMeshHandle:Create(ManualResourceConst.map_creep_selector, KingdomMapUtils.GetMapSystem().Parent, OnGridMeshLoaded)
    self.vfxHandle:Create(ManualResourceConst.vfx_city_xiaosha_xishou, KingdomMapUtils.GetMapSystem().Parent, Delegate.GetOrCreate(self, self.OnSweeperVfxCreated))

    self.creepMask:EnableHighlight(creepData.ID)
    self.isDirty = true
    self.vfxLife = 0

    local x, z = KingdomMapUtils.ParseBuildingPos(creepData.MapBasics.BuildingPos)
    local worldPosition = MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
    KingdomMapUtils.MoveAndZoomCamera(worldPosition, 1800, 0.15, 0.15, nil, function()
        KingdomMapUtils.GetBasicCamera().enablePinch = false
        ---@type CityCreepClearInteractUIParameter
        local param = {
            camera = KingdomMapUtils.GetBasicCamera(),
        }
        g_Game.UIManager:Open(UIMediatorNames.CityCreepClearNewUIMediator, param, nil, true)
    end)
end

function MapCreepModule:StopSweepClean(closeUI)
    self.isCleaning = false
    self.isDragging = false

    self:ReleaseVfx()

    local basicCamera = KingdomMapUtils.GetBasicCamera()
    basicCamera.enablePinch = true
    basicCamera.enableDragging = true
    
    self.creepMask:DisableHighlight()
    self.isDirty = true

    if closeUI then
        g_Game.UIManager:CloseByName(UIMediatorNames.CityCreepClearNewUIMediator)
    end
end

function MapCreepModule:ExitCreepCleaning()
    self:StopSweepClean(true)
end

function MapCreepModule:OnDragStart(itemConfigID)
    KingdomMapUtils.GetBasicCamera().enableDragging = false
    
    self.cleaningContainers:Clear()
    self.cleanedCreeps:Clear()
    self.creepMask:CheckAnyCreepCleaned(self.cleanedCreeps)
    self.cleanItemConfigID = itemConfigID
    self.isDragging = true
    self:EnableVfx()
end

function MapCreepModule:OnDragEnd()
    if not self.isDragging then return end

    KingdomMapUtils.GetBasicCamera().enableDragging = true

    self:RequestCleanCreep()

    self:DisableVfx()
    self.gridMeshHandle:Delete()
    self.isDragging = false
end

function MapCreepModule:OnDrag(screenPos)
    if not self.isDragging then return end
    
    screenPos = screenPos + Vector3(-70, -70, 0)
    local worldPosition = KingdomMapUtils.ScreenToWorldPosition(screenPos)
    local coord = MapUtils.CalculateWorldPositionToCoord(worldPosition, KingdomMapUtils.GetStaticMapData())

    local creepID, circleIndex, patchID = self.creepMask:FindCreep(coord.X, coord.Y)
    if creepID ~= 0 and creepID == self.initialCreepData.ID then
        --是否已经清理过
        if not self.cleaningContainers:Contains(patchID, creepID, circleIndex) and not self.cleanedCreeps:Contains(creepID) then
            self.cleaningContainers:Add(patchID, creepID, circleIndex)
            local entity = self:GetCreepEntity(creepID)
            local centerSize, patchSize, circles, pathes = self:BuildUpdateCreepInfo(entity.ID, entity.CreepTumorInfo)
            if not centerSize then return end
            local buildingPosX, buildingPosY = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
            self.creepMask:UpdateCreep(creepID, buildingPosX, buildingPosY, centerSize, patchSize, circles, pathes)
            self.isDirty = true
            self.vfxLife = 3
             --self:PopCleanLightReward(creepConfig)            
            local cost = ConfigRefer.ConstMain:CostDurabilityPerSlgCreepBlock()
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_CLEAR_BIG_ADD, cost)
        end

        if self.creepMask:CheckAnyCreepCleaned(self.cleanedCreeps) then
            self:RequestCleanCreep()
            self:ExitCreepCleaning()
        end
    end

    self:UpdateVfxPosition(creepID, coord)
end

function MapCreepModule:RequestCleanCreep()
    if not self.cleaningContainers:IsEmpty() then
        local request = require("ClearOuterSlgCreepParameter").new()
        request.args.TargetCreepId = self.initialCreepData.ID
        request.args.ItemId = self.cleanItemConfigID
        for _, circleList in pairs(self.cleaningContainers.idList) do
            for circleIndex, indexMap in pairs(circleList) do
                for _, index in pairs(indexMap) do
                    request.args.Circles:Add(circleIndex)
                    request.args.BlockIndex:Add(index)
                end
            end
        end
        request:SendWithFullScreenLock()
        self.cleaningContainers:Clear()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_CLEAR_DO)
    end
end

---@param go CS.UnityEngine.GameObject
function MapCreepModule:OnSweeperVfxCreated(go, userdata)
    go:SetLayerRecursively("Tile")
    self.sweeperVfxTrans = go.transform
    self.sweeperVfxTrans.localScale = One * 50
    self.sweeperVfxTrans:SetVisible(false)
end


---@param creepID number
---@param coord CS.DragonReborn.Vector2Short
function MapCreepModule:UpdateVfxPosition(creepID, coord)
    if not self.isDragging then return end
    local gridMeshX, gridMeshZ, sweeperX, sweeperZ = self:CalculateVfxPosition(coord.X, coord.Y)
    if gridMeshX and gridMeshZ then
        local gridMeshPosition = MapUtils.CalculateCoordToTerrainPosition(gridMeshX, gridMeshZ, KingdomMapUtils.GetMapSystem())
        gridMeshPosition.y = KingdomMapUtils.SampleHeight(gridMeshPosition.x, gridMeshPosition.z) + 5
        if Utils.IsNotNull(self.gridMesh) then
            self.gridMesh:SetVisible(true)
            self.gridMesh.transform.position = gridMeshPosition
        end
    else
        if Utils.IsNotNull(self.gridMesh) then
            self.gridMesh:SetVisible(false)
        end
    end
    if sweeperX and sweeperZ then
        local sweeperVfxPosition = MapUtils.CalculateCoordToTerrainPosition(sweeperX, sweeperZ, KingdomMapUtils.GetMapSystem())
        if Utils.IsNotNull(self.sweeperVfxTrans) then
            self.sweeperVfxTrans.position = sweeperVfxPosition  + Vector3(0, 40, 0)
            self.sweeperVfxTrans:SetVisible(true)
        end
    else
        if Utils.IsNotNull(self.sweeperVfxTrans) then
            self.sweeperVfxTrans:SetVisible(false)
        end
    end
end

function MapCreepModule:ReleaseVfx()
    if self.gridMeshHandle then
        self.gridMeshHandle:Delete()
    end
    self:DisableVfx()
    self.gridMesh = nil

    if self.vfxHandle then
        self.vfxHandle:Delete()
    end
    self.sweeperVfxTrans = nil
end

function MapCreepModule:EnableVfx()
    if Utils.IsNotNull(self.sweeperVfxTrans) then
        self.sweeperVfxTrans:SetVisible(true)
    end
    if Utils.IsNotNull(self.gridMesh) then
        self.gridMesh:SetVisible(true)
    end
end

function MapCreepModule:DisableVfx()
    if Utils.IsNotNull(self.sweeperVfxTrans) then
        self.sweeperVfxTrans:SetVisible(false)
    end
    if Utils.IsNotNull(self.gridMesh) then
        self.gridMesh:SetVisible(false)
    end
end

---@param creepConfig SlgCreepTumorConfigCell
function MapCreepModule:PopCleanLightReward(creepConfig)
    local msg = self.rewardMessageSet[creepConfig:Id()]
    if not msg then
        msg = {}
        msg.PopType = ItemPopType.PopTypeLightReward
        msg.ItemCount = {}
        msg.ItemID = {}
        
        local itemGroup = ConfigRefer.ItemGroup:Find(creepConfig:OuterRemoveRewards())
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroup:ItemGroupInfoList(i)
            table.insert(msg.ItemID, itemGroupInfo:Items())
            table.insert(msg.ItemCount, itemGroupInfo:Nums())
        end
   
        self.rewardMessageSet[creepConfig:Id()] = msg
    end
    ModuleRefer.RewardModule:ShowLightReward(msg)
end

function MapCreepModule:CreepExistsAt(tileX, tileZ)
    local uniqueId, _, _ = self.creepMask:FindCreep(tileX, tileZ)
    return uniqueId ~= 0
end

---@return table<number, wds.PlayerMapCreep> | MapField
function MapCreepModule:GetAllCreeps()
    local playerMapCreeps = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerMapCreeps
    return playerMapCreeps and playerMapCreeps.Creeps or {}
end

---@return wds.SlgCreepTumor
function MapCreepModule:GetCreepEntityAt(tileX, tileZ)
    local uniqueId, _, _ = self.creepMask:FindCreep(tileX, tileZ)
    if uniqueId ~= 0 then
        return g_Game.DatabaseManager:GetEntity(uniqueId, DBEntityType.SlgCreepTumor)
    end
    return nil
end

---@return wds.SlgCreepTumor
function MapCreepModule:GetCreepEntity(entityId)
    ---@type wds.SlgCreepTumor
    local mapEntity = g_Game.DatabaseManager:GetEntity(entityId, DBEntityType.SlgCreepTumor)
    return mapEntity
end

---@return wds.SlgCreepTumorInfo
---@return SlgCreepCenterConfigCell
function MapCreepModule:GetCreepDataAt(tileX, tileZ)
    local uniqueId, _, _ = self.creepMask:FindCreep(tileX, tileZ)
    if uniqueId ~= 0 then
        local data = self:GetCreepData(uniqueId)
        if not data then return nil, nil end
        local creepConfig = ConfigRefer.SlgCreepTumor:Find(data.CfgId)
        return data, creepConfig
    end
    return nil, nil
end

---@return wds.SlgCreepTumorInfo
function MapCreepModule:GetCreepData(id)
    ---@type wds.SlgCreepTumor
    local mapEntity = g_Game.DatabaseManager:GetEntity(id, DBEntityType.SlgCreepTumor)
    return mapEntity and mapEntity.CreepTumorInfo or nil
end

function MapCreepModule:CalculateVfxPosition(tileX, tileZ)
    local circleIndex, creepX, creepZ = self.creepMask:GetPatchCoordinate(self.initialCreepData.ID, tileX, tileZ)
    if circleIndex < 0 then return tileX,tileZ,tileX,tileZ end
    local circleData = self.initialCreepData.CreepTumorInfo.Circles[circleIndex + 1]
    local creepConfig = ConfigRefer.SlgCreepOuter:Find(circleData.BlockConfigId)
    local patchSize = creepConfig:Size()
    local round = circleIndex + 1
    local posX, posY = KingdomMapUtils.ParseBuildingPos(self.initialCreepData.MapBasics.BuildingPos)
    local minX = posX - round * patchSize
    local minZ = posY - round * patchSize
    local gridMeshX = creepX * patchSize + minX
    local gridMeshZ = creepZ * patchSize + minZ
    local sweeperX = math.floor(creepX * patchSize + minX + patchSize / 2)
    local sweeperZ = math.floor(creepZ * patchSize + minZ + patchSize / 2)
    return gridMeshX, gridMeshZ, sweeperX, sweeperZ
end

---@param creepData wds.PlayerMapCreep
function MapCreepModule:IsTumorAlive(creepData)
    if not creepData then
        return false
    end
    return creepData.Status == wds.PlayerMapCreepStatus.PlayerMapCreepStatusNormal
end

---@param childs wds.CreepTumorChild[]
function MapCreepModule.MaxDepth(childs, maxDepth)
    if not childs then return maxDepth end
    for _, current in ipairs(childs) do
        if current.State == wds.CreepTumorNodeStatus.CreepTumorNodeStatusNormal and not current.NotWorking then
            maxDepth = (maxDepth or 0) + 1
        end
    end
    return maxDepth
end

---@param creepSpread wds.CreepSpread
---@return number|nil,string,string @count, icon, buffValue
function MapCreepModule.GetCreepSpreadBuffCount(creepSpread)
    if not creepSpread then return nil end
    local maxDepth = MapCreepModule.MaxDepth(creepSpread.Childs, nil)
    return maxDepth, "sp_icon_buff_strain", maxDepth and I18N.GetWithParams("base_pet_rank_attr_des", maxDepth * 10) or string.Empty
end

---@return number,string,string @count, icon, buffValue
function MapCreepModule:GetMonsterLinkTumorCreepBuffCount(mobEntityId)
    local linkCreepTumorId = self.mobToCreepCenter[mobEntityId]
    if not linkCreepTumorId then return nil end
    ---@type wds.SlgCreepTumor
    local tumor = g_Game.DatabaseManager:GetEntity(linkCreepTumorId, DBEntityType.SlgCreepTumor)
    return MapCreepModule.GetCreepSpreadBuffCount(tumor and tumor.CreepSpread)
end

return MapCreepModule
