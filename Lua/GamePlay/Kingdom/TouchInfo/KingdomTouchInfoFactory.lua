local MapUtils = CS.Grid.MapUtils
local Color = CS.UnityEngine.Color

local KingdomTouchInfoCompHelper = require('KingdomTouchInfoCompHelper')
local UIMediatorNames = require('UIMediatorNames')
local KingdomTouchInfoOperation = require('KingdomTouchInfoOperation')
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require("DBEntityType")
local KingdomTouchInfoHelper = require("KingdomTouchInfoHelper")
local TouchInfoDefine = require("TouchInfoDefine")
local DBEntityPath = require('DBEntityPath')
local EventConst = require("EventConst")
local TouchMenuHelper = require("TouchMenuHelper")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local I18N = require("I18N")
local ConfigRefer = require('ConfigRefer')
local GuideUtils = require("GuideUtils")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local ClientDataKeys = require("ClientDataKeys")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local KingdomTouchInfoMarkProvider = require("KingdomTouchInfoMarkProvider")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")
local MapFogDefine = require("MapFogDefine")


local TouchMenuCellLeagueDatum = require('TouchMenuCellLeagueDatum')
local TouchMenuCellPairDatum = require('TouchMenuCellPairDatum')
local TouchMenuCellProgressDatum = require('TouchMenuCellProgressDatum')

---@class KingdomTouchInfoFactory
local KingdomTouchInfoFactory = class("TouchInfoFactory")

KingdomTouchInfoFactory.ButtonIcons = {
    IconStrength = "sp_common_icon_details",
    IconDetails = "sp_common_icon_details",
    IconExplore = "sp_common_icon_details",
    IconMark = "sp_comp_icon_mark",
    IconUnmark = "sp_comp_icon_unmark",
}

KingdomTouchInfoFactory.ButtonBacks = {
    ConfirmBack = "sp_btn_circle_confirm",
    MainBack = "sp_btn_circle_main",
    NormalBack = "sp_btn_circle_sec",
    NegativeBack = "sp_btn_circle_negtive",
}

---@param tile MapRetrieveResult
---@param lod number
---@param context any
function KingdomTouchInfoFactory.CreateDataFromKingdom(tile, lod, context)
    local data
    if tile and tile.entity and tile.entity.TypeHash == DBEntityType.Village then
        local scene = g_Game.SceneManager.current
        local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(tile.X, tile.Z, KingdomMapUtils.GetMapSystem())
        if ModuleRefer.GuideModule:FirstClickGuide(ClientDataKeys.GameData.ClickVillage, pos, 6229) then
            return
        end
    end
    if tile.entity ~= nil then
        g_Logger.LogChannel('Kingdom','Select Kingdom Entity:' .. tile.entity.ID)
        if tile.entity.TypeHash == DBEntityType.CastleBrief then
            data = KingdomTouchInfoFactory.CreateCity(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.ResourceField then
            data = KingdomTouchInfoFactory.CreateResourceField(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.Village then
            data = KingdomTouchInfoFactory.CreateVillage(tile, lod, context)
        elseif tile.entity.TypeHash == DBEntityType.TransferTower then
            data = KingdomTouchInfoFactory.CreateTransferTower(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.DefenceTower then
            data = KingdomTouchInfoFactory.CreateDefenseTower(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.EnergyTower then
            data = KingdomTouchInfoFactory.CreateEnergyTower(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.SlgCreepTumorRemoverBuilding then
            data = KingdomTouchInfoFactory.CreateCreepRemover(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.SlgInteractor then
            data = KingdomTouchInfoFactory.CreateSlgInteractor(tile, lod)
        elseif tile.entity.TypeHash == DBEntityType.Pass then
            data = KingdomTouchInfoFactory.CreateGate(tile, lod,context)
        elseif tile.entity.TypeHash == DBEntityType.CommonMapBuilding then
            local config = ConfigRefer.FlexibleMapBuilding:Find(tile.entity.MapBasics.ConfID)
            if config then
                local bT = config:Type()
                if bT == FlexibleMapBuildingType.BehemothDevice then
                    data = KingdomTouchInfoFactory.CreateBehemothDevice(tile, lod,context)
                elseif bT == FlexibleMapBuildingType.BehemothSummoner then
                    data = KingdomTouchInfoFactory.CreateBehemothSummoner(tile, lod,context)
                end
            end
        elseif tile.entity.TypeHash == DBEntityType.SlgCreepTumor then
            if ModuleRefer.MapCreepModule:CreepExistsAt(tile.X, tile.Z) then
                data = KingdomTouchInfoFactory.CreateCreep(tile, lod)
            elseif ModuleRefer.MapCreepModule:HasAnyCreepOnCreepCenter(tile.entity) then
                data = KingdomTouchInfoFactory.CreateCreepByCenter(tile, lod)
            else
                data = KingdomTouchInfoFactory.CreateEmpty(tile, lod)
            end
        end
    elseif tile.playerUnit then
        local playerUnit = tile.playerUnit
        if playerUnit.TypeHash then
            if playerUnit.TypeHash == wds.PlayerMapCreep.TypeHash then
                data = KingdomTouchInfoFactory.CreateCreepTumor(tile, lod)
            elseif playerUnit.TypeHash == wds.SeEnter.TypeHash then
                data = KingdomTouchInfoFactory.CreatePlayerSlgInteractor(tile, lod)
            end
        else
            ModuleRefer.WorldRewardInteractorModule:ShowMenu(playerUnit)
        end
      
    else
        if ModuleRefer.MapCreepModule:CreepExistsAt(tile.X, tile.Z) then
            data = KingdomTouchInfoFactory.CreateCreep(tile, lod)
        else
            data = KingdomTouchInfoFactory.CreateEmpty(tile, lod)
        end
    end
    KingdomTouchInfoFactory.ShowTouchInfo(data)
end

---@param data TouchMenuUIDatum
function KingdomTouchInfoFactory.ShowTouchInfo(data)
    ModuleRefer.KingdomTouchInfoModule:Show(data)
end

---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateCity(tile, lod)
    local provider = require("KingdomTouchInfoProviderCastle").new()
    local mainWindow = provider:CreateBasicInfo(tile)
    local compsData = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, compsData, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end


---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateResourceField(tile, lod)
    local provider = require("KingdomTouchInfoProviderResourceField").new()
    
    local mainWindow = provider:CreateBasicInfo(tile)
    local compsData = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local tip = provider:CreateTipData(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, compsData, buttons, tip):SetPos(position, sizeX, sizeZ)
end


---@class VillageFastForwardToSelectTroopDelegate
---@field __name string

---@param tile MapRetrieveResult
---@param lod number
---@param context VillageFastForwardToSelectTroopDelegate|nil
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateGate(tile, lod, context)
    local provider = require("KingdomTouchInfoProviderGate")
    if context and context.__name and context.__name == "VillageFastForwardToSelectTroopDelegate" then
        local btnFlags = provider.GetKingdomTouchInfoProviderGateButtonFlags(tile.entity)
        if (btnFlags & provider.ButtonFlags.buttonManagedAttack) ~= 0 then
            provider.ManagedAttack(tile)
            return
        end
    end
    local action = function()
        local mainWindow = provider:CreateBasicInfo(tile)
        local secondWindow = provider:CreateDetailInfo(tile)
        local buttons = provider:CreateButtonInfo(tile)
        local tip = provider:CreateTipData(tile)
        local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
        if tip then
            local data = TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons), tip):SetPos(position, sizeX, sizeZ)
            KingdomTouchInfoFactory.ShowTouchInfo(data)
        else
            local data = TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
            KingdomTouchInfoFactory.ShowTouchInfo(data)
        end
    end

    ---@type wds.Pass
    local entity = tile.entity
    if ModuleRefer.MapBuildingTroopModule:IsNPCTroopInit(entity.Army) then
        action()
    else
        local TryInitVillageTroopParameter = require("TryInitVillageTroopParameter")
        local request = TryInitVillageTroopParameter.new()
        request.args.VillageId = tile.entity.ID
        request:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, response)
            action()
        end)
    end
end

---@class VillageFastForwardToSelectTroopDelegate
---@field __name string

---@param tile MapRetrieveResult
---@param lod number
---@param context VillageFastForwardToSelectTroopDelegate|nil
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateVillage(tile, lod, context)
    local provider = require("KingdomTouchInfoProviderVillage")
    if context and context.__name and context.__name == "VillageFastForwardToSelectTroopDelegate" then
        local btnFlags = provider.GetKingdomTouchInfoProviderVillageButtonFlags(tile.entity)
        if (btnFlags & provider.ButtonFlags.buttonManagedAttack) ~= 0 then
            provider.ManagedAttack(tile)
            return
        end
    end
    local isScout = ModuleRefer.RadarModule:GetScout(tile.entity)
    local pos = tile.entity.MapBasics.Position
    local fogUnlock = ModuleRefer.MapFogModule:IsFogUnlocked(math.floor(pos.X), math.floor(pos.Y))
    local action = function()
        local mainWindow
        local secondWindow
        local buttons
        local tip

        mainWindow = provider:CreateBasicInfo(tile)
        secondWindow = provider:CreateDetailInfo(tile)
        buttons = provider:CreateButtonInfo(tile)
        tip = provider:CreateTipData(tile)

        if isScout and fogUnlock then
            tip = nil
        end

        local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
        if tip then
            local data = TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons), tip):SetPos(position, sizeX, sizeZ)
            KingdomTouchInfoFactory.ShowTouchInfo(data)
        else
            local data = TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
            KingdomTouchInfoFactory.ShowTouchInfo(data)
        end
    end

    ---@type wds.Village
    local village = tile.entity
    if ModuleRefer.MapBuildingTroopModule:IsNPCTroopInit(village.Army) then
        action()
    else
        local TryInitVillageTroopParameter = require("TryInitVillageTroopParameter")
        local request = TryInitVillageTroopParameter.new()
        request.args.VillageId = tile.entity.ID
        request:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, response)
            action()
        end)
    end
end


---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateTransferTower(tile, lod)
    local provider = require("KingdomTouchInfoProviderTransferTower")
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end


---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateDefenseTower(tile, lod)
    local provider = require("KingdomTouchInfoProviderDefenseTower")
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end


---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateEnergyTower(tile, lod)
    local provider = require("KingdomTouchInfoProviderEnergyTower")
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end

---@param tile MapRetrieveResult
---@param lod number
---@param context any
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateBehemothDevice(tile, lod, context)
    local provider = require("KingdomTouchInfoProviderBehemothDevice")
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end

---@param tile MapRetrieveResult
---@param lod number
---@param context any
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateBehemothSummoner(tile, lod, context)
    local provider = require("KingdomTouchInfoProviderBehemothSummoner")
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end

---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateCreepTumor(tile, lod)
    if not ModuleRefer.MapCreepModule:IsTumorAlive(tile.playerUnit) then
        return
    end

    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_toast_clearcreep"))
end

function KingdomTouchInfoFactory.CreatePlayerSlgInteractor(tile, lod)
    local configId = tile.playerUnit.MineCfgId
    local conf = ConfigRefer.Mine:Find(configId)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculatePlayerSlgInteractorDisplayPositionAndMargin(tile)
    local mapInstId = conf:MapInstanceId()
    if mapInstId > 0 then
        local mapCfg = ConfigRefer.MapInstance:Find(mapInstId)
        local needPower = mapCfg:Power()
        local costPPP = mapCfg:CostPPP()
		local context = {
			worldPos = position,
			gridPos = CS.DragonReborn.Vector2Short(tile.X, tile.Z),
			interactorId = tile.playerUnit.ID,
			interactorConfId = configId,
            isPersonalInteractor = true,
            overrideGoToFunc = function()
                ---@type HUDSelectTroopListData
                local param = {}
                param.entity = tile.playerUnit
                param.isSE = true
                param.tid = mapInstId
                param.interactorId = tile.playerUnit.ID
                param.isPersonalInteractor = true
                param.needPower = needPower
                param.recommendPower = needPower
                param.costPPP = costPPP
                require("HUDTroopUtils").StartMarch(param)
            end
		}
        return ModuleRefer.SEPreModule:GetTouchMenuForWorld(context):SetPos(position, sizeX, sizeZ)
    end
    return nil
end


---@param tile MapRetrieveResult
function KingdomTouchInfoFactory.CreateSlgInteractor(tile, lod)
    local configId = tile.entity.Interactor.ConfigID
    local conf = ConfigRefer.Mine:Find(configId)
    if not conf then
        return
    end
    if not (tile.entity.Interactor.State.CanInteract and tile.entity.Interactor.LifeStatus == wds.InteractorLifeStatus.InteractorLifeStatusNormal and 
    not conf:IsShowTouchMenu()) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_mine_wfcj"))
        return
    end
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    local mapInstId = conf:MapInstanceId()
    if mapInstId > 0 then
        local mapCfg = ConfigRefer.MapInstance:Find(mapInstId)
        local needPower = mapCfg:Power()
        local costPPP = mapCfg:CostPPP()
		local context = {
			worldPos = position,
			gridPos = CS.DragonReborn.Vector2Short(tile.X, tile.Z),
			interactorId = tile.entity.ID,
			interactorConfId = configId,
            overrideGoToFunc = function()
                ---@type HUDSelectTroopListData
                local param = {}
                param.entity = tile.entity
                param.isSE = true
                param.tid = mapInstId
                param.interactorId = tile.entity.ID
                param.needPower = needPower
                param.recommendPower = needPower
                param.costPPP = costPPP
                require("HUDTroopUtils").StartMarch(param)
            end
		}
        return ModuleRefer.SEPreModule:GetTouchMenuForWorld(context):SetPos(position, sizeX, sizeZ)
    else
        local provider = require("KingdomTouchInfoProviderInteractor").new()
        local basicData = provider:CreateBasicInfo(tile)
        local detailData = provider:CreateDetailInfo(tile)
        local buttons = provider:CreateButtonInfo(tile)
        local tipData = provider:CreateTipData(tile)
        return TouchMenuHelper.GetSinglePageUIDatum(basicData, detailData, buttons, tipData):SetPos(position, sizeX, sizeZ)
    end
end


---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateDecoration(tile, lod)
    local mainWindow = KingdomTouchInfoCompHelper.GenerateBasicData(tile)

    local buttons = {}
    table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
            KingdomTouchInfoOperation.MoveTroopToTile,
            tile,
            KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
            I18N.Get("world_qianwang"),
            KingdomTouchInfoFactory.ButtonBacks.NegativeBack
    ))


    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, nil, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
end

---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateCreepByCenter(tile, lod)
    if not ModuleRefer.MapCreepModule:CanShowCreep(lod) then
        return nil
    end
    local creepData = ModuleRefer.MapCreepModule:GetCreepEntity(tile.entity.ID)
    ModuleRefer.MapCreepModule:StartSweepClean(creepData)
end

---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateCreep(tile, lod)
    if not ModuleRefer.MapCreepModule:CanShowCreep(lod) then
        return nil
    end

    local creepData = ModuleRefer.MapCreepModule:GetCreepEntityAt(tile.X, tile.Z)
    ModuleRefer.MapCreepModule:StartSweepClean(creepData)
end

---@param tile MapRetrieveResult
---@param lod number
---@return TouchInfoData
function KingdomTouchInfoFactory.CreateEmpty(tile, lod)
    --local marker = KingdomTouchInfoMarkProvider.new(tile)
    local mainWindow = KingdomTouchInfoCompHelper.GenerateBasicData(tile)--:SetMarkProvider(marker)

    local buttons = {}
    table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
            KingdomTouchInfoOperation.MoveTroopToTile,
            tile,
            KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
            I18N.Get("world_qianwang"),
            KingdomTouchInfoFactory.ButtonBacks.NegativeBack
    ))
    table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
            KingdomTouchInfoOperation.MoveCity,
            tile,
            KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
            I18N.Get("world_qiancheng"),
            KingdomTouchInfoFactory.ButtonBacks.NegativeBack
    ))

    if ModuleRefer.AllianceModule:CheckCanSetAllianceGatherPoint() then
        local content = I18N.Get("alliance_gathering_point_1")
        local onClick = Delegate.GetOrCreate(ModuleRefer.AllianceModule, ModuleRefer.AllianceModule.SetAllianceGatherPoint)
        local button = TouchMenuMainBtnDatum.new(content, onClick, tile)
        table.insert(buttons, button)
    end

    local position = KingdomTouchInfoHelper.GetWorldPosition(tile.X, tile.Z)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, nil, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position)
end

function KingdomTouchInfoFactory.CreateMist(tileX, tileZ)
    local mistID = ModuleRefer.MapFogModule:GetMistAt(tileX, tileZ)
    if mistID < 0 then
        return
    end

    local mainWindow = KingdomTouchInfoCompHelper.GenerateMistMainWindow(mistID, tileX, tileZ)

    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    local extraLabelColor = ModuleRefer.MapFogModule:IsExploreValueEnough() and Color.white or Color.red

    local exploreItemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local itemConfig = ConfigRefer.Item:Find(exploreItemID)

    local buttons = {}
    local isOK, showGoto, tip = ModuleRefer.MapFogModule:GetMistTip(mistID)
    if showGoto then
		local button = KingdomTouchInfoCompHelper.GenerateButtonCompData(
				KingdomTouchInfoOperation.MistUnlockGoTo,
				mistID,
				KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
				I18N.Get("world_qianwang"),
				TouchInfoDefine.ButtonBacks.BackNormal)
		table.insert(buttons, button)
    else
		local button = KingdomTouchInfoCompHelper.GenerateButtonCompData(
				KingdomTouchInfoOperation.UnlockMist,
				mistID,
				KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
				I18N.Get("mist_btn_explore"),
				TouchInfoDefine.ButtonBacks.BackWarn
		)
		button:SetExtraLabel("x" .. tostring(costPerMistCell))
		button:SetExtraLabelColor(extraLabelColor)
		button:SetExtraImage(itemConfig:Icon())
		button:SetEnable(isOK)
		table.insert(buttons, button)
    end

    local tipFunc = function()
        local isOK, _, tip = ModuleRefer.MapFogModule:GetMistTip(mistID)
        return tip
    end
    local tipData = TouchMenuButtonTipsData.new():SetContent(tipFunc)
    local position = KingdomTouchInfoHelper.GetWorldPosition(tileX, tileZ)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, nil, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons), tipData):SetPos(position)
end

---@type wds.BehemothCage
function KingdomTouchInfoFactory.CreateBehemothCageLod3(entity)
    local provider = require("KingdomTouchInfoProviderBehemothCageLod3")
    local x,y = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local tile = require("MapRetrieveResult").new(x, y, nil, entity, nil, 1, 1)
    local mainWindow = provider:CreateBasicInfo(tile)
    local secondWindow = provider:CreateDetailInfo(tile)
    local buttons = provider:CreateButtonInfo(tile)
    local tip = provider:CreateTipData(tile)
    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    if tip then
        return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons), tip):SetPos(position, sizeX, sizeZ)
    else
        return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, secondWindow, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ)
    end
end

function KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, name, level)
    local mainWindow = KingdomTouchInfoCompHelper.GenerateBasicDataHighLod(tileX, tileZ, name, level)

    local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
    local buttons = {}
    --KingdomTouchInfoHelper.AddBattleSignal(buttons, tile)
    table.insert(buttons, KingdomTouchInfoCompHelper.GenerateButtonCompData(
            KingdomTouchInfoOperation.LookAt,
            tile,
            KingdomTouchInfoFactory.ButtonIcons.IconStrength,--"sp_common_icon_strength",
            I18N.Get("world_qianwang"),
            KingdomTouchInfoFactory.ButtonBacks.NegativeBack
    ))

    local position, sizeX, sizeZ = KingdomTouchInfoHelper.CalculateDisplayPositionAndMargin(tile)
    return TouchMenuHelper.GetSinglePageUIDatum(mainWindow, nil, TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)):SetPos(position, sizeX, sizeZ):SetClickEmptyClose(true)
end

function KingdomTouchInfoFactory.CreateExpedition(eventId, position, progress, quality)
    local basicData = KingdomTouchInfoCompHelper.GenerateExpeditionBasicWindow(eventId)
    local compsData = KingdomTouchInfoCompHelper.GenerateExpeditionDetailWindow(eventId, progress, quality)
    local callback = function()
        g_Game.EventManager:TriggerEvent(EventConst.RADAR_HIDE_CLOSE_CAMERA)
        g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)
        local basicCamera = KingdomMapUtils.GetBasicCamera()
        local size = ConfigRefer.ConstMain:ChooseCameraDistance()
        basicCamera:LookAt(position)
        basicCamera:SetSize(size)
    end
    local btnGroups = TouchMenuHelper.GetRecommendButtonGroupDataArray({TouchMenuMainBtnDatum.new(I18N.Get("world_qianwang"), callback)})
    return TouchMenuHelper.GetSinglePageUIDatum(basicData, compsData, btnGroups):SetPos(position):SetClickEmptyClose(true)
end

return KingdomTouchInfoFactory
