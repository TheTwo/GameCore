local KingdomMapUtils = require("KingdomMapUtils")
local BaseModule = require("BaseModule")
local PoolUsage = require("PoolUsage")
local UIMediatorNames = require("UIMediatorNames")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local KingdomPlacerFactory = require("KingdomPlacerFactory")
local KingdomConstructionCantPlaceReason = require("KingdomConstructionCantPlaceReason")
local MapStatePlacingBuilding = require("MapStatePlacingBuilding")
local MapStateRelocate = require("MapStateRelocate")
local DBEntityType = require("DBEntityType")
local KingdomConstant = require("KingdomConstant")
local KingdomPlacingBuildingList = require("KingdomPlacingBuildingList")
local MapSortingOrder = require("MapSortingOrder")
local KingdomPlacer = require("KingdomPlacer")
local RelocateCantPlaceReason = require("RelocateCantPlaceReason")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")

local KingdomPlacingStateFactory = require("KingdomPlacingStateFactory")
local KingdomPlacingType = require("KingdomPlacingType")

local KingdomGridMeshManager = CS.Kingdom.KingdomGridMeshManager
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local MapUtils = CS.Grid.MapUtils
local ListInt32 = CS.System.Collections.Generic.List(typeof(CS.System.Int32))
local ListInt16 = CS.System.Collections.Generic.List(typeof(CS.System.Int16))
local ListSingle = CS.System.Collections.Generic.List(typeof(CS.System.Single))

---@class KingdomPlacingModule:BaseModule
---@field super BaseModule
---@field isPlacing boolean
---@field buildingConfig FlexibleMapBuildingConfigCell
---@field anchorPosition CS.UnityEngine.Vector3
---@field anchorCoord CS.DragonReborn.Vector2Short
---@field placer KingdomPlacerHolder
---@field gridMeshManager CS.Kingdom.KingdomGridMeshManager
---@field placerHandle CS.DragonReborn.AssetTool.PooledGameObjectHandle
---@field touchCircleId number
---@field customValidator fun():boolean
---@field staticMapData CS.Grid.StaticMapData
---@field mapSystem CS.Grid.MapSystem
---@field basicCamera BasicCamera
---@field buildingEntityChanged boolean
---@field territoryYesList table CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field territoryNoList table CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field rectYesList table CS.System.Collections.Generic.List(typeof(CS.System.Int16))
---@field rectNoList table CS.System.Collections.Generic.List(typeof(CS.System.Int16))
---@field circleYesList table CS.System.Collections.Generic.List(typeof(CS.System.Single))
---@field circleNoList table CS.System.Collections.Generic.List(typeof(CS.System.Single))
---@field size {x:number,y:number}
---@field placeIdxHandle number
---@field state KingdomPlacingState
local KingdomPlacingModule = class("KingdomPlacingModule", BaseModule)

function KingdomPlacingModule:ctor()
    KingdomPlacingModule.super.ctor(self)
    self.placeIdxHandle = nil
end

function KingdomPlacingModule:OnRegister()
    self.territoryYesList = ListInt32(32)
    self.territoryNoList = ListInt32(32)
    self.rectYesList = ListInt16(128)
    self.rectNoList = ListInt16(128)
    self.circleYesList = ListSingle(64)
    self.circleNoList = ListSingle(64)
end

function KingdomPlacingModule:OnRemove()
    self:Release()
end

function KingdomPlacingModule:IsPlacing()
    return self.isPlacing
end

function KingdomPlacingModule:GetPlacingBuildingConfig()
    return self.buildingConfig
end

---@param buildingCellId number @FlexibleMapBuildingConfigCell Id
---@param customValidator fun():boolean
function KingdomPlacingModule:StartPlacing(buildingCellId, customValidator, noClose)
    if not KingdomMapUtils.IsMapState() then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CLEAR_SLG_SELECT)
    
    self:Reset(noClose)
    
    -- g_Game.UIManager:CloseByName(UIMediatorNames.TroopCircleMenuMediator)
    -- g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)

    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    
    self:CalculateCenterCoord()

    ---@type KingdomSceneStateMap
    local kingdomState = KingdomMapUtils.GetKingdomState()
    if kingdomState:GetCurrentMapState():GetName() ~= MapStatePlacingBuilding.Name then
        kingdomState:EnterPlacingBuilding()
        self:FocusCamera(function()
            self:DoPlace(buildingCellId, self.anchorCoord, customValidator)
        end)
    else
        self.basicCamera.enableDragging = true
        self.basicCamera.enablePinch = false
        self:DoPlace(buildingCellId, self.anchorCoord, customValidator)
    end
    local ret = self.placeIdxHandle or 0
    self.placeIdxHandle = ret + 1

    self.state = KingdomPlacingStateFactory.Create(KingdomPlacingType.AllianceBuilding)
    if self.state then
        self.state:SetContext(ConfigRefer.FlexibleMapBuilding:Find(buildingCellId))
        self.state:OnStart()
    end
    
    return ret
end

---@param buildingCellId number
---@param coord CS.DragonReborn.Vector2Short|nil
---@param customValidator fun():boolean
function KingdomPlacingModule:DoPlace(buildingCellId, coord, customValidator)
    self.buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(buildingCellId)
    self.customValidator = customValidator

    self.gestureHandle = CS.LuaGestureListener(self)
    g_Game.GestureManager:AddListener(self.gestureHandle)
    self.basicCamera.enableDragging = false

    self:ShowPlacingGrid()

    self:HideTouchCircle()
    if self.placer then
        self.placer:Hide()
        self.placer:Dispose()
    end

    self.isPlacing = true

    self.placer = KingdomPlacerFactory.CreateBuilding(self.buildingConfig, coord)
    self.size = self.placer 
            and self.placer:GetContext() 
            and self.placer:GetContext() .sizeX 
            and self.placer:GetContext() .sizeY 
            and {x=self.placer:GetContext().sizeX,y=self.placer:GetContext().sizeY}
    self.placer:SetValidator(Delegate.GetOrCreate(self, self.ValidateCoordinate))
    self.placer:Show()
    self.placer:UpdatePosition(coord.X, coord.Y)
    self.placer:OnPlaceReady(KingdomMapUtils.DirtyMapMark)
end

function KingdomPlacingModule:StartRelocate(buildingCellId, customValidator, coord, callback)
    if not KingdomMapUtils.IsMapState() then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CLEAR_SLG_SELECT)

    self:Reset()

    -- g_Game.UIManager:CloseByName(UIMediatorNames.TroopCircleMenuMediator)
    -- g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)

    self.anchorCoord = coord
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    ---@type KingdomSceneStateMap
    local kingdomState = KingdomMapUtils.GetKingdomState()
    if kingdomState:GetCurrentMapState():GetName() ~= MapStateRelocate.Name then
        kingdomState:EnterRelocate()
        local worldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(coord.X,coord.Y, KingdomMapUtils.GetMapSystem())
        self:FocusCamera(function()
            self:DoRelocate(buildingCellId, coord, customValidator, callback)
        end, worldPos)
    else
        self:DoRelocate(buildingCellId, coord, customValidator, callback)
    end

    self.state = KingdomPlacingStateFactory.Create(KingdomPlacingType.Relocate)
    if self.state then
        self.state:OnStart()
    end
end

function KingdomPlacingModule:DoRelocate(buildingCellId, coord, customValidator, callback)
    self.buildingConfig = ConfigRefer.FixedMapBuilding:Find(buildingCellId)
    self.customValidator = customValidator
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, false)

    self:ShowPlacingGrid(true)

    self:HideTouchCircle()
    if self.placer then
        self.placer:Hide()
        self.placer:Dispose()
    end

    self.isPlacing = true

    self.placer = KingdomPlacerFactory.CreateCastle(self.buildingConfig, coord)
    self.placer:SetValidator(Delegate.GetOrCreate(self, self.ValidateCoordinate))
    self.placer:Show()
    self.placer:UpdatePosition(coord.X, coord.Y)
    TimerUtility.DelayExecute(function()
        self.tickLock = false
    end, 0.5)
    self.placer:OnPlaceReady(KingdomMapUtils.DirtyMapMark)
    if callback then
        callback()
    end
end

function KingdomPlacingModule:EndPlacing(noClose)
    if self.state then
        self.state:OnEnd()
    end
    
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
    self.gestureHandle = nil
    self.isPlacing = false
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, true)
    self:HideTouchCircle()
    if self.gridMeshManager then
        self.gridMeshManager:Hide()
    end
    if self.placer then
        self.placer:Hide()
        self.placer:Dispose()
    end
    self.place = nil
    
    ---@type KingdomSceneStateMap|nil
    local kingdomState = KingdomMapUtils.GetKingdomState()
    if kingdomState then
        local currentMapState = kingdomState:GetCurrentMapState()
        if currentMapState then
            local stateName = currentMapState:GetName()
            if stateName == MapStatePlacingBuilding.Name or stateName == MapStateRelocate.Name then
                kingdomState:EnterNormal()
                self:ResetCamera(noClose)
            end
        end
    end

    if not noClose and g_Game.UIManager:IsOpenedByName(UIMediatorNames.KingdomConstructionModeUIMediator) then
        g_Game.UIManager:CloseByName(UIMediatorNames.KingdomConstructionModeUIMediator)
    end

    KingdomMapUtils.DirtyMapMark()
end

function KingdomPlacingModule:StartBehemoth()
    self:Reset()

    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self:ShowPlacingArea()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickArea))
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))

    self.state = KingdomPlacingStateFactory.Create(KingdomPlacingType.Behemoth)
    if self.state then
        self.state:OnStart()
    end
end

function KingdomPlacingModule:EndBehemoth()
    if self.state then
        self.state:OnEnd()
    end
    
    if self.gridMeshManager then
        self.gridMeshManager:Hide()
    end
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnCameraLodChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickArea))
    KingdomMapUtils.DirtyMapMark()
    if self.gridMeshManager then
        self.gridMeshManager:Dispose()
        self.gridMeshManager = nil
    end
end

function KingdomPlacingModule:Reset(noClose)
    self:EndPlacing(noClose)
    self:EndBehemoth()
end


function KingdomPlacingModule:Release()
    self:HideTouchCircle()
    if self.state then
        self.state:OnEnd()
    end
    if self.gridMeshManager then
        self.gridMeshManager:Dispose()
        self.gridMeshManager = nil
    end
    if self.placer then
        self.placer:Hide()
        self.placer:Dispose()
        self.placer = nil
    end
end

---@private
function KingdomPlacingModule:ShowPlacingGrid(initValid)
    initValid = initValid or false
    self.initType = initValid
    if not self.gridMeshManager then
        local settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.KingdomGridMeshSettings))
        self.gridMeshManager = KingdomGridMeshManager()
        self.gridMeshManager:Initialize(KingdomMapUtils.GetMapSystem(), self.staticMapData, KingdomMapUtils.GetTerritorySystem(), settings, self.basicCamera.mainCamera, MapSortingOrder.GridMesh, require("MapFoundation").HideObject)
    else
        self.gridMeshManager:Show()
    end
    
    if self.state then
        self.state:SetGridData(self.gridMeshManager, self.territoryYesList, self.territoryNoList, self.rectYesList, self.rectNoList, self.circleYesList, self.circleNoList)
    end
    
    self.gridMeshManager:SetRenderParameter("mat_kingdom_grid_mesh", KingdomPlacer.gridColor, KingdomPlacer.noColor, KingdomPlacer.clearColor)
    self.gridMeshManager:Cull()
end

---@private
function KingdomPlacingModule:ShowPlacingArea()
    self.buildingConfig = nil
    if not self.gridMeshManager then
        local settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.KingdomGridMeshSettings))
        self.gridMeshManager = KingdomGridMeshManager()
        self.gridMeshManager:Initialize(KingdomMapUtils.GetMapSystem(), self.staticMapData, KingdomMapUtils.GetTerritorySystem(), settings, self.basicCamera.mainCamera, MapSortingOrder.GridMesh)
    else
        self.gridMeshManager:Show()
    end
    
    if self.state then
        self.state:SetGridData(self.gridMeshManager, self.territoryYesList, self.territoryNoList, self.rectYesList, self.rectNoList, self.circleYesList, self.circleNoList)
    end
    
    local gridColor = KingdomPlacer.gridColor
    gridColor.a = 0.5
    self.gridMeshManager:SetRenderParameter("mat_kingdom_grid_area", gridColor, KingdomPlacer.clearColor, KingdomPlacer.clearColor)
    self.gridMeshManager:Cull()
end

function KingdomPlacingModule:TickArea()
    if KingdomMapUtils.GetLOD() > 2 then
        self:EndBehemoth()
        return
    end

    if self.state and self.state:IsDirty() then
        self.state:SetGridData(self.gridMeshManager, self.territoryYesList, self.territoryNoList, self.rectYesList, self.rectNoList, self.circleYesList, self.circleNoList)
    end

    if self:CalculateCenterCoord() then
        if self.gridMeshManager then
            self.gridMeshManager:Cull()
        end
    end
end

function KingdomPlacingModule:Tick()
    if not self.isPlacing then
        return
    end

    if self.state and self.state:IsDirty() then
        self.state:SetGridData(self.gridMeshManager, self.territoryYesList, self.territoryNoList, self.rectYesList, self.rectNoList, self.circleYesList, self.circleNoList)
    end

    if KingdomMapUtils.GetKingdomState():GetCurrentMapState():GetName() ~= MapStateRelocate.Name or not self.tickLock then
        if self:CalculateCenterCoord() then
            if self.gridMeshManager then
                self.gridMeshManager:Cull()
            end
            if self.placer then
                self.placer:UpdatePosition(self.anchorCoord.X, self.anchorCoord.Y)
            end
        end
    end

    if not self.basicCamera:Idle() then
        self:HideTouchCircle()
    elseif not self.placer or not self.placer:IsDragTarget() then
        self:ShowTouchCircle(self.basicCamera, self.anchorCoord)
    end
end

---@param callback fun(boolean, number, number)
function KingdomPlacingModule:SearchForAvailableRect(centerX, centerY, range, margin, targetSizeX, targetSizeY, callback)
    self.gridMeshManager:SearchForAvailableRect(centerX, centerY, range, margin, targetSizeX, targetSizeY, callback)
end

---@return boolean
---@private
function KingdomPlacingModule:ValidateCoordinate(x, y)
    return self.gridMeshManager:IsCoordinateValid(x, y)
end


function KingdomPlacingModule:OnCameraLodChanged(oldLod, newLod)
    if newLod > 2 then
        self:EndBehemoth()
    end
end

function KingdomPlacingModule:OnDragPlacerHideCircle()
    self:HideTouchCircle()
end

---@param basicCamera BasicCamera
---@param coord CS.DragonReborn.Vector2Short
---@private
function KingdomPlacingModule:ShowTouchCircle(basicCamera, coord)
    if self.touchCircleId then
        return
    end

    local kingdomState = KingdomMapUtils.GetKingdomState()
    if kingdomState:GetCurrentMapState():GetName() == MapStatePlacingBuilding.Name then
        self:InitTouchCircle(basicCamera, coord)
    elseif kingdomState:GetCurrentMapState():GetName() == MapStateRelocate.Name then
        self:InitTouchRelocate(basicCamera, coord)
    end
    
end

---@private
function KingdomPlacingModule:HideTouchCircle()
    if not self.touchCircleId then
        return
    end

    g_Game.UIManager:Close(self.touchCircleId, nil)
    self.touchCircleId = nil
end

function KingdomPlacingModule:InitTouchCircle(basicCamera, coord)
    ---@type CircleMenuSimpleButtonData
    local confirm = {
        buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconTick,
        buttonBack = CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        buttonEnable = self:CheckTileValid() and self:CustomCheck(self.buildingConfig),
        onClick = Delegate.GetOrCreate(self, self.OnConfirmToBuild),
        onClickFailed = Delegate.GetOrCreate(self, self.OnConfirmDisabled)
    }

    ---@type CircleMenuSimpleButtonData
    local cancel = {
        buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconCancel,
        buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        buttonEnable = true,
        onClick = Delegate.GetOrCreate(self, self.OnCancel)
    }

    local worldPosition = MapUtils.CalculateCoordToTerrainPosition(coord.X, coord.Y, self.mapSystem)
    if self.size then
        local endPos = MapUtils.CalculateCoordToTerrainPosition(coord.X + self.size.x, coord.Y + self.size.y, self.mapSystem)
        worldPosition.x = (worldPosition.x + endPos.x) * 0.5
        worldPosition.z = (worldPosition.z + endPos.z) * 0.5
    end
    local param = CircleMemuUIParam.new(basicCamera, worldPosition, I18N.Get(self.buildingConfig:Name()), {confirm, cancel})
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CityCircleMenuUIMediator)
    self.touchCircleId = g_Game.UIManager:Open(UIMediatorNames.CityCircleMenuUIMediator, param)
end

function KingdomPlacingModule:InitTouchRelocate(basicCamera, coord)
    local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
    local worldPosition = MapUtils.CalculateCoordToTerrainPosition(coord.X, coord.Y, KingdomMapUtils.GetMapSystem())
    local relocatePos = CS.UnityEngine.Vector3(self.placer:GetContext().coord.X, self.placer:GetContext().coord.Y, 0)
    ---@type RelocateMediatorParameter
    local param = {camera = basicCamera, worldPos = worldPosition, relocatePos = relocatePos}
    self.touchCircleId = g_Game.UIManager:Open(UIMediatorNames.RelocateMediator, param)
end

---@private
function KingdomPlacingModule:CheckTileValid()
    return self.placer and self.placer:IsAllTileValid()
end

---@param buildingConfig FlexibleMapBuildingConfigCell
---@private
function KingdomPlacingModule:CustomCheck(buildingConfig)
    return not self.customValidator or self.customValidator(buildingConfig) == KingdomConstructionCantPlaceReason.OK
end

---@return boolean
function KingdomPlacingModule:NotifyTerritoryOnlyToast()
    if self.buildingConfig and self.buildingConfig.AllianceCenterTerritoryOnly and self.buildingConfig:AllianceCenterTerritoryOnly() then
        local allianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillage()
        if not allianceCenter then
            if ModuleRefer.VillageModule:AllianceHasAnyVillage() then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemothActivity_tips_buildCondition"))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemothActivity_tips_condition"))
            end
            return true
        end
        local context = self.placer and self.placer:GetContext()
        if context and context.sizeY and context.sizeX and context.coord then
            local vid = allianceCenter.VID
            for j = 0, context.sizeY - 1 do
                for i = 0, context.sizeX - 1 do
                    local X = context.coord.X + i
                    local Y = context.coord.Y + j
                    local territoryId = ModuleRefer.TerritoryModule:GetTerritoryAt(X, Y)
                    if vid ~= territoryId then
                        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemothBuild_tips_build"))
                        return true
                    end
                end
            end
        end
    end
    return false
end

---@private
function KingdomPlacingModule:OnConfirmToBuild()
    if not self:CheckTileValid() then
        if not self:NotifyTerritoryOnlyToast() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_wxdg"))
        end
        return
    end
    if self.customValidator then
        local reason = self.customValidator(self.buildingConfig)
        if reason ~= KingdomConstructionCantPlaceReason.OK then
            local toast = ModuleRefer.KingdomConstructionModule.CantPlaceToast(reason, self.buildingConfig)
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(toast))
            end
            return
        end
    end

    if self.placer then
        self.placer:Place()
    end
    
    self:EndPlacing()
end

function KingdomPlacingModule:OnConfirmDisabled()
    if not self:CheckTileValid() then
        if not self:NotifyTerritoryOnlyToast() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_wxdg"))
        end
        return
    end

    if self.customValidator then
        local reason = self.customValidator(self.buildingConfig)
        if reason ~= KingdomConstructionCantPlaceReason.OK then
            local toast = ModuleRefer.KingdomConstructionModule.CantPlaceToast(reason, self.buildingConfig)
            if not string.IsNullOrEmpty(toast) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(toast))
            end
            return
        end
    end
end

function KingdomPlacingModule:OnCancel()
    self:EndPlacing()
end

function KingdomPlacingModule:OnClickRelocate(type)
    if type == wrpc.MoveCityType.MoveCityType_MoveToCurProvince then
        ---@type CommonConfirmPopupMediatorParameter
        local dialogParam = {}
        local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("relocate_info_DoubleCheck")
        dialogParam.content = I18N.Get("relocate_check_precious")
        dialogParam.onCancel = function()
            self:InitTouchRelocate(self.basicCamera, self.anchorCoord)
            return true
        end
        dialogParam.onClose = function()
            self:InitTouchRelocate(self.basicCamera, self.anchorCoord)
            return true
        end
        dialogParam.onConfirm = function()
            self:OnConfirmRelocate(type)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    elseif type == wrpc.MoveCityType.MoveCityType_MoveToAllianceTerrain then
        self:OnConfirmRelocate(type)
    end
end

---@private
function KingdomPlacingModule:OnConfirmRelocate(type)
   
    local X = self.placer:GetContext().coord.X
    local Y = self.placer:GetContext().coord.Y
    if self.customValidator then
        local reason = self.customValidator(X, Y, type)
        if reason ~= RelocateCantPlaceReason.OK then
            local toast = ModuleRefer.RelocateModule.CantRelocateToast(reason)
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(toast))
            self:EndPlacing()
            return true
        end
    end

    if self.placer then
        KingdomMapUtils.GetKingdomScene():MoveCityByType(X, Y, type)
    end
    
    self:EndPlacing()
    return false
end

---@private
function KingdomPlacingModule:CalculateCenterCoord()
    local anchorCoord
    self.anchorPosition, anchorCoord = KingdomMapUtils.GetCameraAnchorTerrainCoordinate()
    if not self.anchorCoord or self.anchorCoord.X ~= anchorCoord.X or self.anchorCoord.Y ~= anchorCoord.Y then
        self.anchorCoord = anchorCoord
        return true
    end
    return false
end

---@private
function KingdomPlacingModule:FocusCamera(callback, worldPos)
    self.prevCameraSize = self.basicCamera:GetSize()
    self.prevCameraEnableDragging = self.basicCamera.enableDragging
    self.prevCameraEnablePinch = self.basicCamera.enablePinch

    self.basicCamera:ClearCache()
    self.basicCamera:ForceGiveUpTween()
    self.basicCamera.enableDragging = true
    self.basicCamera.enablePinch = false

    local size = 2010
    if not worldPos then
        self.basicCamera:ZoomToWithAnchor(size, self.anchorPosition, KingdomConstant.CameraFocusDuration, callback)
    else
        self.tickLock = true
        self.basicCamera:LookAt(worldPos, 0.1, callback)
        KingdomMapUtils.GetBasicCamera():SetSize(size)
    end
end

---@private
function KingdomPlacingModule:ResetCamera(skipSize)
    self.basicCamera.enableDragging = self.prevCameraEnableDragging
    self.basicCamera.enablePinch = self.prevCameraEnablePinch
    if skipSize then
        return
    end
    local anchor = KingdomMapUtils.GetCameraAnchorPosition()
    self.basicCamera:ZoomTo(self.prevCameraSize, KingdomConstant.CameraFocusDuration)
end

function KingdomPlacingModule:CanDoBuild()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    if not ModuleRefer.KingdomModule:IsSystemOpen(NewFunctionUnlockIdDefine.kingdom_map_build_entry) then
        return false
    end
    
    local types = require("FlexibleMapBuildingType")
    for _, t in pairs(types) do
        if ModuleRefer.KingdomConstructionModule:CheckBuildingAuthority(t) then
            return true
        end
    end
    return false
end

function KingdomPlacingModule:OnClick(gesture)
end
function KingdomPlacingModule:OnPinch(gesture)
end
function KingdomPlacingModule:OnPress(gesture)
end
function KingdomPlacingModule:OnPressDown(gesture)
end
function KingdomPlacingModule:OnRelease(gesture)
end
function KingdomPlacingModule:OnUIElementTouchUp(gesture)
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacingModule:OnDrag(gesture)
    if gesture.phase == CS.DragonReborn.GesturePhase.Started then
        self:OnDragStart(gesture)
    elseif gesture.phase == CS.DragonReborn.GesturePhase.Updated then
        self:OnDragUpdate(gesture)
    elseif gesture.phase == CS.DragonReborn.GesturePhase.Ended then
        self:OnDragEnd(gesture)
    end
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacingModule:OnDragStart(gesture)
    if not self.placer or not self.placer:OnDragStart(gesture) then
        self.basicCamera:DoDrag(gesture)
    end
end

function KingdomPlacingModule:OnDragUpdate(gesture)
    if not self.placer or not self.placer:OnDragUpdate(gesture) then
        self.basicCamera:DoDrag(gesture)
    end
end

function KingdomPlacingModule:OnDragEnd(gesture)
    if not self.placer or not self.placer:OnDragEnd(gesture) then
        self.basicCamera:DoDrag(gesture)
    end
end

return KingdomPlacingModule
