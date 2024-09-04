local CastleBuildingStatus = wds.enum.CastleBuildingStatus
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CityUtils = {}

---@param city City
---@param cell CityGridCell|CityFurniture|CityLegoBuilding
function CityUtils.GetCityCellCenterPos(city, cell)
    local CityLegoBuilding = require("CityLegoBuilding")
    if cell:is(CityLegoBuilding) then
        return city:GetWorldPositionFromCoord((2 * cell.x + cell.sizeX - 1) / 2, (2 * cell.z + cell.sizeZ - 1) / 2)
    else
        return city:GetWorldPositionFromCoord((2 * cell.x + cell.sizeX - 1) / 2, (2 * cell.y + cell.sizeY - 1) / 2)
    end
end

---@return boolean
function CityUtils.IsStatusReadyForFurniture(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Normal
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeReady
        or status == CastleBuildingStatus.CastleBuildingStatus_Upgrading
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
        or status == CastleBuildingStatus.CastleBuildingStatus_Upgraded
        or status == CastleBuildingStatus.CastleBuildingStatus_Repairing
end

---@return boolean
function CityUtils.IsStatusWaitWorker(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Created
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeReady
        or status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
end

---@param status wds.enum.CastleBuildingStatus
---@param cellTile CityCellTile
---@return boolean
function CityUtils.IsStatusOwnWorker(status, cellTile)
    return status == CastleBuildingStatus.CastleBuildingStatus_Constructing or status == CastleBuildingStatus.CastleBuildingStatus_Upgrading
end

---@return boolean
function CityUtils.IsStatusWaitRibbonCutting(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Constructed
        or status == CastleBuildingStatus.CastleBuildingStatus_Upgraded
end

---@return boolean
function CityUtils.IsStatusReady(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Normal
end

function CityUtils.IsStatusUpgrade(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Upgrading
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeReady
end

function CityUtils.IsStatusCreateWaitWorker(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Created
        or status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
end

function CityUtils.IsRepairing(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Repairing
end

function CityUtils.IsConstruction(status)
    return status == CastleBuildingStatus.CastleBuildingStatus_Constructed
        or status == CastleBuildingStatus.CastleBuildingStatus_Constructing
        or status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
        or status == CastleBuildingStatus.CastleBuildingStatus_Upgraded
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeReady
        or status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
        or status == CastleBuildingStatus.CastleBuildingStatus_Upgrading
end

---@param icon string
---@param back string
---@param enable boolean
---@param func fun()
---@param failedFunc fun()|nil
---@param extraData ImageTextPair[]
---@return CircleMenuSimpleButtonData
function CityUtils.CircleMenuSimpleButtonData(icon, back, enable, func, failedFunc, extraData, name)
    local CircleMenuSimpleButtonData = require("CircleMenuSimpleButtonData")
    return CircleMenuSimpleButtonData.new(icon, back, enable, func, failedFunc, extraData, name)
end

---@param city City
---@param cell CityGridCell
---@param useCenterGridEdge boolean
---@return CS.UnityEngine.Vector3 @wordPosition
function CityUtils.SuggestCellCenterPositionWithHeight(city, cell, height, useCenterGridEdge)
    local position
    if useCenterGridEdge then
        position = city:GetCenterGridEdgeWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    else
        position = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    end
    position.y = position.y + height
    return position
end

---@return CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
function CityUtils.GetPooledGameObjectCreateHelper()
    if not CityUtils.helper then
        CityUtils.helper = PooledGameObjectCreateHelper.Create("City")
    end
    return CityUtils.helper
end

---@param trigger CityTrigger
---@param cellTile CityCellTile|CityFurnitureTile
function CityUtils.BindClickCellClosureToCityTrigger(trigger, cellTile)
    if not trigger then return end
    if not cellTile then return end
    local CityCellTile = require("CityCellTile")
    local CityFurnitureTile = require("CityFurnitureTile")

    trigger:SetOnTrigger(function()
        local city = cellTile:GetCity()
        if city and city.stateMachine and city.stateMachine.currentState then
            if city.stateMachine.currentState.OnClickCellTile and cellTile:is(CityCellTile) then
                city.stateMachine.currentState:OnClickCellTile(cellTile)
            elseif city.stateMachine.currentState.OnClickFurnitureTile and cellTile:is(CityFurnitureTile) then
                city.stateMachine.currentState:OnClickFurnitureTile(cellTile)
            end
        end
    end, cellTile)
end

---@param city City
function CityUtils.TryLookAtToCityCoord(city, x, y, duration, callback, forceLookAt)
    if city == nil then return end
    local camera = city:GetCamera()
    local KingdomMapUtils = require("KingdomMapUtils")
    if camera == nil then
        camera = KingdomMapUtils.GetBasicCamera()
    end
    if camera == nil then return end
    if x == nil or y == nil then return end

    if KingdomMapUtils.IsCityState() then
        local worldPos = city:GetCenterWorldPositionFromCoord(x, y, 1, 1)
        local camera = city:GetCamera()
        camera:LookAt(worldPos, duration, callback)
    else
        local kingdomScene = KingdomMapUtils.GetKingdomScene()
        if not kingdomScene then return end
        if not kingdomScene:CheckFocusTileIsCity() and not forceLookAt then
            kingdomScene:FocusToMyCityTile()
            return
        end

        local QueuedTask = require("QueuedTask")
        local EventConst = require("EventConst")
        local queuedTask = CityUtils.CityLookAtTask or QueuedTask.new()
        queuedTask:Release()
        queuedTask:WaitEvent(EventConst.CITY_SET_ACTIVE, nil, function(flag, city2)
            return flag and city2 == city
        end)
        queuedTask:DoAction(function()
            local worldPos = city:GetCenterWorldPositionFromCoord(x, y, 1, 1)
            local camera = city:GetCamera()
            camera:LookAt(worldPos, duration, callback)
        end)
        queuedTask:Start()
        kingdomScene.stateMachine:WriteBlackboard("City_ManualCoord", {x = x, y = y})
        kingdomScene:ReturnMyCity()
    end
end

---@return CityElementResourceConfigCell[]
function CityUtils.GetElementResourceCfgsByType(eleResType)
    local ret = {}
    local ConfigRefer = require("ConfigRefer")
    for _, cfg in ConfigRefer.CityElementResource:pairs() do
        if cfg:Type() == eleResType then
            table.insert(ret, cfg)
        end
    end
    table.sort(ret, function(l, r)
        if l:Quality() == r:Quality() then
            return l:Star() < r:Star()
        end
        return l:Quality() < r:Quality()
    end)
    return ret
end


CityUtils.CityBaseTypeCfgId = 1001
function CityUtils.SaveBaseLevelToPrefs()
    local city = require('ModuleRefer').CityModule.myCity
    if not city then
        return
    end
    local furnitureManager = city.furnitureManager
    if not furnitureManager or not furnitureManager:IsDataReady() then
        return
    end
    local baseLvl = 0
    local furniture = furnitureManager:GetFurnitureByTypeCfgId(CityUtils.CityBaseTypeCfgId)
    if furniture then
        baseLvl = furniture.level
    end
    
    g_Game.PlayerPrefsEx:SetIntByUid("MainBaseLvl",baseLvl)
    g_Game.PlayerPrefsEx:SetInt("MainBaseLvl",baseLvl)
    
end

---@return number
function CityUtils.GetBaseLevel()
    local moduleManager = g_Game.ModuleManager
    if not moduleManager then
        return CityUtils.GetLevelFromPrefs()
    end
    local baseLvl = 0
    local cityModule = moduleManager.moduleMap["CityModule"]
    if cityModule then
        local city = cityModule.myCity
        if not city then
            goto GetBaseLevel_Fin
        end
        local furnitureManager = city.furnitureManager
        if not furnitureManager or not furnitureManager:IsDataReady() then
            goto GetBaseLevel_Fin
        end
        local furniture = furnitureManager:GetFurnitureByTypeCfgId(CityUtils.CityBaseTypeCfgId)
        if furniture then
            baseLvl = furniture.level
        end
    end
    ::GetBaseLevel_Fin::
    if baseLvl > 0 then
        g_Game.PlayerPrefsEx:SetIntByUid("MainBaseLvl",baseLvl)
        g_Game.PlayerPrefsEx:SetInt("MainBaseLvl",baseLvl)
    else
        baseLvl = CityUtils.GetBaseLevelFromPrefs()
    end
    return baseLvl
end

function CityUtils.GetBaseLevelFromPrefs()
    local playerId = g_Game.PlayerPrefsEx:GetPlayerID()
    if playerId ~= nil and playerId > 0 then
        return g_Game.PlayerPrefsEx:GetIntByUid("MainBaseLvl",0)
    else
        return g_Game.PlayerPrefsEx:GetInt("MainBaseLvl",0)
    end
end

function CityUtils.IsBuildMaster(furType)
    local ConfigRefer = require("ConfigRefer")
    for i = 1, ConfigRefer.CityConfig:BuildingMasterStatuesLength() do
        if furType == ConfigRefer.CityConfig:BuildingMasterStatues(i) then
            return true
        end
    end
    return false
end

function CityUtils.OpenCommonConfirmUI(title, content, callback)
    ---@type CommonConfirmPopupMediatorParameter
    local data = {
        styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn,
        title = title,
        content = content,
        onConfirm = callback,
    }
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

function CityUtils.OpenCommonSimpleTips(content, rectTransform, arrowMode)
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = rectTransform
    tipParameter.text = content
    tipParameter.arrowMode = arrowMode or 0
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

function CityUtils.AsyncOpenUI(uiName, uiParam)
    local UIAsyncDataProvider = require("UIAsyncDataProvider")
    local provider = UIAsyncDataProvider.new()
    local name = uiName
    local timing = UIAsyncDataProvider.PopupTimings.AnyTime
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
    local checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    provider:Init(name, timing, check, checkFailedStrategy, false, uiParam)
    local UIManager = require("UIManager")
    provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

return CityUtils