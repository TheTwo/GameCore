local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Utils = require('Utils')
local KingdomConstant = require("KingdomConstant")
local GotoUtils = require("GotoUtils")
local MapFoundation = require("MapFoundation")
local OnChangeHelper = require("OnChangeHelper")
local MapFogCircles = require("MapFogCircles")
local CircleMaskType = require("CircleMaskType")
local ManualResourceConst = require("ManualResourceConst")
local MapFogDefine = require("MapFogDefine")
local Layers = require("Layers")
local LayerMask = require("LayerMask")
local MapConfigCache = require("MapConfigCache")

local MapFogSystem = CS.Kingdom.MapFogSystem
local MapUtils = CS.Grid.MapUtils
local Color32 = CS.UnityEngine.Color32
local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short
local ListInt32 = CS.System.Collections.Generic.List(typeof(CS.System.Int32))

---@class MapFogModule : BaseModule
---@field staticMapData CS.Grid.StaticMapData
---@field fogSystem CS.Kingdom.MapFogSystem
---@field fogCircles MapFogCircles
---@field settings CS.Kingdom.MapFogSettings
---@field isDirty boolean
---@field needRefresh boolean
---@field mistsPerMapX number
---@field mistsPerMapZ number
---@field currentMistID number
---@field allUnlocked boolean
---@field manualUnlock boolean
---@field singleUnlock boolean
---@field isPlayingMultiUnlockEffect boolean
---@field unlockEffectHandle CS.DragonReborn.AssetTool.PooledGameObjectHandle
---@field circleMasks table<number, table<number, CircleMask>>
---@field mistTempCache CS.System.Collections.Generic.List(typeof(CS.System.Int32))
local MapFogModule = class("MapFogModule", BaseModule)
local initColor = Color32(0, 0, 0, 0)
local unlockedColor = Color32(255, 255, 0, 0)
local selectedColor = Color32(0, 0, 255, 0)
local dissolvingUnlockColor = Color32(255, 0, 0, 255)
local dissolvingLockColor = Color32(0, 255, 0, 255)

local MASK_SIZE = 512

local MaxUnlockCount = 10

function MapFogModule:OnRegister()
    self.mistTempCache = ListInt32()
    self.fogSystem = MapFogSystem()
    self.fogCircles = MapFogCircles.new()
    self.circleMasks = {}
    self.grid = {}
    self.unlockEffectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle(require("PoolUsage").Map)
end

function MapFogModule:OnRemove()
    self.fogSystem = nil
    self.fogCircles = nil
    self.circleMasks = nil
    self.grid = nil
end

function MapFogModule:Setup()
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.tilesPerBlockX = self.staticMapData.TilesPerBlockX
    self.tilesPerBlockZ = self.staticMapData.TilesPerBlockZ
    self.blocksPerMapX = self.staticMapData.BlocksPerMapX
    self.blocksPerMapZ = self.staticMapData.BlocksPerMapZ
    self.unitsPerBlockX = self.staticMapData.UnitsPerBlockX
    self.unitsPerBlockZ = self.staticMapData.UnitsPerBlockZ
    self.unitsPerTileX = self.staticMapData.UnitsPerTileX
    self.unitsPerTileZ = self.staticMapData.UnitsPerTileZ
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapFogSettings))
    local camera = KingdomMapUtils.GetBasicCamera().mainCamera
    local mapSystem = KingdomMapUtils.GetMapSystem()
    self.fogSystem:Initialize(MASK_SIZE, mapSystem, camera, self.settings, MapFoundation.HideObject)
    self.fogSystem:SetPalette(initColor, unlockedColor, selectedColor, dissolvingUnlockColor, dissolvingLockColor)
    self.fogSystem:CreateOuterBorderMaskMesh()

    self.fogCircles:Initialize(self)
    
    self.mistsPerMapX, self.mistsPerMapZ = self.fogSystem:GetMistCounts()
    
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
    
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.MistInfo.UnlockInfo.MsgPath, Delegate.GetOrCreate(self, self.OnMistUnlockInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MistTasks.MsgPath, Delegate.GetOrCreate(self, self.OnMistTaskChanged))

    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, Delegate.GetOrCreate(self, self.OnKingdomTransition))

    self:OnMistUnlockInfoChanged()

    self.isDirty = true
end

function MapFogModule:ShutDown()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
    
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.MistInfo.UnlockInfo.MsgPath, Delegate.GetOrCreate(self, self.OnMistUnlockInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MistTasks.MsgPath, Delegate.GetOrCreate(self, self.OnMistTaskChanged))

    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, Delegate.GetOrCreate(self, self.OnKingdomTransition))


    self:ResetState()

    self.fogCircles:Dispose()

    if self.fogSystem then
        self.fogSystem:ClearOuterBorderMaskMesh()
        self.fogSystem:Dispose()
    end
    self.staticMapData = nil

    self.unlockEffectHandle:Delete()
    
    self.settings = nil
end

function MapFogModule:ResetState()
    table.clear(self.circleMasks)
    table.clear(self.grid)

    self.isDirty = false
    self.needRefresh = false
    self.allUnlocked = false
    self.manualUnlock = false
    self.singleUnlock = false
    self.isPlayingMultiUnlockEffect = false

    self.currentMistID = nil
end

function MapFogModule:Tick(dt)
    if not KingdomMapUtils.IsMapState() then
        return
    end

    if self.fogSystem:Tick(dt) then
        self.isDirty = true
    end

    if not self.allUnlocked then
        local troopManager = ModuleRefer.SlgModule.troopManager
        if troopManager:IsAnyTroopMoving() then
            local myTroops, _ = troopManager:GetMyTroops()
            for _, troopInfo in pairs(myTroops) do
                if not troopInfo or not troopInfo.entityData then
					goto continue
                end
				
				local id = troopInfo.entityData.ID
				local ctrl = troopManager:FindTroopCtrl(id)
				if not ctrl then
					goto continue
				end
				
				local position = ctrl:GetPositionFloat3()
				self.fogSystem:SetGameObjectMaskPosition(id, position.x, position.z)
				
				::continue::
            end
            self.isDirty = true
        end
    end

    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem.CullUpdated or self.isDirty then
        self.isDirty = false
        self.fogSystem:Cull(mapSystem.RealCameraBox)
    end

    if self.needRefresh then
        mapSystem:RefreshUnits(0)
        self.needRefresh = false
    end
end

function MapFogModule:OnMistUnlockInfoChanged()
    local mistInfo = self:GetMistInfo()
    if not mistInfo then
        return
    end
    
    if mistInfo.UnlockInfo.IsAllUnlocked then
        self:SetAllUnlocked()
        self.isDirty = true
        return
    end
    
    local unlockedMistGroup = mistInfo.UnlockInfo.UnlockedMistGroupBitMap
    local unlockedInGroup = mistInfo.UnlockInfo.UnlockedInGroupBitMap
    self:RefreshUnlockData(unlockedMistGroup, unlockedInGroup)
end


function MapFogModule:RefreshUnlockData(unlockedMistGroup, unlockedInGroup)
    local cameraBox = KingdomMapUtils.GetMapSystem().CameraBox
    self.needRefresh = self.fogSystem:RefreshUnlockedData(cameraBox, unlockedMistGroup, unlockedInGroup, self.manualUnlock)
end


function MapFogModule:OnMistTaskChanged(entity, changeTable)
    if self.singleUnlock then
        local addMap, _, _ = OnChangeHelper.GenerateMapFieldChangeMap(changeTable)
        if addMap then
            local coords = {}
            local isCanToast = false
            local isCanToast_mistBox = false
            ---@param mistTaskInfo wds.MistTaskInfo
            for _, mistTaskInfo in pairs(addMap) do
                local coord = Vector2Short(KingdomMapUtils.ParseBuildingPos(mistTaskInfo.Pos))
                local radarCfg = ConfigRefer.RadarTask:Find(mistTaskInfo.RadarTaskId)
                if radarCfg then
                    if not radarCfg:IsSkipReward()  then
                        isCanToast = true
                    else
                        isCanToast_mistBox = true
                    end
                end
                if (coord.X ~= 0 or coord.Y ~= 0) then
                    table.insert(coords, coord)
                end
            end
            if #coords > 0 then
                local lod = KingdomMapUtils.GetLOD()
                local cameraZoomFunc = function() 
                    local size, position = KingdomMapUtils.CalculateCoordinatesToCameraSizeAndPosition(coords, KingdomMapUtils.GetBasicCamera().mainCamera, KingdomMapUtils.GetStaticMapData(), KingdomMapUtils.GetCameraLodData())
                    size = 1800
                    KingdomMapUtils.MoveAndZoomCamera(position, size)
                end
                if lod < KingdomConstant.HighLod then
                    cameraZoomFunc()
                else
                    g_Game.EventManager:TriggerEvent(EventConst.MIST_BOX_FOUND, {func = cameraZoomFunc})
                end
            end
            if isCanToast then
                ModuleRefer.ToastModule:AddJumpToast(I18N.Get("Radar_mist_new"))
            end
            if isCanToast_mistBox then
                ModuleRefer.ToastModule:AddJumpToast(I18N.Get("bw_radar_mist_newbox"))
            end
        end
    end
end

function MapFogModule:ExistCircleMask(circleType, id)
    local circles = self.circleMasks[circleType]
    if circles then
        return circles[id] ~= nil
    end
end

function MapFogModule:ClearAllCircleMask()
    for k, v in pairs(CircleMaskType) do
        self:ClearCircleMask(v)
    end
    self.needRefresh = true
end

---@param circleType number
function MapFogModule:ClearCircleMask(circleType)
    local circles = self.circleMasks[circleType]
    if circles then
        for id, circle in pairs(circles) do
            self.fogSystem:RemoveGameObjectMask(id)

            for i = 1, #circle.blockIndices do
                local cell = self:GetGridCell(circle.blockIndices[i])
                table.clear(cell)
            end
        end

        table.clear(circles)
        self.isDirty = true
        self.needRefresh = true
    end
end

function MapFogModule:AddCircleMask(id, circleType, x, z, radius)
    local circles = self.circleMasks[circleType]
    if not circles then
        circles = {}
        self.circleMasks[circleType] = circles
    end

    if not circles[id] then
        local position = MapUtils.CalculateCoordToWorldPosition(x, z, self.staticMapData)
        position.y = 10
        self.fogSystem:AddGameObjectMask(id, "mask_circle", position, 0, 2 * radius, Delegate.GetOrCreate(self, self.OnGameObjectMaskLoaded))
        
        ---@type CircleMask
        local circle = {}
        circle.id = id
        circle.type = circleType
        circle.x = x
        circle.y = z
        circle.radius = radius
        circle.blockIndices = {}
        circles[id] = circle
        self.needRefresh = true

        local sizeX = radius * self.unitsPerTileX
        local sizeZ = radius * self.unitsPerTileZ
        local rect = CS.UnityEngine.Rect.MinMaxRect(position.x - sizeX, position.z - sizeZ, position.x + sizeX, position.z + sizeZ)
        local xMin, yMin, xMax, yMax = MapUtils.CalculateRangeFromRect(rect, self.unitsPerBlockX, self.unitsPerBlockZ)
        for blockX = xMin, xMax do
            for blockZ = yMin, yMax do
                local blockIndex = blockZ * self.blocksPerMapX + blockX;
                table.insert(circle.blockIndices, blockIndex)
            end
        end
        
        for i = 1, #circle.blockIndices do
            local blockIndex = circle.blockIndices[i]
            local cell = self:GetGridCell(blockIndex)
            if not cell then
                cell = {}
                self.grid[blockIndex] = cell
            end
            cell[id] = circle
        end
    end
end

function MapFogModule:RemoveCircleMask(id, circleType)
    local circles = self.circleMasks[circleType]
    if circles then
        local circle = circles[id]
        if circle then
            self.fogSystem:RemoveGameObjectMask(id)
            circles[id] = nil

            for i = 1, #circle.blockIndices do
                local cell = self:GetGridCell(circle.blockIndices[i])
                cell[id] = nil
            end
            
            self.needRefresh = true
            self.isDirty = true
        end
    end
end

function MapFogModule:ShowCircleMaskOfType(circleType)
    local circles = self.circleMasks[circleType]
    if circles then
        self.fogSystem:SetMaskLayer(circles, Layers.MapMark)
    end
end

function MapFogModule:HideCircleMaskOfType(circleType)
    local circles = self.circleMasks[circleType]
    if circles then
        self.fogSystem:SetMaskLayer(circles, Layers.Default)
    end
end

function MapFogModule:GetGridCell(blockIndex)
    local cell = self.grid[blockIndex]
    return cell
end

function MapFogModule:OnGameObjectMaskLoaded(go)
    self.isDirty = true
end

function MapFogModule:OnCameraSizeChanged(oldSize, newSize)
    local cameraLodData = KingdomMapUtils.GetCameraLodData()
    if cameraLodData then
        local symbolSize = cameraLodData:GetSizeByLod(KingdomConstant.SymbolLod - 1)
        self:AdjustFogBlur(newSize, cameraLodData, symbolSize)
        self:AdjustPlaneFogEdgeNoise(newSize, symbolSize)
    end
end

function MapFogModule:OnCameraLodChanged(oldLod, newLod)
    self:AddCastlesCircleHighLod(oldLod, newLod)
end

function MapFogModule:OnKingdomTransition(oldLod, newLod)
    local change = KingdomMapUtils.LodSwitched(oldLod, newLod, KingdomConstant.SymbolLod)
    if change > 0 then
        self.fogSystem:SwitchFog(true)
    elseif change < 0 then
        self.fogSystem:SwitchFog(false)
    end
end

function MapFogModule:ShowPlaneFog()
    self.fogSystem:ShowPlaneFog()
end

function MapFogModule:HidePlaneFog()
    self.fogSystem:HidePlaneFog()
end

function MapFogModule:ShowHeightFog()
    self.fogSystem:ShowHeightFog()
end

function MapFogModule:HideHeightFog()
    self.fogSystem:HideHeightFog()
end

function MapFogModule:AddCastlesCircleHighLod(oldLod, newLod)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    
    local members = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    local change = KingdomMapUtils.LodSwitched(oldLod, newLod, KingdomConstant.SymbolLod)

    if change > 0 then
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        for _, member in pairs(members) do
            self:AddCircleMask(member.ID, CircleMaskType.Castle, member.BigWorldPosition.X, member.BigWorldPosition.Y, radius)
        end
    elseif change < 0 then
        for _, member in pairs(members) do
            self:RemoveCircleMask(member.ID, CircleMaskType.Castle)
        end
    end
    self.isDirty = true
end

function MapFogModule:AdjustFogBlur(cameraSize, cameraLodData, symbolSize)
    local minSize, maxSize, blurRadiusMin, blurRadiusMax, downScaling
    if cameraSize < symbolSize then
        blurRadiusMin = self.settings.BlurRadiusMin
        blurRadiusMax = self.settings.BlurRadiusMax
        downScaling = self.settings.BlurRTDownScalingMax
        minSize = cameraLodData:GetSizeByLod(KingdomConstant.KingdomLodMin - 1)
        maxSize = symbolSize
    else
        blurRadiusMin = self.settings.BlurRadiusSymbolMin
        blurRadiusMax = self.settings.BlurRadiusSymbolMax
        downScaling = self.settings.BlurRTDownScalingMin
        minSize = symbolSize
        maxSize = cameraLodData:GetSizeByLod(KingdomConstant.KingdomLodMax)
    end
   
    local t = math.clamp01((cameraSize - minSize) / (maxSize - minSize))
    local radius = blurRadiusMin * t + blurRadiusMax * (1 - t)
    --g_Logger.Log("cameraSize=%s, minsize=%s, maxsize=%s", cameraSize, minSize, maxSize)
    --g_Logger.Log("t=%s, radius=%s, downscale=%s", t, radius, downScaling)
    self.fogSystem:SetBlurRadius(radius)
    self.fogSystem:SetBlurDownScaling(downScaling)
    self.isDirty = true
end

function MapFogModule:AdjustPlaneFogEdgeNoise(cameraSize, symbolSize)
    if cameraSize > symbolSize then
        local strengthBase = self.settings.PlaneFogStrengthBase
        local strength = math.max(strengthBase / cameraSize * symbolSize, 0)
        self.fogSystem:SetPlaneFogParam(strength, -0.5 * strength)
        self.isDirty = true
    end
end

function MapFogModule:SetAllUnlocked()
    if not self.allUnlocked then
        local width = self.staticMapData.UnitsPerMapX
        local height = self.staticMapData.UnitsPerMapZ
        self:ResetState()
        self:ClearAllCircleMask()
        self.fogSystem:AddGameObjectMask(-1, "mask_all_unlocked", Vector3(width / 2, 0, height / 2), 0, math.max(width * 2, height * 2), Delegate.GetOrCreate(self, self.OnGameObjectMaskLoaded))
        self.allUnlocked = true
    end
end

function MapFogModule:UnlockSingleMist(mistID)
    if not mistID or not math.isinteger(mistID) then
        return
    end
    
    local itemCount = ModuleRefer.MapFogModule:GetUnlockItemCount()
    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    if itemCount < costPerMistCell then
        -- ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("Mist_tips_explorecondition", costPerMistCell))
        ModuleRefer.MapFogModule.UnlockItemGetMore()
        self:ResetSelectedMists()
        return
    end

    local UnlockMistNewParameter = require("UnlockMistNewParameter")
    local message = UnlockMistNewParameter.new()
    message.args.Param.MistUnlockLevel = 1
    message.args.Param.GridIndexes:Add(mistID)
    message:SendOnceCallback(nil, nil, nil, function()
		self:ResetSelectedMists()
        self:ShowUnlockEffect(mistID)
        self.manualUnlock = false
        self.singleUnlock = false
        self.isDirty = true
        g_Game.EventManager:TriggerEvent(EventConst.ON_UNLOCK_WORLD_FOG)
    end)

    self.manualUnlock = true
    self.singleUnlock = true
end

---@param mistIDList number[]
function MapFogModule:UnlockMistCell(mistIDList)
    local mistCount = table.nums(mistIDList)
    if mistCount <= 0 then
        return
    end

    local UnlockMistNewParameter = require("UnlockMistNewParameter")
    local message = UnlockMistNewParameter.new()
    message.args.Param.MistUnlockLevel = 1
    message.args.Param.GridIndexes:AddRange(mistIDList)
    message:SendOnceCallback(nil, nil, nil, function()
        if mistCount == 1 then
            self:ShowUnlockEffect(mistIDList[1])
        end
        self.manualUnlock = false
        self.isDirty = true
        g_Game.EventManager:TriggerEvent(EventConst.ON_UNLOCK_WORLD_FOG)
    end)

    self.manualUnlock = true
    self:ResetSelectedMists()
end

function MapFogModule:ShowUnlockEffect(mistID)
    local mists = { mistID}
    local position, _ = self:GetMistsRange(mists)
    if Utils.IsNull(self.unlockEffectHandle.Asset) then
        if self.unlockEffectHandle.Idle then
            self.unlockEffectHandle:Create(ManualResourceConst.vfx_bigmap_cloud_01, KingdomMapUtils.GetMapSystem().Parent, Delegate.GetOrCreate(self, self.OnUnlockEffectLoaded), position)
        end
    else
        self.unlockEffectHandle.Asset:SetActive(false)
        self:OnUnlockEffectLoaded(self.unlockEffectHandle.Asset, position)
    end
end

---@param go CS.UnityEngine.GameObject
function MapFogModule:OnUnlockEffectLoaded(go, data)
    local position = data
    if Utils.IsNotNull(go) then
        local layer = KingdomMapUtils.InSymbolMapLod() and LayerMask.SymbolMap or LayerMask.Tile
        go.transform.position = position
        go:SetLayerRecursive(layer)
        go:SetActive(true)
    end
end

---@return wds.MistInfo
function MapFogModule:GetMistInfo()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        g_Logger.Error("can't find player")
        return nil
    end
    return player.PlayerWrapper2.MistInfo
end

---@param mistID number
---@return boolean
function MapFogModule:GoToMist(mistID)
    if ModuleRefer.PlayerModule:StrongholdLevel() < ConfigRefer.ConstBigWorld:UnlockMistRadarLevel() then
        --GotoUtils.GotoByGuide()
    elseif not self:CheckNeighborhood(mistID) then
        local mistCenter = self.fogSystem:GetFogCenter(mistID)
        self:GoToNearestMist(mistCenter)
    elseif not self:CheckMistUnlockTasksFinish(mistID) then
        local attrConfig = self:GetMistAttrConfig(mistID)
        for i = 1, attrConfig:ExploreCondLength() do
            local taskId = attrConfig:ExploreCond(i)
            local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
            if taskState ~= wds.TaskState.TaskStateFinished then
                local taskConfig = ConfigRefer.Task:Find(taskId)
                local taskProp = taskConfig:Property()
                GotoUtils.GotoByGuide(taskProp:Goto(), true)
                break
            end
        end
    end
end

---@param mistID number
---@return boolean
function MapFogModule:GetMistTip(mistID)
    local radarLevel = ModuleRefer.RadarModule:GetRadarLv()
    local radarLevelConfig = ConfigRefer.RadarLevel:Find(radarLevel)
    if not radarLevelConfig then
        return
    end
    
    local canUnlockMistLevel = radarLevelConfig:MistLevel()
    local mistConfig = ConfigRefer.MistCell:Find(mistID)
    if not mistConfig then
        return
    end
    
    local landConfig = ConfigRefer.Land:Find(mistConfig:LandformId())
    if not landConfig then
        return
    end
    local mistLevel = landConfig:MistLevel()
    if canUnlockMistLevel < mistLevel then
        local unlockLevel = ModuleRefer.RadarModule:GetCanUnlockMistRadarLevel(mistLevel)
        return false, false, I18N.GetWithParams("Radar_mist_unlock_tips", unlockLevel), MapFogDefine.MistLockedReason.RadarLevelLimit
    end
    
    if not mistID or mistID == -1 or self:IsMistUnlocked(mistID) then
        return false, false, I18N.Get("mist_toast_mistonly"), MapFogDefine.MistLockedReason.FogCellLimit
    end
    
    if not self:CheckMistUnlockTasksFinish(mistID) then
        return false, false, I18N.Get("mist_toast_failcondition"), MapFogDefine.MistLockedReason.MistUnlockTasksLimit
    end

    local unlock, text = self:CheckMistLandform(mistID)
    if not unlock then
        return false, false, text
    end

    if not self:CheckNeighborhood(mistID) then
        return false, true, I18N.Get("Mist_tips_pathnotcleared"), MapFogDefine.MistLockedReason.NotNeighborhood
    end
    
    return true
end

-- 当玩家一块迷雾都没解锁，并且没有触发天下大势解锁迷雾时，只能解锁主堡所在和其邻接的迷雾块
---@return boolean
function MapFogModule:IsInitialState()
    local mistInfo = self:GetMistInfo()
    if mistInfo and mistInfo.UnlockInfo then
        local unlockInfo = mistInfo.UnlockInfo
        return unlockInfo.UnlockMistCellNum == 0 and unlockInfo.SysUnlockedLands and table.nums(unlockInfo.SysUnlockedLands) == 0
    end
end

---@return table<number, boolean>
function MapFogModule:GetInitAvailableMists(x, z)
    local mists = {}
    local cityMistID = self.fogSystem:GetMistAt(x, z)
    mists[cityMistID] = true
    local mistConfig = ConfigRefer.MistCell:Find(cityMistID)
    for i = 1, mistConfig:NeighborMistCellsLength() do
        local mistID = mistConfig:NeighborMistCells(i)
        mists[mistID] = true
    end
    return mists
end

---@param mistID number
---@return boolean
function MapFogModule:CheckNeighborhood(mistID)
    if self:IsInitialState() then
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local pos = castle.MapBasics.Position
        local x, z = KingdomMapUtils.ParseBuildingPos(pos)
        local mists = self:GetInitAvailableMists(x, z)
        return mists[mistID]
    end

    local mistConfig = ConfigRefer.MistCell:Find(mistID)
    for i = 1, mistConfig:NeighborMistCellsLength() do
        local neighborMistId = mistConfig:NeighborMistCells(i)
        if self.fogSystem:IsFogUnlocked(neighborMistId) then
            return true
        end
    end
    return false
end

function MapFogModule:GetNeighborMistsCanUnlock(maxCount)
    local mists = {}
    if maxCount <= 0 then
        return mists
    end

    local castle = ModuleRefer.PlayerModule:GetCastle()
    local pos = castle.MapBasics.Position
    local x, z = KingdomMapUtils.ParseBuildingPos(pos)

    if self:IsInitialState() then
        local initMists = self:GetInitAvailableMists(x, z)
        for mistID, _ in pairs(initMists) do
            table.insert(mists, mistID)
        end
    else
        local coord = Vector2Short(x, z)
        self.fogSystem:GetCanUnlockedMists(coord, maxCount, self.mistTempCache)
        for i = 0, self.mistTempCache.Count - 1 do
            local mistID = self.mistTempCache[i]
            if mistID > 0 then
                table.insert(mists, mistID)
            end
        end
    end
    return mists
end

function MapFogModule:GetUnlockedMistsOfLandform(landformConfigID)
    if not landformConfigID then
        return 0
    end
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local pos = castle.MapBasics.Position
    local x, z = KingdomMapUtils.ParseBuildingPos(pos)
    local coord = Vector2Short(x, z)
    self.fogSystem:GetUnlockedMists(coord, 200, self.mistTempCache)
    for i = 0, self.mistTempCache.Count - 1 do
        local mistID = self.mistTempCache[i]
        local territoryID = mistID
        local landformID = MapConfigCache.GetLandform(territoryID)
        if landformID == landformConfigID then
            return territoryID
        end
    end
    self.fogSystem:GetSortedMists(coord, 2000, self.mistTempCache)
    for i = 0, self.mistTempCache.Count - 1 do
        local mistID = self.mistTempCache[i]
        local territoryID = mistID
        local landformID = MapConfigCache.GetLandform(territoryID)
        if landformID == landformConfigID then
            return territoryID
        end
    end
    return 0
end

---@param mists number[]
---@return CS.UnityEngine.Vector3
---@return number
function MapFogModule:GetMistsRange(mists)
    ---@type CS.DragonReborn.Range2Int
    local wholeRange
    for _, mistID in ipairs(mists) do
        local range = self.fogSystem:GetFogCenterRange(mistID)
        if not wholeRange then
            wholeRange = range
        else
            wholeRange:Encapsulate(range)
        end
    end

    local coord = wholeRange.Center
    local lookAtPosition = MapUtils.CalculateCoordToWorldPosition(coord.X, coord.Y, self.staticMapData)
    local rangeSizeX = (wholeRange.xMax - wholeRange.xMin) * self.staticMapData.UnitsPerTileX
    local rangeSizeY = (wholeRange.yMax - wholeRange.yMin) * self.staticMapData.UnitsPerTileZ
    return lookAtPosition, math.max(rangeSizeX, rangeSizeY)
end

---@param mists number[]
function MapFogModule:LookAtMists(mists, duration, callback)
    local lookAtPosition, rangeSize = self:GetMistsRange(mists)
    KingdomMapUtils.GetBasicCamera():LookAtRange(lookAtPosition, rangeSize, duration, callback)
end

function MapFogModule:GoToNearestMist(worldPosition)
    if self.allUnlocked then
        return
    end
    local coord = MapUtils.CalculateWorldPositionToCoord(worldPosition, self.staticMapData)
    local nearestMistPosition, _ = self:GetNearestMistPosition(coord)
    local size = KingdomMapUtils.GetCameraLodData():GetSizeByLod(2) - 10
    KingdomMapUtils.MoveAndZoomCamera(nearestMistPosition, size, nil, nil, nil, function()
        local mistCoord = MapUtils.CalculateWorldPositionToCoord(nearestMistPosition, self.staticMapData)
        self:ResetSelectedMists()
        self:SetSelectedMistAt(mistCoord.X, mistCoord.Y, true)
    end)
end

function MapFogModule:GoToNearestMist_Guide(worldPosition)
    if self.allUnlocked then
        return
    end
    local coord = MapUtils.CalculateWorldPositionToCoord(worldPosition, self.staticMapData)
    local nearestMistPosition, _ = self:GetNearestMistPosition(coord)
    local size = KingdomMapUtils.GetCameraLodData():GetSizeByLod(2) - 10
    KingdomMapUtils.MoveAndZoomCamera(nearestMistPosition, size, nil, nil, nil, function()
        local mistCoord = MapUtils.CalculateWorldPositionToCoord(nearestMistPosition, self.staticMapData)
        self:ResetSelectedMists()
        self:SetSelectedMistAt(mistCoord.X, mistCoord.Y, true)
        local GuideUtils = require("GuideUtils")
        GuideUtils.GotoByGuide(46)
    end)
end

function MapFogModule:GotoCastleNearestMist()
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    local callback = function()
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local pos = castle.MapBasics.Position
        local x, z = KingdomMapUtils.ParseBuildingPos(pos)
        local worldPosition = MapUtils.CalculateCoordToWorldPosition(x, z, KingdomMapUtils.GetStaticMapData())
        self:GoToNearestMist_Guide(worldPosition)
    end

    if KingdomMapUtils.IsMapState() then
        callback()
    else
        KingdomMapUtils.GetKingdomScene():LeaveCity(function()
            callback()
        end)
    end
end

---@return boolean
function MapFogModule:IsExploreValueEnough()
    local exploreValue = self:GetUnlockItemCount()
    return exploreValue >= ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
end

---@param tileX number
---@param tileZ number
function MapFogModule:IsFogUnlocked(tileX, tileZ)
    return self:IsMistUnlockedAt(tileX, tileZ) or self:CircleUnlockedAt(tileX, tileZ)
end

---@private
---@param mistID number
---@return boolean
function MapFogModule:IsMistUnlocked(mistID)
    return self.allUnlocked or self.fogSystem:IsFogUnlocked(mistID)
end

---@param tileX number
---@param tileZ number
---@return boolean
function MapFogModule:IsMistUnlockedAt(tileX, tileZ)
    if self.allUnlocked then
        return true
    end
    tileX, tileZ = KingdomMapUtils.ParseCoordinate(tileX, tileZ)
    local mist = self.fogSystem:GetMistAt(tileX, tileZ)
    local RANGE = 3
    if mist <= 0 then
        for i = -RANGE, RANGE do
            for j = -RANGE, RANGE do
                local x = tileX + i
                local z = tileZ + j
                mist = self.fogSystem:GetMistAt(x, z)
                if mist > 0 then
                    return self.fogSystem:IsFogUnlocked(mist)
                end
            end
        end
    end
    return self.fogSystem:IsFogUnlockedAt(tileX, tileZ)
end

function MapFogModule:CircleUnlockedAt(tileX, tileZ)
    --todo: return false when guide is on
    tileX, tileZ = KingdomMapUtils.ParseCoordinate(tileX, tileZ)
    local blockIndex = MapUtils.CalculateBlockIndex(tileX, tileZ, self.tilesPerBlockX, self.tilesPerBlockZ, self.blocksPerMapX)
    local cell = self:GetGridCell(blockIndex)

    if cell then
        ---@param circle CircleMask
        for _, circle in pairs(cell) do
            local x, z = KingdomMapUtils.ParseCoordinate(circle.x, circle.y)
            local distX = x - tileX
            local distZ = z - tileZ
            local radius = circle.radius
            if distX * distX + distZ * distZ < radius * radius then
                return true
            end
        end
    end
end

---@param tileX number
---@param tileZ number
---@return number
function MapFogModule:GetMistAt(tileX, tileZ)
    tileX, tileZ = KingdomMapUtils.ParseCoordinate(tileX, tileZ)
    return self.fogSystem:GetMistAt(tileX, tileZ)
end

function MapFogModule:SetSelectedMistAt(tileX, tileZ, showTouchInfo)
    tileX, tileZ = KingdomMapUtils.ParseCoordinate(tileX, tileZ)
    local mistID = self:GetMistAt(tileX, tileZ)

    if self.currentMistID then
        if showTouchInfo then
            self.currentMistID = nil
            ModuleRefer.KingdomTouchInfoModule:Hide()
            self.fogSystem:ResetSelectedMists()
            self.isDirty = true
            return
        end
    end
    ModuleRefer.KingdomTouchInfoModule:Hide()
    
    self.fogSystem:ResetSelectedMists()

    self.currentMistID = mistID
    self.fogSystem:SetSelectedMist(mistID)

    if self.currentMistID ~= -1 then
        if showTouchInfo then
            local data = KingdomTouchInfoFactory.CreateMist(tileX, tileZ)
            ModuleRefer.KingdomTouchInfoModule:Show(data)
        end
    end

    self.isDirty = true
end

function MapFogModule:ResetSelectedMists()
    self.fogSystem:ResetSelectedMists()
    self.currentMistID = nil
    self.isDirty = true
end

function MapFogModule:GetNearestMistPosition(coord)
    if self:IsInitialState() then
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local pos = castle.MapBasics.Position
        local x, z = KingdomMapUtils.ParseBuildingPos(pos)
        local mistID = self.fogSystem:GetMistAt(x, z)
        local radius = ConfigRefer.ConstMain:CityUnlockMistRadius()
        local coord = self.fogSystem:CalculateValidCoordExcludeCircle(mistID, x, z, radius)
        local position = MapUtils.CalculateCoordToWorldPosition(coord.X, coord.Y, KingdomMapUtils.GetStaticMapData())
        return position, mistID
    else
        if not coord then
            local castle = ModuleRefer.PlayerModule:GetCastle()
            local pos = castle.MapBasics.Position
            coord = Vector2Short(KingdomMapUtils.ParseBuildingPos(pos))
        end
        local position, mistID = self.fogSystem:GetNearestMistPosition(coord)
        if mistID == 0 then
            g_Logger.Error("can't find nearest mist at %s,%s", coord.X, coord.Y)
            return nil, nil
        end
        return position, mistID
    end
end

---@return MistTypeAttrConfigCell
function MapFogModule:GetMistAttrConfig(mistID)
    local mistConfig = ConfigRefer.MistCell:Find(mistID)
    if mistConfig then
        return ConfigRefer.MistTypeAttr:Find(mistConfig:MistTypeAttrId())
    end
    return nil
end

---@param mistID number
---@return boolean
function MapFogModule:CheckMistUnlockTasksFinish(mistID)
    local attrConfig = self:GetMistAttrConfig(mistID)
    for i = 1, attrConfig:ExploreCondLength() do
        local taskId = attrConfig:ExploreCond(i)
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if taskState ~= wds.TaskState.TaskStateFinished then
            return false
        end
    end
    return true
end

function MapFogModule:CheckMistLandform(mistID)
    --注意，迷雾和领地是对应的
    local territoryConfig = ConfigRefer.Territory:Find(mistID)
    return ModuleRefer.LandformModule:GetLandformOpenHint(territoryConfig:LandId(), false)
end

---@return number
function MapFogModule:GetUnlockItemCount()
    --return self:GetMistInfo().ExploreValue
    local itemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemID)
    return itemCount
end

function MapFogModule:GetUnlockItemCountLimit()
    local radarLevel = ModuleRefer.RadarModule:GetRadarLv()
    local levelConfig = ConfigRefer.RadarLevel:Find(radarLevel)
    if levelConfig then
        return levelConfig:UnlockMistPointRecoverMax()
    end
    return 0
end

function MapFogModule:IsItemEnough()
    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    local exploreValue = self:GetUnlockItemCount()
    return exploreValue >= costPerMistCell
end

---@return number
function MapFogModule:GetMaxUnlockCount()
    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    local exploreValue = self:GetUnlockItemCount()
    local maxExploreNum = math.floor(exploreValue / costPerMistCell)
    maxExploreNum = math.min(maxExploreNum, MaxUnlockCount) 
    local mists = self:GetNeighborMistsCanUnlock(maxExploreNum)
    return table.nums(mists)
end

function MapFogModule.UnlockItemGetMore()
    local itemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local exchangeItemParam = {}
    exchangeItemParam.id = itemID
    exchangeItemParam.num = ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    ModuleRefer.InventoryModule:OpenExchangePanel({ exchangeItemParam })
end

function MapFogModule:ShowUnlockItemTip()
    local recoverInterval = ConfigRefer.ConstMain:UnlockMistPointRecoverInterval()
    local intervalStr = tostring(math.round(Utils.ParseDurationToSecond(recoverInterval) / 3600))
    return I18N.GetWithParams("Radar_mist_glowstick_tips", intervalStr)
end

return MapFogModule
