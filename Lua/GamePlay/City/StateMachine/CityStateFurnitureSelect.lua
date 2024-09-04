local CityStateDefault = require("CityStateDefault")
---@class CityStateFurnitureSelect:CityStateDefault
---@field cellTile CityFurnitureTile
local CityStateFurnitureSelect = class("CityStateFurnitureSelect", CityStateDefault)
local Delegate = require("Delegate")
local CastleDelFurnitureParameter = require("CastleDelFurnitureParameter")
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local CityUtils = require("CityUtils")
local UIMediatorNames = require("UIMediatorNames")
local CityStateI18N = require("CityStateI18N")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityWorkClosureFactory = require("CityWorkClosureFactory")
local I18N = require("I18N")
local CityCitizenDefine = require("CityCitizenDefine")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local CityFurnitureTypesSelectedFocusType = require("CityFurnitureTypesSelectedFocusType")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CityWorkType = require("CityWorkType")
local Utils = require("Utils")
local QueuedTask = require("QueuedTask")
local TimerUtility = require("TimerUtility")
local CityWorkFurnitureUpgradeUIParameter = require("CityWorkFurnitureUpgradeUIParameter")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local ArtResourceUtils = require("ArtResourceUtils")
local Debug = false

function CityStateFurnitureSelect:Enter()
    CityStateDefault.Enter(self)
    self.queuedTask = QueuedTask.new()
    self.cellTile = self.stateMachine:ReadBlackboard("furniture", true)
    local exitImmediately = self:CollectFurnitureProcessOutput(self.cellTile)
    exitImmediately = exitImmediately or self:CollectFurnitureCollectOutput(self.cellTile)
    exitImmediately = exitImmediately or self:TryConfirmLevelUpFurniture(self.cellTile)
    
    if exitImmediately then
        self:ExitToIdleState()
        return
    end
    self:OpenUI()
    self:PlayIndoorFurnitureSound()
    self:PlayNormalSelectSound()
    -- self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)
    -- g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_UPDATE, wds.CityBattleObjType.CityBattleObjTypeFurniture, self.cellTile:GetCell():UniqueId())
    g_Game.ServiceManager:AddResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureDel))
    g_Game.EventManager:AddListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnFurnitureNormalProduceMediatorExit))
    g_Game.EventManager:AddListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnFurnitureFinished))
end

function CityStateFurnitureSelect:ReEnter()
    self:Exit()
    self:Enter()
end

function CityStateFurnitureSelect:Exit()
    local furnitureId = self.cellTile:GetCell():UniqueId()
    TimerUtility.DelayExecuteInFrame(function()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_UPDATE, wds.CityBattleObjType.CityBattleObjTypeFurniture, furnitureId)
    end, 1, true)
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnFurnitureNormalProduceMediatorExit))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_INFO_UI_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_CLOSE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnFurnitureFinished))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureDel))
    self.cellTile:SetSelected(false)
    -- self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    -- self:DeleteSelector()
    self:CloseUI()
    self.cellTile = nil
    if self.queuedTask then
        self.queuedTask:Release()
        self.queuedTask = nil
    end
    CityStateDefault.Exit(self)
end

function CityStateFurnitureSelect:OnFurnitureDel(isSuccess, rsp)
    if isSuccess then
        self.stateMachine:ChangeState(self.city:GetSuitableIdleState(self.city.cameraSize))
    end
end

---@param trigger CityTrigger
---@param position CS.UnityEngine.Vector3 @gesture.position
function CityStateFurnitureSelect:OnClickTrigger(trigger, position)
    local x,y = trigger:GetOwnerPos()
    if x ~= self.cellTile.x or y ~= self.cellTile.y then
        self:ExitToIdleState()
        return true
    end
    return CityStateDefault.OnClickTrigger(self, trigger, position)
end

function CityStateFurnitureSelect:OnClickCellTile(cellTile)
    self:ExitToIdleState()
    return true
end

---@param furnitureTile CityFurnitureTile
function CityStateFurnitureSelect:OnClickFurnitureTile(furnitureTile)
    if self.cellTile == furnitureTile then
        return true
    end

    return CityStateDefault.OnClickFurnitureTile(self, furnitureTile)
end

function CityStateFurnitureSelect:OnCameraSizeChanged(oldValue, newValue)
    self:TryChangeToAirView(oldValue, newValue)
end

function CityStateFurnitureSelect:OpenUI()
    self:ShowCityCircleMenu()
end

function CityStateFurnitureSelect:CloseUI()
    self:HideCityCircleMenu()
end

function CityStateFurnitureSelect:ShowFurnitureDetails()
    local furniture = self.cellTile:GetCell()
    self:ExitToIdleState()
    furniture:TryOpenLvUpUI()
end

function CityStateFurnitureSelect:GetDetailEnterButton()
    local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_troop_icon_d",
        "sp_btn_circle_sec",
        true,
        Delegate.GetOrCreate(self, self.ShowFurnitureDetails))
    return buttonData
end

function CityStateFurnitureSelect:GetCircleMenuUIParameter()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    local furniture = self.cellTile:GetCell()
    local furnitureConfig = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local buttonDataList = {}
    local workTypeCheck = {}
    for i = 1, furnitureConfig:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(furnitureConfig:WorkList(i))
        local workType = workCfg:Type()
        if workTypeCheck[workType] then
            g_Logger.Error("一个家具上有两个同类型Work, 不予处理")
            goto continue
        end
        workTypeCheck[workType] = true
        if workType == CityWorkType.FurnitureLevelUp then
            if furniture:IsUpgrading()  then
                local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_speedup",
                    CircleMenuButtonConfig.ButtonBacks.BackNormal,
                    true,
                    CityWorkClosureFactory.CreateFurnitureLvUpSpeedUpButton(self.cellTile, self),
                    CityWorkClosureFactory.CreateDisableButton())
                buttonData:SetNodeName("p_btn_speed_up"):SetPriority(-2)
                table.insert(buttonDataList, buttonData)
            else
                local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_city_icon_upgrade",
                    CircleMenuButtonConfig.ButtonBacks.BackNormal,
                    true,
                    CityWorkClosureFactory.CreateFurnitureLvUpButton(workCfg, self.cellTile, self),
                    CityWorkClosureFactory.CreateDisableButton())
                buttonData:SetNodeName("p_btn_upgrade"):SetPriority(100)
                table.insert(buttonDataList, buttonData)
            end
        elseif workType == CityWorkType.ResourceProduce then
            local buttonData = CityUtils.CircleMenuSimpleButtonData(workCfg:CircleMenuIcon(),
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateResGenButton(self.cellTile, self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        elseif workType == CityWorkType.Process then
            local buttonData = CityUtils.CircleMenuSimpleButtonData(workCfg:CircleMenuIcon(),
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateProcessButton(self.cellTile, self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        elseif workType == CityWorkType.Incubate then
            local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_incubate",
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateHatchEggButton(self.cellTile, self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        elseif workType == CityWorkType.MaterialProcess then
            local buttonData = CityUtils.CircleMenuSimpleButtonData(workCfg:CircleMenuIcon(),
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateMaterialProcessButton(self.cellTile, self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        end
        ::continue::
    end

    if CityUtils.IsBuildMaster(furnitureConfig:Type()) then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_build_02",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateBuildMaterButton(self.cellTile, self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:MainFurnitureType() then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_manage",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateMainFurnitureButton(self.cellTile, self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)

        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.ConstMain:RadarSystemSwitch()) then
            local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_radar",
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateRaderButton(self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        end

        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.ConstMain:CastleSkinSystemSwitch()) then
            local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_pet_level",
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateCastleSkinButton(self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        end
    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:HotSpringFurniture() then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_pet_od",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateMobileUnitButton(self.cellTile, self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:StockRoomFurniture() then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_storehouse",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateStoreroomButton(self.cellTile, self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:TemperatureBooster() then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_temp",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateHeaterButton(self.cellTile, self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == CityFurnitureTypeNames["1002601"] then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_gacha",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateGachaButton(self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == 1004201 then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_pvp",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateReplicaPVPButton(self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == 1003501 then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_suitproduce",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateEquipMakingButton(self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)
    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:CityWallFurnitureType() then
        local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_common_icon_defence",
            CircleMenuButtonConfig.ButtonBacks.BackNormal,
            true,
            CityWorkClosureFactory.CreateCityDefenceButton(self),
            CityWorkClosureFactory.CreateDisableButton())
        table.insert(buttonDataList, buttonData)

        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.ConstMain:CastleSkinSystemSwitch()) then
            local buttonData = CityUtils.CircleMenuSimpleButtonData("sp_comp_icon_work_pet_level",
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                true,
                CityWorkClosureFactory.CreateCastleSkinButton(self),
                CityWorkClosureFactory.CreateDisableButton())
            table.insert(buttonDataList, buttonData)
        end

    elseif furnitureConfig:Type() == ConfigRefer.CityConfig:TrainingDummyFurniture() then
        local showTaskId = ConfigRefer.HuntingConst:HuntingCircleMenuBtnShow()
        local unlockTaskId = ConfigRefer.HuntingConst:HuntingCircleMenuBtnUnlock()
        local TaskItemDataProvider = require("TaskItemDataProvider")
        local showTask = TaskItemDataProvider.new(showTaskId)
        local unlockTask = TaskItemDataProvider.new(unlockTaskId)
        local show = showTaskId == 0 or showTask:IsTaskFinished()
        local unlock = unlockTaskId == 0 or unlockTask:IsTaskFinished()
        if show then
            local icon = ConfigRefer.HuntingConst:HuntingBubbleIcon()
            if Utils.IsNullOrEmpty(icon) then
                icon = "sp_item_icon_debris_egril"
            end
            local buttonData = CityUtils.CircleMenuSimpleButtonData(icon,
                CircleMenuButtonConfig.ButtonBacks.BackNormal,
                unlock,
                CityWorkClosureFactory.CreateCityHuntingButton(self),
                CityWorkClosureFactory.CreateCityHuntingDisableButton())
            table.insert(buttonDataList, buttonData)
        end
    end

    if not workTypeCheck[CityWorkType.FurnitureLevelUp] then
        if furnitureConfig:Type() ~= 1004201 and furnitureConfig:Type() ~= 1003501 then
            table.insert(buttonDataList, self:GetDetailEnterButton())
        end
    end

    local petInfos = nil
    if not furniture:IsBuildMaster() and not furniture:IsHotSpring() then
        local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
        if petIdMap then
            petInfos = {}
            for petId, _ in pairs(petIdMap) do
                local pet = ModuleRefer.PetModule:GetPetByID(petId)
                ---@type CommonPetIconBaseData
                local info = {
                    id = petId,
                    cfgId = pet.ConfigId,
                    onClick = function()
                        self:ExitToIdleState()
                        local workTimeFunc = nil
                        if self.city.petManager.cityPetData[petId] then
                            workTimeFunc = Delegate.GetOrCreate(self.city.petManager, self.city.petManager.GetRemainWorkDesc)
                        end
                        ---@type CityPetDetailsTipUIParameter
                        local param = {
                            id = petId,
                            cfgId = pet.ConfigId,
                            Level = pet.Level,
                            removeFunc = nil,
                            workTimeFunc = workTimeFunc,
                            benefitFunc = nil,
                            rectTransform = nil,
                        }
                        g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, param)
                        self.city.petManager:BITraceTipsOpen(furniture.singleId)
                    end,
                    selected = false,
                    level = pet.Level,
                    rank = pet.RankLevel,
                }
                table.insert(petInfos, info)
            end
        end
    end

    table.sort(buttonDataList, function(a, b)
        return a.priority > b.priority
    end)

    return CircleMemuUIParam.new(self.city:GetCamera(), self.cellTile:GetWorldCenter(), self.cellTile:GetName(), buttonDataList):SetLevel(furnitureConfig:Level()):SetPetInfo(petInfos)
end

---Obsolete
function CityStateFurnitureSelect:CreateSelector()
    self.handler = self.city.createHelper:Create(self.cellTile:GetSelectorPrefabName(), self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnSelectorCreated), nil, 0, true)
end

function CityStateFurnitureSelect:DeleteSelector()
    if self.handler then
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    self.selector = nil
end

---@param go CS.UnityEngine.GameObject
function CityStateFurnitureSelect:OnSelectorCreated(go, userdata)
    if go == nil then
        g_Logger.Error("Load city_map_building_selector failed!")
        return
    end

    local cell = self.cellTile:GetCell()
    local behaviourName = self.cellTile:GetSelectorBehaviourName()
    if behaviourName == "CityBuildingSelector" then
        ---@type CityBuildingSelector
        self.selector = go:GetLuaBehaviour(behaviourName).Instance
        self.selector:Init(self.city, cell.x, cell.y, cell.sizeX, cell.sizeY, cell)
    elseif behaviourName == "CityCreepSweeperFurnitureSelector" then
        ---@type CityCreepSweeperFurnitureSelector
        local selector = go:GetLuaBehaviour(behaviourName).Instance
        local sweeperConfig = ModuleRefer.CityCreepModule:GetSweeperConfigByFurnitureLevelId(self.cellTile:GetCell():ConfigId())
        selector:Init(self.city, cell.x, cell.y, cell.sizeX, cell.sizeY, sweeperConfig:SweepSizeX(), sweeperConfig:SweepSizeY(), self.cellTile:GetCell())
        self.selector = selector
    elseif behaviourName == "CityAutoCollectBoxFurnitureSelector" then
        ---@type CityAutoCollectBoxFurnitureSelector
        local selector = go:GetLuaBehaviour(behaviourName).Instance
        selector:Init(self.city, cell.x, cell.y, cell.sizeX, cell.sizeY, cell)
        self.selector = selector
    end
end

function CityStateFurnitureSelect:OnFurnitureNormalProduceMediatorExit(uiMediatorName)
    if uiMediatorName == UIMediatorNames.CityFurnitureConstructionProcessUIMediator
            or uiMediatorName == UIMediatorNames.CityCitizenResourceAutoCollectMediator
            or uiMediatorName == UIMediatorNames.CityFurnitureConstructionSynthesizeUIMediator
    then
        self:ExitToIdleState()
    end
end

---@param furniture CityFurnitureTile
function CityStateFurnitureSelect:FocusOnTarget(furniture)
    local typeConfig = furniture:GetFurnitureTypesCell()
    if not typeConfig or typeConfig:SelectedFocus() == CityFurnitureTypesSelectedFocusType.None then
        return
    end

    if typeConfig:SelectedFocus() ~= CityFurnitureTypesSelectedFocusType.None then
        if not furniture:ShouldShowEntryBubble() then
            self:DOFocus(furniture)
        else
            self.queuedTask:WaitEvent(EventConst.CITY_FURNITURE_ENTRY_BUBBLE_LOADED, nil, Delegate.GetOrCreate(self, self.CheckToFocus)):DoAction(Delegate.GetOrCreate(self, self.DOFocusCurrentTile)):Start()
        end
    end
end

---@param tile CityFurnitureTile
function CityStateFurnitureSelect:CheckToFocus(tile)
    return self.cellTile ~= nil and self.cellTile == tile
end

---@param tile CityFurnitureTile
function CityStateFurnitureSelect:DOFocus(tile)
    local go = tile.tileView.root
    if Utils.IsNull(go) then return end

    self.city:MoveGameObjIntoCamera(go, 0.25, CityConst.FullScreenCameraSafeArea)
end

function CityStateFurnitureSelect:DOFocusCurrentTile()
    self:DOFocus(self.cellTile)
end

---@param tile CityFurnitureTile
function CityStateFurnitureSelect:CollectFurnitureProcessOutput(tile)
    local castleFurniture = tile:GetCastleFurniture()
    if castleFurniture == nil then return false end
    if castleFurniture.ProcessInfo.ConfigId == 0 then return false end
    return false
end

---@param tile CityFurnitureTile
function CityStateFurnitureSelect:CollectFurnitureCollectOutput(tile)
    local castleFurniture = tile:GetCastleFurniture()
    if castleFurniture == nil then return false end
    return false
end

---@param tile CityFurnitureTile
function CityStateFurnitureSelect:TryConfirmLevelUpFurniture(tile)
    local castleFurniture = tile:GetCastleFurniture()
    if castleFurniture == nil then return false end
    if castleFurniture.LevelUpInfo.Working and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
        self.city.furnitureManager:RequestClaimFurnitureLevelUp(tile:GetCell().singleId)
        return true
    end
    return false
end

function CityStateFurnitureSelect:PlayIndoorFurnitureSound()
    local furniture = self.cellTile:GetCell()
    if not furniture then return end

    if not furniture:IsInBuilding() then return end

    local typCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
    if typCfg.IndoorClickSound and typCfg:IndoorClickSound() > 0 then
        g_Game.SoundManager:PlayAudio(typCfg:IndoorClickSound())
    end
end

function CityStateFurnitureSelect:PlayNormalSelectSound()
    local furnitureTile = self.cellTile
    if furnitureTile ~= nil and furnitureTile.tileView then
        local mainAssets = furnitureTile.tileView:GetMainAssets()
        local mainAsset, _ = next(mainAssets)
        if mainAsset and Utils.IsNotNull(furnitureTile.tileView.gameObjs[mainAsset]) then
            g_Game.SoundManager:Play("sfx_ui_building_select", furnitureTile.tileView.gameObjs[mainAsset])
        end
    else
        g_Game.SoundManager:Play("sfx_ui_building_select")
    end
end

---@param city City
---@param batchEvt {Event:string, furnitureId:number}
function CityStateFurnitureSelect:OnFurnitureFinished(city, batchEvt)
    if city ~= self.city then return end
    if self.cellTile == nil then return end
    if batchEvt.furnitureId ~= self.cellTile:GetCell().singleId then return end

    self:ExitToIdleState()
end

return CityStateFurnitureSelect