local KingdomMapUtils = require('KingdomMapUtils')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require('UIMediatorNames')
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local SlgUtils = require('SlgUtils')
local MapUtils = CS.Grid.MapUtils
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

---@class KingdomTouchInfoOperation
local KingdomTouchInfoOperation = class("TouchInfoOperation")

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.VisitCity(tile)
    local city = ModuleRefer.CityModule:GetCity(tile.entity.ID)
    if city then
        g_Game.UIManager:CloseByName(UIMediatorNames.WorldEventRecordMediator)
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY)
    end
end

---@param tile MapRetrieveResult
---@param clickTrans CS.UnityEngine.Transform
---@param purpose wrpc.MovePurpose
---@param filter nil|fun(troopInfo:TroopInfo):boolean
function KingdomTouchInfoOperation.MoveTroopToTile(tile, clickTrans, purpose, filter)
    if not tile then
        return
    end
    if not purpose or type(purpose) ~= "number" or purpose < wrpc.MovePurpose.MovePurpose_Move or purpose > wrpc.MovePurpose.MovePurpose_ClearCenterSlgCreep then
        purpose = wrpc.MovePurpose.MovePurpose_Move
    end
    if tile.entity then
        KingdomTouchInfoOperation.SendTroopToEntityQuickly(tile.entity, false, false, purpose, nil, filter)
    else        
        ---@type HUDSelectTroopListData
        local selectTroopData = {}
        selectTroopData.tile = tile
        selectTroopData.purpose = purpose
        selectTroopData.isSE = false
        selectTroopData.needPower = -1
        selectTroopData.recommendPower = -1
        selectTroopData.costPPP = 0
        selectTroopData.filter = filter
        require("HUDTroopUtils").StartMarch(selectTroopData)
    end

end

function KingdomTouchInfoOperation.StartAssembleAttack(tile)
     --Send Troop
     if not tile then
        return
    end
    
    ---@type HUDSelectTroopListData
    local selectTroopData = {}
    selectTroopData.tile = tile
    selectTroopData.entity = tile.entity
    selectTroopData.isSE = false
    selectTroopData.needPower = -1
    selectTroopData.recommendPower = -1
    selectTroopData.costPPP = 0
    selectTroopData.isAssemble = true
    require("HUDTroopUtils").StartMarch(selectTroopData)
end


---@param entity wds.ResourceField | wds.Village | wds.SlgInteractor
---@param isEscrow boolean 是否是托管
---@param isEscrowToggleOn boolean
---@param purpose wrpc.MovePurpose
---@param noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil
---@param filter nil|fun(troopInfo:TroopInfo):boolean
function KingdomTouchInfoOperation.SendTroopToEntityQuickly(entity, isEscrow, isEscrowToggleOn, purpose, noEscrowChoice, filter)
    if not entity then return end
    if isEscrow and type(isEscrow) ~= "boolean" then
        isEscrow = false
    end
    
    if entity.TypeHash == DBEntityType.ResourceField
        or entity.TypeHash == DBEntityType.Village
        or entity.TypeHash == DBEntityType.Pass
        or entity.TypeHash == DBEntityType.BehemothCage
        or entity.TypeHash == DBEntityType.CommonMapBuilding
        or entity.TypeHash == DBEntityType.DefenceTower
        or entity.TypeHash == DBEntityType.EnergyTower
    then
        local isCollectingRes = entity.TypeHash == DBEntityType.ResourceField
        KingdomTouchInfoOperation.SendTroopToMapBuilding(entity, isCollectingRes, isEscrow, isEscrowToggleOn, noEscrowChoice, purpose, filter)
    else
        KingdomTouchInfoOperation.SendTroopToEntity(entity,purpose or wrpc.MovePurpose.MovePurpose_Move, filter, nil, isEscrow,false, false, isEscrowToggleOn, nil, nil, noEscrowChoice)
    end
end

function KingdomTouchInfoOperation.SendTroopToWorldEventAndAutoFinish(entity)
    if not entity then return end
    KingdomTouchInfoOperation.SendTroopToEntity(entity,wrpc.MovePurpose.MovePurpose_AutoClearExpedition, nil, nil, false,false, false, false, true)
end


---@param entity wds.ResourceField|wds.Village|wds.BehemothCage|wds.EnergyTower|wds.DefenceTower|wds.CommonMapBuilding
---@param isEscrow boolean 是否是托管
---@param isEscrowToggleOn boolean
---@param noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil
---@param filter nil|fun(troopInfo:TroopInfo):boolean
function KingdomTouchInfoOperation.SendTroopToMapBuilding(entity, isCollectingRes, isEscrow, isEscrowToggleOn, noEscrowChoice, purpose, filter, autoFinish, showBack)
    ---@type fun(troopInfo:TroopInfo):boolean
    local internalFileter
    if entity then
        local buildingEntity = entity
        internalFileter = function(troopInfo)
            if troopInfo.entityData and not SlgUtils.IsTroopSelectable(troopInfo.entityData) then
                return false
            end
            if troopInfo.troopId then
                if buildingEntity.Army 
                    and ( buildingEntity.Army.PlayerTroopIDs:Count() > 0
                    or buildingEntity.Army.PlayerOnRoadTroopIDs:Count() > 0)
                then
                    if (buildingEntity.Army.PlayerTroopIDs[troopInfo.troopId] or buildingEntity.Army.PlayerOnRoadTroopIDs[troopInfo.troopId]) then
                        return false
                    end
                end
                if buildingEntity.Strengthen
                    and ( buildingEntity.Strengthen.PlayerTroopIDs:Count() > 0
                    or buildingEntity.Strengthen.PlayerOnRoadTroopIDs:Count() > 0)
                then
                    if (buildingEntity.Strengthen.PlayerTroopIDs[troopInfo.troopId] or buildingEntity.Strengthen.PlayerOnRoadTroopIDs[troopInfo.troopId]) then
                        return false
                    end
                end
            end
            if filter and not filter(troopInfo) then
                return false
            end
            return true
        end
    end
    internalFileter = internalFileter or filter
    
    KingdomTouchInfoOperation.SendTroopToEntity(entity, purpose or wrpc.MovePurpose.MovePurpose_Move,internalFileter, nil, isEscrow, false, isCollectingRes, isEscrowToggleOn, autoFinish, showBack, noEscrowChoice)
end


---@param entity wds.ResourceField | wds.Village | wds.SlgInteractor | wds.BehemothCage
---@param purpose number @wrpc.MovePurpose
---@param filter nil|fun(troopInfo:TroopInfo):boolean
---@param overrideItemClickGoFunc nil|fun(data:HUDSelectTroopListItemData)
---@param isEscrow boolean 托管
---@param isAssemble boolean 集结
---@param isCollectingRes boolean 采集
---@param isEscrowToggleOn boolean
---@param autoFinish boolean
---@param noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil
function KingdomTouchInfoOperation.SendTroopToEntity(entity,purpose,filter,overrideItemClickGoFunc, isEscrow, isAssemble, isCollectingRes, isEscrowToggleOn,autoFinish, showBack,noEscrowChoice)
    if not entity then
        g_Logger.Error("empty entity")
        return
    end
    local isSE,needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(entity)
    ---@type HUDSelectTroopListData
    local selectTroopData = {}
    selectTroopData.entity = entity
    selectTroopData.purpose = purpose
    selectTroopData.isSE = isSE
    selectTroopData.needPower = needPower
    selectTroopData.recommendPower = recommendPower
    selectTroopData.costPPP = costPPP
    selectTroopData.filter = filter
    selectTroopData.overrideItemClickGoFunc = overrideItemClickGoFunc
    selectTroopData.isEscrow = isEscrow
    selectTroopData.escrowToggleOn = isEscrowToggleOn
    selectTroopData.isAssemble = isAssemble
    selectTroopData.isCollectingRes = isCollectingRes
    selectTroopData.showAutoFinish = autoFinish
    selectTroopData.noEscrowChoice = noEscrowChoice
    if entity.TypeHash == DBEntityType.SlgInteractor then
        if isSE then
            selectTroopData.interactorId = entity.Id
            selectTroopData.tid = KingdomMapUtils.GetSEMapInstanceIdInEntity(entity)
        else
            --收集物显示部队自动返回配置
            selectTroopData.showBack = true
        end
    else
        selectTroopData.showBack = showBack
    end
    require("HUDTroopUtils").StartMarch(selectTroopData)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.LookAt(tile)
    if not KingdomMapUtils.IsMapState() then
        return
    end
    
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local lookAtSize = ConfigRefer.ConstMain:ChooseCameraDistance()
    local size = lookAtSize or KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    local tileX, tileZ
    if tile.entity and tile.entity.MapBasics then
        local pos = tile.entity.MapBasics.Position
        tileX, tileZ = KingdomMapUtils.ParseBuildingPos(pos)
    else
        tileX, tileZ = tile.X, tile.Z
    end

    local lod = KingdomMapUtils.GetCameraLodData():CalculateLod(lookAtSize)
    g_Game.EventManager:TriggerEvent(EventConst.WAIT_AND_SHOW_UNIT, tileX, tileZ, lod)

    mapSystem:ForceLoadHeightMap(tileX, tileZ)
    local position = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, mapSystem)
    KingdomMapUtils.MoveAndZoomCamera(position, size)
end

---@param armyData wds.Army
function KingdomTouchInfoOperation.HasArmySituationInfosCanShow(armyData)
   if not armyData then return false end
   if armyData.DummyTroopInitFinish then
    local infos = armyData.Situation and armyData.Situation.Infos
    if table.isNilOrZeroNums(infos) then return false end
    for _, info in pairs(infos) do
        if info.Attackers and info.Attackers:Count() > 0 then
            return true
        end
        if info.Defender then
            return true
        end
    end  
    return false
    else
        return not table.isNilOrZeroNums(armyData.DummyTroopIDs)
    end
end

---@param param {tile:MapRetrieveResult, entityPath:"DBEntityPath"}
function KingdomTouchInfoOperation.OpenWarDetailUIMediator(param)
    g_Game.UIManager:Open(UIMediatorNames.KingdomConstructionWarDetaillUIMediator,
    {
        buildEntity = param.tile.entity,
        entityPath = param.entityPath
    }
    )
end

function KingdomTouchInfoOperation.OpenReinforceUI(tile)
    g_Game.UIManager:Open(UIMediatorNames.ReinforceMediator, {tile = tile})
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.SendReinforceTroop(tile)
    KingdomTouchInfoOperation.MoveTroopToTile(tile, nil, wrpc.MovePurpose.MovePurpose_Reinforce)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.OpenDefenceUI(tile)
    g_Game.UIManager:Open(UIMediatorNames.DefenceMediator)
end

function KingdomTouchInfoOperation.LeaveTroopFrom(entity)
    if entity and entity.Army then
        local memberInfo = ModuleRefer.MapBuildingTroopModule:GetMyTroop(entity.Army)
        if not memberInfo then return end
        ModuleRefer.MapBuildingTroopModule:LeaveTroopFrom(entity.ID, memberInfo.Id)
    end
end

function KingdomTouchInfoOperation.BackHomeFrom(entity)
    if entity and entity.Army then
        local memberInfo = ModuleRefer.MapBuildingTroopModule:GetMyTroop(entity.Army)
        if not memberInfo then return end
        ModuleRefer.SlgModule:ReturnToHome(memberInfo.Id)
    end
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.ShowTroopInfo(tile)
    ModuleRefer.MapBuildingTroopModule:ShowTroopInfo(tile)
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
---@param skipConfirm boolean
function KingdomTouchInfoOperation.RemoveMapBuilding(tile, transform ,skipConfirm)
    local action = function()
        KingdomTouchInfoOperation.RemoveMapBuildingById(tile.entity.ID, tile.entity.TypeHash)
        return true
    end
    if skipConfirm and type(skipConfirm) == "boolean" then
        action()
        return
    end
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.Get("alliance_jz_shifouchaichu")
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.onConfirm = action
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
---@param skipConfirm boolean
function KingdomTouchInfoOperation.RemoveBehemothDevice(tile, transform ,skipConfirm)
    local action = function()
        ModuleRefer.AllianceModule.Behemoth:RemoveBehemothDevice(transform, tile.entity.ID)
        return true
    end
    if skipConfirm and type(skipConfirm) == "boolean" then
        action()
        return
    end
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.Get("alliance_jz_shifouchaichu")
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.onConfirm = action
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
---@param skipConfirm boolean
function KingdomTouchInfoOperation.RemoveBehemothSummoner(tile, transform ,skipConfirm)
    local action = function()
        ModuleRefer.AllianceModule.Behemoth:RemoveBehemothSummoner(transform, tile.entity.ID)
        return true
    end
    if skipConfirm and type(skipConfirm) == "boolean" then
        action()
        return
    end
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.Get("alliance_jz_shifouchaichu")
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.onConfirm = action
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
function KingdomTouchInfoOperation.SummonBehemothOnEntity(tile, transform)
    local summoner = ModuleRefer.AllianceModule.Behemoth:GetSummonerInfo()
    local currentBehemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    if not summoner or not currentBehemoth then
        return
    end
    ModuleRefer.AllianceModule.Behemoth:SummonBehemoth(transform, summoner:GetBuildingEntityId(), ConfigRefer.AllianceConsts:SummonBehemothRefFlexibleMapBuilding() ,tile.entity.ID)
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
function KingdomTouchInfoOperation.TransformToAllianceCenter(tile, transform)
    ---@type AllianceCenterTransformMediatorParameter
    local param = {}
    param.trySelectVillageId = tile and tile.entity and tile.entity.ID
    g_Game.UIManager:Open(UIMediatorNames.AllianceCenterTransformMediator, param)
	--local village = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
	--if not village then
	--	ModuleRefer.AllianceModule:TransformAllianceCenter(transform, tile.entity.ID)
	--elseif village.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
	--	ModuleRefer.AllianceModule:ChangeAllianceCenter(transform, tile.entity.ID)
	--end
end

---@param tile MapRetrieveResult
---@param transform CS.UnityEngine.Transform
function KingdomTouchInfoOperation.TransformToAllianceCenterSpeedUp(tile, transform)
	KingdomTouchInfoOperation.ConstructingReinforce(tile)
end

function KingdomTouchInfoOperation.RemoveMapBuildingById(uniqueId, typeId)
    local message = nil
    if typeId == DBEntityType.EnergyTower then
        message = require("RemoveEnergyTowerParameter").new()
    elseif typeId == DBEntityType.DefenceTower then
        message = require("RemoveDefenceTowerParameter").new()
    elseif typeId == DBEntityType.TransferTower then
        message = require("RemoveTransferTowerParameter").new()
    elseif typeId == DBEntityType.MobileFortress then
        message = require("RemoveMobileFortressParameter").new()
    end

    message.args.TowerID = uniqueId
    message:SendWithFullScreenLock()
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.SendStrengthenTroop(tile)
    --Send Troop
    KingdomTouchInfoOperation.MoveTroopToTile(tile,nil, wrpc.MovePurpose.MovePurpose_Strengthen)
end

function KingdomTouchInfoOperation.IsConstructingReinforceFunctionOn()
    return true
end

function KingdomTouchInfoOperation.IsTransformToAllianceCenterConstructingReinforceFunctionOn()
    return false
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.ConstructingReinforce(tile)
    if not KingdomTouchInfoOperation.IsConstructingReinforceFunctionOn() then
        return
    end
    ModuleRefer.MapBuildingTroopModule:FocusBuilding(tile.X, tile.Z, function()
        ---@type MapBuildingParameter
        local param = {}
        param.EntityID = tile.entity.ID
        param.Owner = tile.entity.Owner
        param.MapBasics = tile.entity.MapBasics
        param.Army = nil
        param.StrengthenArmy = tile.entity.Strengthen
        param.Construction = tile.entity.Construction
        param.EntityTypeHash = tile.entity.TypeHash
        param.IsStrengthen = true
        if tile.entity.TypeHash == DBEntityType.Village then
            param.VillageTransformInfo = tile.entity.VillageTransformInfo
        end
        g_Game.UIManager:Open(UIMediatorNames.MapBuildingTroopConstructionUIMediator, param)
    end)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.GoToBehemothActivity(tile)
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
    -- -----@type ActivityCenterOpenParam
    -- local param = {}
    -- param.tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
    -- g_Game.UIManager:Open(UIMediatorNames.ActivityCenterMediator, param)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.CheckClearCreepAt(tile)
    return ModuleRefer.MapCreepModule:GetCleanAlertTip(tile) == nil
end

function KingdomTouchInfoOperation.UnlockMist(mistID)
    ModuleRefer.MapFogModule:UnlockSingleMist(mistID)
end

function KingdomTouchInfoOperation.MistUnlockGoTo(mistID)
    ModuleRefer.MapFogModule:GoToMist(mistID)
end

function KingdomTouchInfoOperation.OpenRadar()
    ModuleRefer.RadarModule:SetRadarState(true)
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    local param = {isInCity = false, stack = basicCamera:RecordCurrentCameraStatus()}
    g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.MoveCity(tile)
    if KingdomMapUtils.IsMapState() then
        -- KingdomMapUtils.GetKingdomScene():MoveCity(tile.X, tile.Z)
        local coord = {X = tile.X, Y = tile.Z}
        ModuleRefer.KingdomPlacingModule:StartRelocate(ModuleRefer.PlayerModule:GetCastle().MapBasics.ConfID, ModuleRefer.RelocateModule.CanRelocate, coord)
    end
end

---@param param {entity:table, entityPath:"DBEntityPath"}
function KingdomTouchInfoOperation.OccupationHistory(param)
    if param and param.entityPath ==  DBEntityPath.Village then
        ---@type AllianceVillageOccupationHistoryMediatorParameter
        local parameter = {}
        parameter.village = param.entity
        g_Game.UIManager:Open(UIMediatorNames.AllianceVillageOccupationHistoryMediator, parameter)
    end
end

---@param param {tile:MapRetrieveResult, entityPath:"DBEntityPath"}
function KingdomTouchInfoOperation.OccupationGainDetail(param)
    if param and(param.entityPath ==  DBEntityPath.Village or param.entityPath == DBEntityPath.Pass) then
        ---@type AllianceVillageOccupationGainMediatorParameter
        local parameter = {}
        parameter.village = param.tile.entity
        g_Game.UIManager:Open(UIMediatorNames.AllianceVillageOccupationGainMediator, parameter)
    end
end

---@param tile MapRetrieveResult
function KingdomTouchInfoOperation.ProtectCastle(tile)
    ---@type UseResourceParam
    local param = {title = "protect_btn_castle_Protection"}
    param.items = {51021, 51022, 51023, 51024}
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, param)
end

return KingdomTouchInfoOperation
