
local SEEnvironment = require("SEEnvironment")
local Delegate = require("Delegate")
local CitySeInputWrapper = require("CitySeInputWrapper")
local SESceneRoot = require("SESceneRoot")
local UnitActorFactory = require("UnitActorFactory")
local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local UnitActorType = require("UnitActorType")
local UnitMoveManager = require("UnitMoveManager")
local ConfigRefer = require("ConfigRefer")
local CityElementType = require("CityElementType")
local UnitCitizenConfigWrapper = require("UnitCitizenConfigWrapper")
local ArtResourceUtils = require("ArtResourceUtils")
local CityStateHelper = require("CityStateHelper")
local CityConst = require("CityConst")
local CitySePresetHeroPetLink = require("CitySePresetHeroPetLink")
local EventConst = require("EventConst")
local SEUnitCategory = require("SEUnitCategory")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local HomeSeTroopRecoverHpParameter = require("HomeSeTroopRecoverHpParameter")
local CitySeExpedtitionMarker = require("CitySeExpedtitionMarker")
local TimerUtility = require('TimerUtility')
local SLGConst_Manual = require("SLGConst_Manual")
local SEMapInfo = CS.SEMapInfo
local LAYER_MASK_SE_FLOOR = 1 << 20
local SEPreExportDefine = require("SEPreExportDefine")
local Utils = require("Utils")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")

local CityManagerBase = require("CityManagerBase")

---@alias WanderingHeroesInitParam {fromPos:wds.Vector3F, fromDir:wds.Vector3F}

---@class CitySeManager:CityManagerBase
---@field super CityManagerBase
local CitySeManager = class("CitySeManager", CityManagerBase)

local LAYER_MASK_CITY_STATIC = 1 << 11

function CitySeManager:ctor(city, ...)
    CitySeManager.super.ctor(self, city, ...)
    ---@type CitySeMapInfo
    self._seMapInfoLua = nil
    ---@type SEEnvironment
    self._seEnvironment = nil
    self._seEnvinited = false
    self._cityFixedSeId = 20000 -- special for city
    self._inputWrapper = CitySeInputWrapper.new(city)
    ---@type table<number, boolean>
    self._presetWanderingHeroes = {}
    ---@type table<number, WanderingHeroesInitParam>
    self._pendingCreateHeroes = {}
    ---@type table<number, boolean>
    self._markIsExplorerModeEndTeleport = {}
    ---@type table<number, CityUnitExplorer>
    self._createdWanderingSeHeroes = {}
    self._moveManager = UnitMoveManager.new()
    ---@type table<number, number>
    self._heroIdConfig2CitizenConfigId = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("CitySeManager")
    ---@type CitySePresetHeroPetLink
    self._presetHeroPetLink = CitySePresetHeroPetLink.new(self)
    self._seModleExtraScale = 1

    self._dummyUnitEntity = wds.SePet.New()
    self._dummyUnitEntity.ID = -99
    self._inExplorerFocus = false
    self._currentExploreZone = nil
    ---@type table<number, number>
    self._trackedExpeditions = {}
     ---@type table<number, boolean>
    self._waitSpawnerActive = {}
    ---@type wds.Expedition
    self._trackExpditionEntity = nil
    self._expeditionMarker = CitySeExpedtitionMarker.new(self)
end

function CitySeManager:OnBasicResourceLoadFinish()
    self._seMapInfoLua = self.city.seMapRoot.Instance
    self._seMapInfoLua:SetCity(self.city)
end

function CitySeManager:OnBasicResourceUnloadStart()
    if self._seMapInfoLua then
        self._seMapInfoLua:SetCity(nil)
    end
    self._seMapInfoLua = nil
end

function CitySeManager:NeedLoadData()
    return true
end

function CitySeManager:DoDataLoad()
    table.clear(self._heroIdConfig2CitizenConfigId)
    for _, value in ConfigRefer.Citizen:pairs() do
        self._heroIdConfig2CitizenConfigId[value:HeroId()] = value:Id()
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetDataChanged))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroEntityCreated))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroEntityDestroyed))
    self._seModleExtraScale = 1
    self._seModleExtraScale = ConfigRefer.ConstSe:CitySeExtraScale()
    if self._seModleExtraScale <= 0 then
        self._seModleExtraScale = 1
    end
    return self:DataLoadFinish()
end

function CitySeManager:DoDataUnload()
    table.clear(self._presetWanderingHeroes)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetDataChanged))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroEntityCreated))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroEntityDestroyed))
end

function CitySeManager:OnViewLoadStart()
    if self._seEnvironment then return end
    self._seEnvironment = SEEnvironment.Instance(true)
    self._seEnvinited = false
    self.city.seMediator:SetSeEnvironment(self._seEnvironment)
end

function CitySeManager:OnCameraLoaded()
    self.city.seFloatingTextMgr.MainCamera = self.city.camera:GetUnityCamera()
end

function CitySeManager:OnViewLoadFinish()
    self:DoTryLoadSeEnvironment()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTicker))
end

function CitySeManager:OnViewUnloadStart()
    table.clear(self._pendingCreateHeroes)
    table.clear(self._presetWanderingHeroes)
    table.clear(self._markIsExplorerModeEndTeleport)
    for heroId, unit in pairs(self._createdWanderingSeHeroes) do
        unit:Dispose()
        self._createdWanderingSeHeroes[heroId] = nil
    end
    self._presetHeroPetLink:Dispose()
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTicker))
    self:CleanupSeEnvironment()
end

function CitySeManager:OnCityActive()
    self:DoTryLoadSeEnvironment()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self._inputWrapper, self._inputWrapper.Tick))
    self:OnPresetDataChanged()
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_CLICK, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopClick))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_BEGIN, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragBegin))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_UPDATE, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_END, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_CANCEL, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragCancel))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionCreate))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionDestroy))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Expedition.ExpeditionInfo.SpawnerId.MsgPath, Delegate.GetOrCreate(self, self.OnExpeditionChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchEvt))
end

function CitySeManager:OnCityInactive()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_CLICK, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopClick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_BEGIN, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragBegin))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_UPDATE, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_END, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragEnd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_CANCEL, Delegate.GetOrCreate(self, self.OnCityOrderExplorerSlgTroopDragCancel))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionCreate))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Expedition, Delegate.GetOrCreate(self, self.OnExpeditionDestroy))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Expedition.ExpeditionInfo.SpawnerId.MsgPath, Delegate.GetOrCreate(self, self.OnExpeditionChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchEvt))
    table.clear(self._pendingCreateHeroes)
    table.clear(self._presetWanderingHeroes)
    table.clear(self._markIsExplorerModeEndTeleport)
    for heroId, unit in pairs(self._createdWanderingSeHeroes) do
        unit:Dispose()
        self._createdWanderingSeHeroes[heroId] = nil
    end
    self._presetHeroPetLink:Dispose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self._inputWrapper, self._inputWrapper.Tick))
    self:DisposeDragLine()
end

function CitySeManager:DoTryLoadSeEnvironment()
    if not self.city.camera or not self.city.showed then
        return
    end
    if self._seEnvinited then return end
    self._seEnvinited = true
    if not self._seEnvironment then
        self._seEnvironment = SEEnvironment.Instance(true)
    end
    local unityCamera = self.city.camera:GetUnityCamera()
    ---@type CS.SEForCityMapInfo
    local seMapInfo = SEMapInfo.GetInstance(self._cityFixedSeId)
    seMapInfo:SetMainCamera(unityCamera)
    seMapInfo:SetVirtualCamera(self.city.camera.virtualCamera)
    seMapInfo:SetVirtualCameraAlt({self.city.camera.virtualCamera, self.city.camera.virtualCamera})
    SESceneRoot.SetSceneRoot(seMapInfo:GetMapRoot())
    SESceneRoot.SetClientScale(self.city.scale)
    SESceneRoot.SetCameraRotation(self.city.camera.mainTransform.eulerAngles.y)
    SESceneRoot.SetSceneWayPointYOffset(self.city.scale * 0.1)
    self._seEnvironment:Init(self._cityFixedSeId, g_Game.UIManager:GetUICamera(), unityCamera, seMapInfo, nil, SEEnvironmentModeType.CityScene)
    self._seEnvironment._citySeMode = true
    self._seEnvironment._inputManager:SetInputWrapper(self._inputWrapper)
    self._seEnvironment._inputManager:SetOverrideGroundProvider(Delegate.GetOrCreate(self, self.GroundClickProvider))
    ---在非se战斗过程中 使用探索小队直接调用move 指令 不使用se自己内置的点击移动
    self._seEnvironment:SetAllowClickMove(false)
end

---@param ray CS.UnityEngine.Ray
---@return boolean, CS.UnityEngine.Vector3
function CitySeManager:GroundClickProvider(ray)
    ---@type boolean
	local result
	---@type CS.UnityEngine.Vector3
	local point
	-- Click move
	result, point = CS.RaycastHelper.PhysicsRaycastRayHitWithMask(ray, 512, LAYER_MASK_CITY_STATIC)
	if result then
        local pathFinding = self.city.cityPathFinding
        local hitPosition = pathFinding:NearestWalkableOnGraph(point, pathFinding.AreaMask.CityGround)
        if hitPosition then
            return true, hitPosition
        end
	end
    return false, nil
end

function CitySeManager:CleanupSeEnvironment()
    if not self._seEnvironment then return end
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CitySeExplorerHudUIMediator)
    self._seEnvinited = false
    self.city.seMediator:SetSeEnvironment(nil)
    self._seEnvironment._inputManager:SetOverrideGroundProvider(nil)
    local unitMgr = self._seEnvironment:GetUnitManager()
    if unitMgr and unitMgr:GetUnit(self._dummyUnitEntity.ID) then
        unitMgr:DestroyUnit(self._dummyUnitEntity)
    end
    self._seEnvironment:Dispose()
    self._seEnvironment = nil
end

function CitySeManager:SetSeCaptainClickMove(worldPos, presetIndex)
    if not self._seEnvironment then return end
    if self.city.cityExplorerManager:HasInProgressOpenTreasure() then return end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    if not team or team:IsInBattle() or team:InInteractState() then return end
    self._seEnvironment._inputManager:MoveToWorldPos(worldPos, presetIndex)
    return true
end

function CitySeManager:Tick(_)
    if self.city.cityPathFinding:IsNavMeshReady() then
        local onTickAddLimit = 3
        for heroId, initParam in pairs(self._pendingCreateHeroes) do
            self:SpawnOne(heroId, initParam)
            onTickAddLimit = onTickAddLimit - 1
            if onTickAddLimit <= 0 then
                break
            end
        end
        onTickAddLimit = 3
        -- repeat
        --     local presetIndex, petId, heroEntityId = self._presetHeroPetLink:PopOneInPending()
        --     if not presetIndex or not petId or not heroEntityId then
        --         break
        --     end
        --     self:SpawnOnePet(presetIndex, petId, heroEntityId)
        --     onTickAddLimit = onTickAddLimit - 1
        -- until onTickAddLimit <= 0
    end
end

function CitySeManager:IgnoreInvervalTicker(dt)
    self._moveManager:Tick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, unit in pairs(self._createdWanderingSeHeroes) do
        unit:Tick(dt, nowTime)
    end
    self._presetHeroPetLink:Tick(dt, nowTime)
end

function CitySeManager:OnPresetDataChanged()
    table.clear(self._presetWanderingHeroes)
    self._presetHeroPetLink:ResetAllHeroAndPetLink()
    local city = self.city
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local allPreset = city:GetCastleBrief().TroopPresets.Presets
    ---@type table<number, boolean>
    local seCreatedHeroes = {}
    ---@type table<number, number>
    local seLinkedPets = {}
    if allPreset then
        local count = #allPreset
        for i = 1, count do
            local p = allPreset[i]
            if p.Status == wds.TroopPresetStatus.TroopPresetInHome or p.Status == wds.TroopPresetStatus.TroopPresetIdle then
                local persetIndex = i - 1
                for indexInList, value in ipairs(p.Heroes) do
                    self._presetWanderingHeroes[value.HeroCfgID] = true
                    if value.PetCompId ~= 0 then
                        self._presetHeroPetLink:AddHeroPetLink(persetIndex, value.HeroCfgID, value.PetCompId, indexInList)
                    end
                end
            end
        end
    end
    ---@type table<number, wds.Hero>
    local allCreatedHeroes = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Hero)
    for _, value in pairs(allCreatedHeroes) do
        if value.Owner.PlayerID == myPlayerId then
            seCreatedHeroes[value.BasicInfo.ConfID] = true
            local petId = self._presetHeroPetLink:HeroId2PetId(value.BasicInfo.PresetIndex, value.BasicInfo.ConfID)
            if petId then
                seLinkedPets[petId] = value.ID
            end
        end
    end
    for heroId, _ in pairs(self._pendingCreateHeroes) do
        if not self._presetWanderingHeroes[heroId] or seCreatedHeroes[heroId] then
            self._pendingCreateHeroes[heroId] = nil
            self._markIsExplorerModeEndTeleport[heroId] = nil
        end
    end
    for heroId, unit in pairs(self._createdWanderingSeHeroes) do
        if not self._presetWanderingHeroes[heroId] or seCreatedHeroes[heroId] then
            self._createdWanderingSeHeroes[heroId] = nil
            unit:Dispose()
        end
    end
    for heroId, _ in pairs(self._presetWanderingHeroes) do
        if not seCreatedHeroes[heroId] and not self._createdWanderingSeHeroes[heroId] then
            ---@type WanderingHeroesInitParam
            local initParam = {}
            self._pendingCreateHeroes[heroId] = initParam
        end
    end
    self._presetHeroPetLink:FilterNoLinkHeroPendingCreatePet()
    self._presetHeroPetLink:FilterNoHeroCreatedPet(seLinkedPets)
    self._presetHeroPetLink:FilterAddToPendingCreatePet(seLinkedPets)
end

---@param entity wds.Hero
function CitySeManager:OnSeHeroEntityCreated(_, entity)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    local presetIndex = entity.BasicInfo.PresetIndex
    local heroId = entity.BasicInfo.ConfID
    local unit = self._createdWanderingSeHeroes[heroId]
    if unit then
        unit:Dispose()
    end
    self._createdWanderingSeHeroes[heroId] = nil
    self._pendingCreateHeroes[heroId] = nil
    self._markIsExplorerModeEndTeleport[heroId] = nil
    local petId = self._presetHeroPetLink:HeroId2PetId(presetIndex, heroId)
    if not petId then return end
    local petUnit = self._presetHeroPetLink:GetCreatedPet(presetIndex, petId)
    if petUnit then return end
    self._presetHeroPetLink:AddToPendingCreatePet(presetIndex, petId, entity.ID)
end

---@param entity wds.Hero
function CitySeManager:OnSeHeroEntityDestroyed(_, entity)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    local presetIndex = entity.BasicInfo.PresetIndex
    local heroId = entity.BasicInfo.ConfID
    local petId = self._presetHeroPetLink:RemoveCreatedPeByHeroId(presetIndex, heroId)
    if petId then
        self._presetHeroPetLink:RemoveFromPendingCreatePet(presetIndex, petId)
    end
    if self._createdWanderingSeHeroes[heroId] then return end
    ---@type WanderingHeroesInitParam
    local initParam = {}
    initParam.fromDir = entity.MapBasics.Direction
    initParam.fromPos = entity.MapBasics.Position
    if self._pendingCreateHeroes[heroId] then
        self._pendingCreateHeroes[heroId] = initParam
        return
    end
    if not self._presetWanderingHeroes[heroId] then return end
    self._pendingCreateHeroes[heroId] = initParam
end

---@param heroId number
---@param initParam WanderingHeroesInitParam
function CitySeManager:SpawnOne(heroId, initParam)
    self._pendingCreateHeroes[heroId] = nil
    local actAsTeleportSafeAreaId = self._markIsExplorerModeEndTeleport[heroId]
    if actAsTeleportSafeAreaId then
        initParam = {}
        local has, v2 = self.city.safeAreaWallController:RandomInSafeAreaGrid(actAsTeleportSafeAreaId, self.city:GetSafeAreaSliceDataUsage())
        if has then
            initParam.fromPos = wds.Vector3F.New(v2.x, v2.y, 0)
        end
    elseif not initParam.fromPos then
        local id, _, _ = self.city.safeAreaWallMgr:GetBiggestIdSafeAreaIdCenter()
        if id then
            local has, v2 = self.city.safeAreaWallController:RandomInSafeAreaGrid(id, self.city:GetSafeAreaSliceDataUsage())
            if has then
                initParam.fromPos = wds.Vector3F.New(v2.x, v2.y, 0)
            end
        end
    end
    self._markIsExplorerModeEndTeleport[heroId] = nil
    local config = ConfigRefer.Heroes:Find(heroId)
    if not config then return end
    local seNpcConfig = ConfigRefer.SeNpc:Find(config:SeNpcCfgId())
    if not seNpcConfig then return end
    local cityConfig = ConfigRefer.CityConfig
    local asset,scale = self:GetSeModel(seNpcConfig)
    local extraScale =  ConfigRefer.ConstSe:CitySeExtraScale()
    if extraScale <= 0 then
        extraScale = 1
    end
    scale = scale * extraScale
    local walkSpeed = UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedWalk())
    local runSpeed = UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedRun())
    local unitConfig = UnitCitizenConfigWrapper.new(asset,walkSpeed , runSpeed, scale)
    ---@type CityUnitExplorer
    local unit = UnitActorFactory.CreateOne(UnitActorType.CITY_EXPLORER)
    self._createdWanderingSeHeroes[heroId] = unit
    local initPos = nil
    local initDir = nil
    if initParam.fromPos then
        initPos = self.city:GetWorldPositionFromCoord(initParam.fromPos.X, initParam.fromPos.Y)
        initPos = self.city.cityPathFinding:NearestWalkableOnGraph(initPos, self.city.cityPathFinding.AreaMask.CityGround)
    end
    if initParam.fromDir then
        initDir = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(initParam.fromDir.X, 0, initParam.fromDir.Y))
    end
    local agent = self._moveManager:Create(unit.id, initPos, initDir or CS.UnityEngine.Quaternion.identity, walkSpeed)
    local pathHeightFixer = Delegate.GetOrCreate(self.city, self.city.FixHeightWorldPosition)
    unit:Init(heroId, asset, self._goCreator, agent, unitConfig , self.city.cityPathFinding, pathHeightFixer, self)
    unit:LoadModelAsync(self.city.CityExploreRoot)
    unit:AttachMoveGridListener(self.city.unitMoveGridEventProvider)
    if actAsTeleportSafeAreaId then
        unit:PlayTeleportBornVfx()
    end
end

---@param heroEntity wds.Hero
---@return CS.UnityEngine.Vector3, CS.UnityEngine.Quaternion
function CitySeManager:GetPetSpawnPosAndDir(heroEntity)
    local heroPos = heroEntity.MapBasics.Position
    local heroDir = heroEntity.MapBasics.Direction
    local pos = self.city:GetWorldPositionFromCoord(heroPos.X, heroPos.Y)
    local dir = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(heroDir.X, 0, heroDir.Y))
    pos = CityExplorerTeamDefine.CalculatePetFollowUnitPosition(pos, dir)
    local pathFinding = self.city.cityPathFinding
    pos = pathFinding:NearestWalkableOnGraph(pos, pathFinding.AreaMask.CityGround)
    return pos, dir
end

function CitySeManager:SpawnOnePet(presetIndex, petId, heroEntityId)
    ---@type wds.Hero
    local heroEntity = g_Game.DatabaseManager:GetEntity(heroEntityId, DBEntityType.Hero)
    if not heroEntity then return end
    local petData = ModuleRefer.PetModule:GetPetByID(petId)
    if not petData then return end
    local petConfig = ConfigRefer.Pet:Find(petData.ConfigId)
    if not petConfig then return end
    local seNpcConfig = ConfigRefer.SeNpc:Find(petConfig:SeNpcId())
    if not seNpcConfig then return end
    local cityConfig = ConfigRefer.CityConfig
    local asset,scale = self:GetSeModel(seNpcConfig)
    scale = scale * self._seModleExtraScale
    local walkSpeed = UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedWalk())
    local runSpeed = UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedRun())
    local unitConfig = UnitCitizenConfigWrapper.new(asset,walkSpeed , runSpeed, scale)
    local pos,dir =  self:GetPetSpawnPosAndDir(heroEntity)
    ---@type CityUnitExplorerPet
    local unit = UnitActorFactory.CreateOne(UnitActorType.CITY_SE_FOLLOW_HERO_PET)
    local agent = self._moveManager:Create(unit.id, pos, dir, walkSpeed)
    local pathHeightFixer = Delegate.GetOrCreate(self.city, self.city.FixHeightWorldPosition)
    unit:Init(petId, asset, self._goCreator, agent, unitConfig , self.city.cityPathFinding, pathHeightFixer, self, heroEntity, seNpcConfig:Id())
    unit:LoadModelAsync(self.city.CityExploreRoot)
    self._presetHeroPetLink:PetCreated(presetIndex, petId, unit)
end

local PERFORMANCE_LEVEL_LOW_THRESHOLD = CS.DragonReborn.Performance.DeviceLevel.High:GetHashCode()

---@param seNpcConfig SeNpcConfigCell
function CitySeManager:GetSeModel(seNpcConfig)
    local model,scale = ArtResourceUtils.GetItemAndScale(seNpcConfig:Model())
	local modelLow,scaleLow = ArtResourceUtils.GetItemAndScale(seNpcConfig:LowerModel())
	local deviceLevel = g_Game.PerformanceLevelManager:GetDeviceLevel():GetHashCode()
	if (modelLow and deviceLevel < PERFORMANCE_LEVEL_LOW_THRESHOLD) then
		return modelLow, scaleLow or 1
	end
    return (model or ""),(scale or 1)
end

---@return boolean, number
function CitySeManager:IsInResCollectWork(presetIndex)
    return self._presetHeroPetLink:IsInExplorerCollectResource(presetIndex)
end

---@return CitySeExplorerPetsLogicDefine.SetWorkResult, number|nil
function CitySeManager:SetSeExplorerCollectResource(presetIndex, tileId)
    return self._presetHeroPetLink:SetSeExplorerCollectResource(presetIndex, tileId)
end

function CitySeManager:ExitInExplorerMode(lockable, markTeleportToSafeAreaId)
    if not self.city:IsInSingleSeExplorerMode() then
        return false
    end
    ---@type CityStateSeExplorerFocus
    local state = self.city.stateMachine:GetCurrentState()
    local presetIndex = state:GetCurrentPresetIndex()
    if not presetIndex then return false end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    if team then
        for _, seHero in pairs(team._assignSEHeros) do
            self._markIsExplorerModeEndTeleport[seHero:GetHeroConfigId()] = markTeleportToSafeAreaId
        end
    end
    return self.city.cityExplorerManager:ExitInExplorerMode(lockable)
end

---@return CS.UnityEngine.Vector3|nil,number|nil
function CitySeManager:GetEnterCityCameraFocuOnExplorerPosAndSize()
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    ---@type table<number, wds.ScenePlayer>
    local scenePlayers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    if not scenePlayers then return nil, nil end
    for _, scenePlayer in pairs(scenePlayers) do
        if scenePlayer.Owner.PlayerID == myPlayerId then
            local explor,_ = CityStateHelper.GetScenePlayerInExplorerAndinFocusPreset(scenePlayer)
            if not explor then
                break
            end
            local heroPos = self:GetCaptainHeroPos(scenePlayer, explor.PresetIndex)
            if heroPos then
                break
            end
            return heroPos, CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE
        end
    end
    return nil, nil
end

---@param scenePlayer wds.ScenePlayer
---@param presetIndex number
function CitySeManager:GetCaptainHeroPos(scenePlayer, presetIndex)
    local scenePlayerHero = scenePlayer.ScenePlayerHero.Infos[presetIndex]
    if not scenePlayerHero then return nil end
    ---@type wds.Hero
    local hero = g_Game.DatabaseManager:GetEntity(scenePlayerHero.CaptainHeroEntityId, DBEntityType.Hero)
    if not hero then return nil end
    local serverLogicPos = hero.MapBasics.Position
    return self.city:GetWorldPositionFromCoord(serverLogicPos.X, serverLogicPos.Y)
end

---@param presetIndex number
---@param go CS.UnityEngine.GameObject
function CitySeManager:OnCityOrderExplorerSlgTroopClick(presetIndex, go)
    if self.city:IsInSingleSeExplorerMode() or self.city:IsInSeBattleMode() then return end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex - 1)
    if not team then return end
end

---@param presetIndex number
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CitySeManager:OnCityOrderExplorerSlgTroopDragBegin(presetIndex, go, event)
    if self.city:IsInSingleSeExplorerMode() or self.city:IsInSeBattleMode() then return end
    self.selectPresetIndex = presetIndex
    self:BlockCamera()
end

---@param presetIndex number
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CitySeManager:OnCityOrderExplorerSlgTroopDragUpdate(presetIndex, go, event)
    if self.city:IsInSingleSeExplorerMode() or self.city:IsInSeBattleMode() then return end
    local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    -- self:TryDragToPos(team, event.position)
end

---@param presetIndex number
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CitySeManager:OnCityOrderExplorerSlgTroopDragEnd(presetIndex, go, event)
    self:OnDragEndMoveTroop(event.position)
    if self.city:IsInSingleSeExplorerMode() or self.city:IsInSeBattleMode() then return end
    -- local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    -- if not team then return end
    self:RecoverCamera()
end

---@param presetIndex number
---@param go CS.UnityEngine.GameObject
function CitySeManager:OnCityOrderExplorerSlgTroopDragCancel(presetIndex, go)
    g_Logger.Log("OnCityOrderExplorerSlgTroopDragCancel:%s,%s", presetIndex, go)
    if self.city:IsInSingleSeExplorerMode() or self.city:IsInSeBattleMode() then return end
    -- local team = self.city.cityExplorerManager:GetTeamByPresetIndex(presetIndex)
    -- if not team then return
    self:DisposeDragLine()
    self:RecoverCamera()
end

---@param heroes table<number, SEHero>
---@return SEHero|nil
function CitySeManager:GetFocusOnHeroInTeam(heroes, presetIndex)
    if not heroes then return nil end
    local longRangeHero = nil
    local longRangeHeroIndex = nil
    local shortRangeHero = nil
    local shortRangeHeroIndex = nil
    for _, seHero in pairs(heroes) do
        local heroPresetIndex = seHero:GetHeroPresetIndex()
        if heroPresetIndex ~= presetIndex then
            goto continue
        end
        local heroId = seHero:GetHeroConfigId()
        local category = seHero:GetData():GetConfig():Category()
        local index = self._presetHeroPetLink:HeroId2IndexInList(presetIndex, heroId)
        if category == SEUnitCategory.HeroLongDis then
            if not longRangeHero then
                longRangeHero = seHero
                longRangeHeroIndex = index
            elseif index and (not longRangeHeroIndex or index < longRangeHeroIndex)  then
                longRangeHero = seHero
                longRangeHeroIndex = index
            end
        else
            if not shortRangeHero then
                shortRangeHero = seHero
                shortRangeHeroIndex = index
            elseif index and (not shortRangeHeroIndex or index < shortRangeHeroIndex)  then
                shortRangeHero = seHero
                shortRangeHeroIndex = index
            end
        end
        ::continue::
    end
    if not longRangeHero then return shortRangeHero end
    return longRangeHero
end

---@return SEHero|nil
function CitySeManager:GetCurrentCameraFocusOnHero(presetIndex)
    if not self.city:IsInSingleSeExplorerMode() and not self.city:IsInSeBattleMode() then return nil end
    if not self._seEnvironment then return nil end
    local unitMgr = self._seEnvironment:GetUnitManager()
    if not unitMgr then return nil end
    local heroes = unitMgr:GetHeroList()
    return self:GetFocusOnHeroInTeam(heroes, presetIndex)
end

function CitySeManager:HomeSeTroopRecoverHp(presetIndex, lockTrans)
    local sendCmd = HomeSeTroopRecoverHpParameter.new()
    sendCmd.args.PresetIndex = presetIndex
    sendCmd:SendOnceCallback(lockTrans)
end

---@return SEDummy
function CitySeManager:GetOrCreateDummyUnitOnGridPos(gridX, gridY)
    local unitMgr = self._seEnvironment:GetUnitManager()
    local dummyUnit = unitMgr:GetDummyUnit(-99)
    if not dummyUnit then
        self._dummyUnitEntity.MapBasics.Position = wds.Vector3F(gridX, gridY, 0)
        unitMgr:CreateDummyUnit(self._dummyUnitEntity)
        dummyUnit = unitMgr:GetDummyUnit(-99)
    else
        self._dummyUnitEntity.MapBasics.Position = wds.Vector3F(gridX, gridY, 0)
    end
    dummyUnit:SyncGoPosFromEntityPos()
    return dummyUnit
end

function CitySeManager:EnterExplorerFocus(currentExploreZone)
    self.city:SeExploreZoneChanged(currentExploreZone)
    self._inExplorerFocus = true
    self._currentExploreZone = currentExploreZone
    self._expeditionMarker:Setup(currentExploreZone)
    self._expeditionMarker:SetNeedShow(true)
    self:FindExpeditionToMark()
    if self._seEnvironment then
        self._seEnvironment:SetCityModeInExploring(true)
    end
end

function CitySeManager:ExitExplorerFocus()
    self._inExplorerFocus = false
    self._expeditionMarker:ClearStack()
    table.clear(self._trackedExpeditions)
    self._expeditionMarker:SetNeedShow(false)
    self.city:SeExploreZoneChanged(nil)
    if self._seEnvironment then
        self._seEnvironment:SetCityModeInExploring(false)
    end
end

function CitySeManager:UpdateCurrentExploreZone(zoneId)
    if not self._inExplorerFocus then return end
    if self._currentExploreZone == zoneId then return end
    self.city:SeExploreZoneChanged(zoneId)
    self._currentExploreZone = zoneId
    self._expeditionMarker:FilterCurrentStack(zoneId)
end

---@param entity wds.Expedition
function CitySeManager:OnExpeditionCreate(typeId, entity)
    if not self._inExplorerFocus then return end
    if entity.ExpeditionInfo.SpawnerId == 0 then return end
    if self._trackedExpeditions[entity.ID] then return end
    local spawnerId = entity.ExpeditionInfo.SpawnerId
    self._trackedExpeditions[entity.ID] = spawnerId
    if not self.city.elementManager:IsSpawnerActived(spawnerId) then
        self._waitSpawnerActive[spawnerId] = true
        return
    end
    self._expeditionMarker:PushElementId(spawnerId)
end

---@param entity wds.Expedition
function CitySeManager:OnExpeditionDestroy(typeId, entity)
    if not self._inExplorerFocus then return end
    local spawnerId = self._trackedExpeditions[entity.ID]
    self._trackedExpeditions[entity.ID] = nil
    if not spawnerId then return end
    self._waitSpawnerActive[spawnerId] = nil
    self._expeditionMarker:PopElementId(spawnerId)
end

---@param entity wds.Expedition
function CitySeManager:OnExpeditionChanged(entity, _)
    if not self._inExplorerFocus then return end
    local spawnerId = self._trackedExpeditions[entity.ID]
    local nowSpawnerId = entity.ExpeditionInfo.SpawnerId
    if spawnerId == nowSpawnerId then return end
    self._trackedExpeditions[entity.ID] = nil
    if spawnerId then
        self._waitSpawnerActive[spawnerId] = nil
        self._expeditionMarker:PopElementId(spawnerId)
    end
    if nowSpawnerId == 0 then return end
    self._trackedExpeditions[entity.ID] = nowSpawnerId
    if not self.city.elementManager:IsSpawnerActived(nowSpawnerId) then
        self._waitSpawnerActive[nowSpawnerId] = true
        return
    end
    self._expeditionMarker:PushElementId(nowSpawnerId)
end

function CitySeManager:FindExpeditionToMark()
    self._trackExpditionEntity = nil
    ---@type table<number, wds.Expedition>
    local expeditions = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Expedition)
    if not expeditions then return end
    for _, value in pairs(expeditions) do
        self:OnExpeditionCreate(_, value)
    end
end

---@param evtInfo {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CitySeManager:OnCityElementBatchEvt(city, evtInfo)
    if not self._inExplorerFocus then return end
    if not city or city ~= self.city or not self.city:IsMyCity() or not evtInfo then
        return
    end
    local CityElementData = ConfigRefer.CityElementData
    if evtInfo.Remove then
        for id, v in pairs(evtInfo.Remove) do
            if v then
                local c = CityElementData:Find(id)
                local eleType = c and c:Type() or -1
                if eleType == CityElementType.Npc then
                    self._expeditionMarker:PopElementId(id)
                end
            end
        end
    end
    if evtInfo.Change then
        for id, v in pairs(evtInfo.Change) do
            if v then
                local c = CityElementData:Find(id)
                local eleType = c and c:Type() or -1
                if eleType == CityElementType.Spawner then
                    if self.city.elementManager:IsSpawnerActived(id) then
                        self._expeditionMarker:PushElementId(id)
                    else
                        self._expeditionMarker:PopElementId(id)
                    end
                end
            end
        end
    end
    if evtInfo.Add then
        for id, v in pairs(evtInfo.Add) do
            if v then
                local c = CityElementData:Find(id)
                local eleType = c and c:Type() or -1
                if eleType == CityElementType.Npc then
                    self._expeditionMarker:PushElementId(id)
                end
            end
        end
    end
end

function CitySeManager:GetExploreModeMarker()
    return self._expeditionMarker
end

function CitySeManager:TryDragToPos(team, screenPos)
    if not self._seEnvironment then
        self._seEnvironment = require('SEEnvironment').Instance()
    end
    local screenPos = CS.UnityEngine.Vector3(screenPos.x,screenPos.y,0)
    local endPos = self:ScreenPos2CityWorldPos(screenPos)

    --处理拖出地图边界的情况
    if not endPos then
        endPos = self.lastDragEndPos
    else
        self.lastDragEndPos = endPos
    end

    local startPos
    if team then
        startPos = team._teamTrigger._selectRing.transform.position
        self.troopStartCoorX = nil
        self.troopStartCoorY = nil
    else
        local coordX, coordY = self.city:GetCoordFromPosition(endPos)
        local doorX, doorY = self.city.cityExplorerManager:GetNearestSafeAreaWallDoorPos(coordX, coordY)
        if doorX == nil or doorY == nil then
            g_Logger.Error("没有找到安全门的位置")
            return
        end
        startPos = self.city:GetWorldPositionFromCoord(doorX,doorY)
        self.troopStartCoorX = doorX
        self.troopStartCoorY = doorY
    end

    if not self.dragVirtualCtrl then
        self.dragVirtualCtrl = ModuleRefer.SlgModule.selectManager:GetVirtualCtrl(startPos)
        self.dragVirtualCtrl:CreateTroopLine()
        self.dragVirtualCtrl:GetTroopLine().transform.localScale = CS.UnityEngine.Vector3.one * 0.007
    elseif self.dragStartPos ~= startPos then
        self.dragStartPos = startPos
        self.dragVirtualCtrl:SetPosition(startPos)
    else
        ModuleRefer.SlgModule.touchManager:UpdateTroopLine(self.dragVirtualCtrl,endPos,nil,true)
        ModuleRefer.SlgModule.touchManager.uiTroopDesTip:SetTargetEntity(self.dragVirtualCtrl,nil,false)
    end
end

function CitySeManager:OnDragEndMoveTroop()
    if self.dragVirtualCtrl and self.selectPresetIndex then
        if self.lastDragEndPos == nil then
            return
        end

        local pos = self.lastDragEndPos
        if self.troopStartCoorX and self.troopStartCoorY then
            local presetIndex = self.selectPresetIndex
            self.city.cityExplorerManager:CreateHomeSeTroop(self.selectPresetIndex, self.troopStartCoorX, self.troopStartCoorY,true,nil,function()
                self:MoveToWorldPos(pos, presetIndex)
                g_Game.TroopViewManager:CreateVfxExtend(SLGConst_Manual.troopBornVfxInCity,self.dragStartPos,CS.UnityEngine.Vector3.forward,0.4,2,1)
            end)
        else
            self:MoveToWorldPos(pos, self.selectPresetIndex)
        end
        self:DisposeDragLine()
    end
end

function CitySeManager:DisposeDragLine()
    if self.dragVirtualCtrl then
        self.dragVirtualCtrl:ReleaseTroopLine()
        ModuleRefer.SlgModule.touchManager:DespawnTroopLineAddObj()
        self.dragVirtualCtrl = nil
        self.selectPresetIndex = nil
        self.lastDragEndPos = nil
    end
end

---@param screenPos CS.UnityEngine.Vector3
---@return pos CS.UnityEngine.Vector3
function CitySeManager:ScreenPos2CityWorldPos(screenPos)
    local ray = self._seEnvironment:GetCamera():ScreenPointToRay(screenPos)
    local hit,pos = self:GroundClickProvider(ray)
    return  pos
end

--- 移动到世界坐标
---@param self SEInputManager
---@param worldPos CS.UnityEngine.Vector3
function CitySeManager:MoveToWorldPos(worldPos, presetIndex, logicPos)
	local mapInfo = self._seEnvironment:GetMapInfo()
	if Utils.IsNull(mapInfo) then
		g_Logger.Error("MoveToWorldPos ignored because nil mapInfo")
		return
	end
    if logicPos == nil then
        logicPos = mapInfo:ClientPos2Server(worldPos)
    end
    local msg = require("MoveStepParameter").new()
    msg.args.TargetEntityId = 0
    msg.args.Force = false
    msg.args.DestPoint.X = logicPos.x
    msg.args.DestPoint.Y = logicPos.y
    msg.args.DestPoint.Z = logicPos.z
    if presetIndex then
        msg.args.PresetIndex = presetIndex
    else
        msg.args.PresetIndex = (self._seEnvironment:GetCurrentFocusPresetIndex() or self._seEnvironment:GetFallbackPresetIndex())
    end
    msg:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            -- ModuleRefer.ToastModule:AddSimpleToast("#部队已出征")
        end
    end,Delegate.GetOrCreate(self, self.OnMoveToWorldPosErrorFilter))
end

function CitySeManager:OnMoveToWorldPosErrorFilter(msgId, errorCode)
	if errorCode == 30041 or errorCode == 30048 then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errcode_pos_unattainable"))
		return true
	end
end

function CitySeManager:BlockCamera()
    local camera = self.city:GetCamera()
    if camera ~= nil then
        camera.enableDragging = false
    end
end

function CitySeManager:RecoverCamera()
    local camera = self.city:GetCamera()
    if camera then
        camera.enableDragging = true
    end
end

---@param viewPortPos CS.UnityEngine.Vector3|nil @screenPos
---@param cameraSize number|nil @default CityConst.CITY_RECOMMEND_CAMERA_SIZE
---@param cameraMoveSpeed number|nil @default BasicCamera DEFAULT_MOVE_SPEED
---@param onMoveEndCallback fun(success:boolean)
---@return boolean
function CitySeManager:FocusOnWanderingHero(heroConfigId, viewPortPos, cameraSize ,cameraMoveSpeed ,onMoveEndCallback)
    local unit = self._createdWanderingSeHeroes[heroConfigId]
    if not unit then
        if onMoveEndCallback then onMoveEndCallback(false) end
        return false
    end
    local worldPos = unit._moveAgent._currentPosition
    if not worldPos then
        if onMoveEndCallback then onMoveEndCallback(false) end
        return false
    end
    viewPortPos = viewPortPos or CS.UnityEngine.Vector3(0.5, 0.5, 0.0)
    self.city.camera:ForceGiveUpTween()
    cameraSize = cameraSize or CityConst.CITY_RECOMMEND_CAMERA_SIZE
    self.city.camera:ZoomToWithFocusBySpeed(cameraSize, viewPortPos, worldPos, cameraMoveSpeed, function()
        if onMoveEndCallback then onMoveEndCallback(true) end
    end)
    return true
end

function CitySeManager:GetWanderingHero(heroConfigId)
    local unit = self._createdWanderingSeHeroes[heroConfigId]
    return unit
end

function CitySeManager:GetWanderingHeroTransform(heroConfigId)
    local unit = self._createdWanderingSeHeroes[heroConfigId]
    if unit then
        return unit:GetTransform()
    end
    return nil
end

return CitySeManager