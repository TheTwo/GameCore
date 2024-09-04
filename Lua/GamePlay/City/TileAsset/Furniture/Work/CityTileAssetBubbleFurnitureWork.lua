local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetBubbleFurnitureWork:CityTileAssetBubble
---@field new fun():CityTileAssetBubbleFurnitureWork
local CityTileAssetBubbleFurnitureWork = class("CityTileAssetBubbleFurnitureWork", CityTileAssetBubble)
local StateMachine = require("StateMachine")
local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
local CityFurWorkBubbleStateCollect = require("CityFurWorkBubbleStateCollect")
local CityFurWorkBubbleStateIdle = require("CityFurWorkBubbleStateIdle")
local CityFurWorkBubbleStateProcess = require("CityFurWorkBubbleStateProcess")
local CityFurWorkBubbleStateProduce = require("CityFurWorkBubbleStateProduce")
local CityFurWorkBubbleStateUpgraded = require("CityFurWorkBubbleStateUpgraded")
local CityFurWorkBubbleStateCanUpgrade = require("CityFurWorkBubbleStateCanUpgrade")
local CityFurWorkBubbleStateAllianceHelp = require("CityFurWorkBubbleStateAllianceHelp")
local CityFurWorkBubbleStateAutoPetCatch = require("CityFurWorkBubbleStateAutoPetCatch")
local CityFurWorkBubbleStateAllianceRecommendation = require("CityFurWorkBubbleStateAllianceRecommendation")
local CityFurWorkBubbleStateRadarEnter = require("CityFurWorkBubbleStateRadarEnter")
local CityFurWorkBubbleStateNeedPet = require("CityFurWorkBubbleStateNeedPet")
local CityFurWorkBubbleStateStoreroom = require("CityFurWorkBubbleStateStoreroom")
local CityFurWorkBubbleStateCanHatchPet = require("CityFurWorkBubbleStateCanHatchPet")
local CityFurWorkBubbleStateCanProcess = require("CityFurWorkBubbleStateCanProcess")
local CityFurWorkBubbleStatePvpChallenge = require("CityFurWorkBubbleStatePvpChallenge")
local CityFurWorkBubbleStateHunting = require("CityFurWorkBubbleStateHunting")

local CityUtils = require("CityUtils")
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
local CityWorkFormula = require("CityWorkFormula")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local CityAttrType = require("CityAttrType")
local CityProcessUtils = require("CityProcessUtils")
local ShowCanProcessFurTypes = {
    [1001201] = true,
    [1003001] = true,
    [1003101] = true,
    [1003201] = true,
    [1003301] = true,
    [1003401] = true,
}

function CityTileAssetBubbleFurnitureWork:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end
    if not self.stateMachine or not self.stateMachine.currentState then return string.Empty end
    return self.stateMachine.currentState:GetPrefabName()
end

function CityTileAssetBubbleFurnitureWork:OnTileViewInit()
    -- g_Logger.ErrorChannel("BubbleDebug", "CityTileAssetBubbleFurnitureWork.OnTileViewInit")
    CityTileAssetBubble.OnTileViewInit(self)
    self.furnitureId = self.tileView.tile:GetCell().singleId
    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState(CityFurWorkBubbleStateCollect:GetName(), CityFurWorkBubbleStateCollect.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateIdle:GetName(), CityFurWorkBubbleStateIdle.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateProcess:GetName(), CityFurWorkBubbleStateProcess.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateProduce:GetName(), CityFurWorkBubbleStateProduce.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateUpgraded:GetName(), CityFurWorkBubbleStateUpgraded.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateCanUpgrade:GetName(), CityFurWorkBubbleStateCanUpgrade.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateAllianceHelp:GetName(), CityFurWorkBubbleStateAllianceHelp.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateAutoPetCatch:GetName(), CityFurWorkBubbleStateAutoPetCatch.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateAllianceRecommendation:GetName(), CityFurWorkBubbleStateAllianceRecommendation.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateRadarEnter:GetName(), CityFurWorkBubbleStateRadarEnter.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateNeedPet:GetName(), CityFurWorkBubbleStateNeedPet.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateStoreroom:GetName(), CityFurWorkBubbleStateStoreroom.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateCanHatchPet:GetName(), CityFurWorkBubbleStateCanHatchPet.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateCanProcess:GetName(), CityFurWorkBubbleStateCanProcess.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStatePvpChallenge:GetName(), CityFurWorkBubbleStatePvpChallenge.new(self.furnitureId, self))
    self.stateMachine:AddState(CityFurWorkBubbleStateHunting:GetName(), CityFurWorkBubbleStateHunting.new(self.furnitureId, self))

    self._canLevelUp = false
    self.furniture = self:GetCity().furnitureManager:GetFurnitureById(self.furnitureId)
    if self.furniture and self.furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp) then
        self._canLevelUp = true
    end

    if self._canLevelUp then
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_SET_HELP_REQUEST_GREY_TIME, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingStart))
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingEnd))
        g_Game.EventManager:AddListener(EventConst.AUTO_PET_CATCH_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnAutoPetCatchStateChanged))

        self:UpdateAllianceHelpCanRequest()
    end

    if self.furniture.furType == ConfigRefer.AllianceConsts:AllianceFurnitureId() then
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_RECOMMENDATION_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRecommendationChanged))
    elseif self.furniture.furType == 1000101 then
        g_Game.EventManager:AddListener(EventConst.RADAR_FURNITURE_CHANGED, Delegate.GetOrCreate(self, self.OnRadarEntryChanged))
    end

    if self.furniture.furType == ConfigRefer.CityConfig:ReplicaPvpFurniture() then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.CanChallengeTimes.MsgPath, Delegate.GetOrCreate(self, self.RouteState))
    end

    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdateBatch))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_PET_UPDATE, Delegate.GetOrCreate(self, self.OnPetAssignedUpdate))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.GlobalData.OfflineData.LastGetOfflineBenefitTime.MsgPath, Delegate.GetOrCreate(self, self.RouteState))
    self:RouteState()
end

function CityTileAssetBubbleFurnitureWork:OnTileViewRelease()
    -- g_Logger.ErrorChannel("BubbleDebug", "CityTileAssetBubbleFurnitureWork.OnTileViewInit")

    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdateBatch))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_PET_UPDATE, Delegate.GetOrCreate(self, self.OnPetAssignedUpdate))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_SET_HELP_REQUEST_GREY_TIME, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingStart))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingEnd))
    g_Game.EventManager:RemoveListener(EventConst.AUTO_PET_CATCH_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnAutoPetCatchStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_RECOMMENDATION_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRecommendationChanged))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_FURNITURE_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceRecommendationChanged))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.GlobalData.OfflineData.LastGetOfflineBenefitTime.MsgPath, Delegate.GetOrCreate(self, self.RouteState))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.CanChallengeTimes.MsgPath, Delegate.GetOrCreate(self, self.RouteState))

    self.stateMachine:ClearAllStates()
    self.stateMachine = nil
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetBubbleFurnitureWork:GetBubble()
    return self._bubble
end

function CityTileAssetBubbleFurnitureWork:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    -- g_Logger.ErrorChannel("BubbleDebug", "CityTileAssetBubbleFurnitureWork:OnAssetLoaded")

    if not self:TrySetPosToMainAssetAnchor(go.transform) then
        self:SetPosToTileWorldCenter(go)
    end

    local behaviour = go:GetLuaBehaviour("City3DBubbleStandard")
    if Utils.IsNull(behaviour) then return end

    ---@type City3DBubbleStandard
    self._bubble = behaviour.Instance
    if not self.stateMachine then return end
    if not self.stateMachine.currentState then return end
    -- g_Logger.ErrorChannel("BubbleDebug", "OnBubbleLoaded")
    self.stateMachine.currentState:OnBubbleLoaded(self._bubble)
end

function CityTileAssetBubbleFurnitureWork:OnAssetUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
    self.stateMachine.currentState:OnBubbleUnload()
end

function CityTileAssetBubbleFurnitureWork:UpdateIsPolluted(route)
    self.isNotPolluted = not self.furniture:IsPolluted()
    if route then
        self:RouteState()
    end
end

function CityTileAssetBubbleFurnitureWork:UpdateCanDoLevelUp(route)
    local castleFurniture = self:GetCity().furnitureManager:GetCastleFurniture(self.furnitureId)
    self.canDoLevelUp = castleFurniture ~= nil and not castleFurniture.LevelUpInfo.Working
    if route then
        self:RouteState()
    end
end

function CityTileAssetBubbleFurnitureWork:UpdateLevelUpCostEnough(route)
    self.levelCostEnough = self:IsLevelUpCostEnough()
    if route then
        self:RouteState()
    end
end

function CityTileAssetBubbleFurnitureWork:IsLevelUpCostEnough()
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg == nil then
        return false
    end

    local nextLvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(self.furniture.furType, self.furniture.level + 1)
    if nextLvCell == nil then
        return false
    end

    local itemGroup = ConfigRefer.ItemGroup:Find(nextLvCell:LevelUpCost())
    if itemGroup ~= nil then
        local costItems = CityWorkFormula.CalculateInput(workCfg, itemGroup, nil, self.furnitureId)
        for i, v in ipairs(costItems) do
            if ModuleRefer.InventoryModule:GetAmountByConfigId(v.id) < v.count then
                return false
            end
        end
    end
    return true
end

function CityTileAssetBubbleFurnitureWork:OnFurnitureUpdateBatch(city, batchEvt)
    if city ~= self:GetCity() then return end

    if not batchEvt.Change[self.furnitureId] then return end
    self._canLevelUp = false
    local furniture = self:GetCity().furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture and furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp) then
        self._canLevelUp = true
    end
    if not self._canLevelUp then
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_SET_HELP_REQUEST_GREY_TIME, Delegate.GetOrCreate(self, self.OnAllianceStatusChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingStart))
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnFurnitureUpgradingEnd))
        g_Game.EventManager:RemoveListener(EventConst.AUTO_PET_CATCH_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnAutoPetCatchStateChanged))
    end
    self:RouteState()
end

function CityTileAssetBubbleFurnitureWork:OnPetAssignedUpdate(city, batchEvt)
    if city ~= self:GetCity() then return end
    if not batchEvt.RelativeFurniture[self.furnitureId] then return end
    self:RouteState()
end

function CityTileAssetBubbleFurnitureWork:UpdateAllianceHelpCanRequest(route)
    self._upgradingWorkId = self.furniture:GetUpgradingWorkId()
    if route then
        self:RouteState()
    end
end

function CityTileAssetBubbleFurnitureWork:RouteState()
    if self:Locked() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
    elseif self:NeedShowAllianceRecommendation() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.AllianceRecommendation)
    elseif self:NeedShowRadarEntry() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.RadarEnter)
    elseif self:NeedShowAutoPetCatch() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.AutoPetCatch)
    elseif self:NeedShowUpgraded() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Upgraded)
    elseif self:NeedShowRequestAllianceHelp() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.AllianceHelp)
    elseif self:NeedShowProcessFinished() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Process)
    elseif self:NeedShowProcess() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Process)
    elseif self:NeedShowProduce() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Produce)
    elseif self:NeedShowNeedPet() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.NeedPet)
    elseif self:NeedShowStoreroom() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Storeroom)
    elseif self:NeedShowCanHatchEgg() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.CanHatchPet)
    elseif self:NeedShowCanProcess() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.CanProcess)
    elseif self:NeedShowPvpChallenge() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.PvpChallenge)
    elseif self:NeedShowHunting() then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Hunting)
    else
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
    end
end

function CityTileAssetBubbleFurnitureWork:Locked()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return castleFurniture.Locked
end

function CityTileAssetBubbleFurnitureWork:NeedShowAutoPetCatch()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return castleFurniture.CastleCatchPetInfo ~= nil and castleFurniture.CastleCatchPetInfo.Status ~= wds.AutoCatchPetStatus.AutoCatchPetStatusIdle
end

function CityTileAssetBubbleFurnitureWork:NeedShowUpgraded()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return castleFurniture.LevelUpInfo.Working and
        castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress
end

function CityTileAssetBubbleFurnitureWork:NeedShowProcessFinished()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end
    
    if castleFurniture.ProcessInfo.ConfigId == 0 then return false end
    return castleFurniture.ProcessInfo.FinishNum > 0 and castleFurniture.ProcessInfo.LeftNum == 0
end

function CityTileAssetBubbleFurnitureWork:NeedShowCollectFinished()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return false
end

function CityTileAssetBubbleFurnitureWork:NeedShowProcess()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end
    
    return castleFurniture.ProcessInfo.ConfigId ~= 0
end

function CityTileAssetBubbleFurnitureWork:NeedShowProduce()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end
    
    local info = castleFurniture.ResourceProduceInfo
    local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local interval = ConfigRefer.CityConfig:ResourceProduceBubbleHiddenTime()
    return info.ResourceType > 0 and info.StartTime.ServerSecond > 0 and now >= info.StartTime.ServerSecond + interval
end

function CityTileAssetBubbleFurnitureWork:NeedShowCollect()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    return false
end

function CityTileAssetBubbleFurnitureWork:NeedShowAllianceRecommendation()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    if self.furnitureId ~= ConfigRefer.AllianceConsts:AllianceFurnitureId() then
        return false
    end

    local recommendation = ModuleRefer.AllianceModule:GetRecommendation()
    return recommendation ~= nil
end

function CityTileAssetBubbleFurnitureWork:NeedShowRadarEntry()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return false end

    if self.furniture.furType ~= 1000101 then
        return false
    end

    local count = ModuleRefer.RadarModule:GetRadarTaskRewardCount()
    return count > 0
end

function CityTileAssetBubbleFurnitureWork:NeedShowRequestAllianceHelp()
    if not self._canLevelUp or not self._upgradingWorkId then
        return false
    end
    if not ModuleRefer.AllianceModule:IsAllianceEntryUnLocked() then
        return false
    end
    if not ModuleRefer.AllianceModule:IsAllianceHelpUnlocked() then
        return false
    end
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return ModuleRefer.AllianceModule:CanShowGreyHelpRequestBubble()
    end
    local castleFurniture = self.furniture:GetCastleFurniture()
    if not castleFurniture or not castleFurniture.LevelUpInfo or castleFurniture.LevelUpInfo.Helped then
        return false
    end
    return true
end

function CityTileAssetBubbleFurnitureWork:NeedShowNeedPet()
    local needCount = self.furniture:GetPetWorkSlotCount()
    if needCount == 0 then return false end

    local needShow = false
    local lvCfg = self.furniture.furnitureCell
    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg:Type() == CityWorkType.ResourceProduce then
            needShow = true
            break
        end
    end

    if self.furniture:IsBuildMaster() then
        needShow = true
    elseif self.furniture:IsHotSpring() then
        needShow = true
    elseif self.furniture:IsTemperatureBooster() then
        needShow = true
    end

    if not needShow then return false end
    local petCount = self:GetCity().petManager:GetPetCountByWorkFurnitureId(self.furnitureId)
    return petCount < needCount
end

function CityTileAssetBubbleFurnitureWork:NeedShowStoreroom()
    local castleFurniture = self.furniture:GetCastleFurniture()
    if not castleFurniture then return false end

    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastOfflineIncomeTime = self:GetCity():GetCastle().GlobalData.OfflineData.LastGetOfflineBenefitTime.ServerSecond
    local stockTime = math.max(0, now - lastOfflineIncomeTime)
    local maxTime = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)

    return castleFurniture.StockRoomInfo.Benefits:Count() > 0 and (stockTime > 3600 or stockTime >= maxTime)
end

function CityTileAssetBubbleFurnitureWork:NeedShowCanHatchEgg()
    if not self.furniture:CanDoCityWork(CityWorkType.Incubate) then return false end

    local castleFurniture = self.furniture:GetCastleFurniture()
    if not castleFurniture then return false end
    if castleFurniture.ProcessInfo.ConfigId > 0 then return false end

    return self.furniture:CanHatchEggCount() > 0
end

function CityTileAssetBubbleFurnitureWork:NeedShowCanProcess()
    if not ShowCanProcessFurTypes[self.furniture.furType] then return false end

    if self.furniture:CanDoCityWork(CityWorkType.Process) then
        return self:NeedShowCanProcessImp()
    elseif self.furniture:CanDoCityWork(CityWorkType.MaterialProcess) then
        return self:NeedShowCanMaterialProcessImp()
    end

    return false
end

function CityTileAssetBubbleFurnitureWork:NeedShowCanProcessImp()
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.Process)
    if workCfgId == 0 then return true end

    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    for i = 1, workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(workCfg:ProcessCfg(i))
        local isMakingFurniture = CityProcessUtils.IsFurnitureRecipe(processCfg)
        if isMakingFurniture then
            local lvCfg = CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
            local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
            local ownCount = self:GetCity().furnitureManager:GetFurnitureCountByTypeCfgId(typCfg:Id())
            local realMaxCount = self:GetCity().furnitureManager:GetFurnitureMaxOwnCount(typCfg:Id())
            if ownCount < realMaxCount and CityProcessUtils.IsRecipeUnlocked(processCfg) and CityProcessUtils.IsRecipeVisible(processCfg) and CityProcessUtils.GetCostEnoughTimes(processCfg) > 0 then
                return true
            end
        else
            if CityProcessUtils.IsRecipeUnlocked(processCfg) and CityProcessUtils.IsRecipeVisible(processCfg) and CityProcessUtils.GetCostEnoughTimes(processCfg) > 0 then
                return true
            end
        end
    end

    return false
end

function CityTileAssetBubbleFurnitureWork:NeedShowCanMaterialProcessImp()
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.MaterialProcess)
    if workCfgId == 0 then return true end

    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    for i = 1, workCfg:ConvertProcessCfgLength() do
        local convertCfg = ConfigRefer.CityWorkMatConvertProcess:Find(workCfg:ConvertProcessCfg(i))
        if CityProcessUtils.IsConvertRecipeUnlocked(convertCfg) and CityProcessUtils.IsConvertRecipeVisible(convertCfg) then
            for j = 1, convertCfg:RecipesLength() do
                local recipeId = convertCfg:Recipes(j)
                local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
                if CityProcessUtils.IsRecipeUnlocked(processCfg) and CityProcessUtils.IsRecipeVisible(processCfg) and CityProcessUtils.GetCostEnoughTimes(processCfg) > 0 then
                    return true
                end
            end
        end
    end

    return false
end

function CityTileAssetBubbleFurnitureWork:NeedShowPvpChallenge()
    if self.furniture.furType ~= ConfigRefer.CityConfig:ReplicaPvpFurniture() then return false end

    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    local ticketId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
    local ticketCount = ModuleRefer.InventoryModule:GetAmountByConfigId(ticketId)
    return canChallengeTimes > 0 or ticketCount > 0
end

function CityTileAssetBubbleFurnitureWork:NeedShowHunting()
    if self.furniture.furType ~= ConfigRefer.CityConfig:TrainingDummyFurniture() then return false end
    local sysId = ConfigRefer.HuntingConst:FuncSwitch()
    local isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)

    local showTaskId = ConfigRefer.HuntingConst:HuntingCircleMenuBtnShow()
    local showTask = require("TaskItemDataProvider").new(showTaskId)
    local show = showTaskId == 0 or showTask:IsTaskFinished()
    return isUnlock and show
end

function CityTileAssetBubbleFurnitureWork:OnAllianceStatusChanged()
    self:UpdateAllianceHelpCanRequest(true)
end

---@param city City
---@param msg {furnitureId:number}
function CityTileAssetBubbleFurnitureWork:OnFurnitureUpgradingStart(city, msg)
    if not city:IsMyCity() or self.furnitureId ~= msg.furnitureId then
        return
    end
    self:UpdateAllianceHelpCanRequest(true)
end

---@param city City
---@param msg {furnitureId:number}
function CityTileAssetBubbleFurnitureWork:OnFurnitureUpgradingEnd(city, msg)
    if not city:IsMyCity() or self.furnitureId ~= msg.furnitureId then
        return
    end
    self:UpdateAllianceHelpCanRequest(true)
end

---@param helpInfo wds.AllianceHelpInfo
function CityTileAssetBubbleFurnitureWork:OnAllianceHelpRequested(helpInfo)
    if self.furnitureId ~= helpInfo.TargetID or self._upgradingWorkId ~= helpInfo.OptionID then
        return
    end
    self:UpdateAllianceHelpCanRequest(true)
end

---@param furnitureId number
function CityTileAssetBubbleFurnitureWork:OnAutoPetCatchStateChanged(furnitureId)
    if self.furnitureId ~= furnitureId then
        return
    end
    
    self:RouteState()
end


---@param furnitureId number
function CityTileAssetBubbleFurnitureWork:OnAllianceRecommendationChanged(furnitureId)
    if self.furnitureId ~= furnitureId then
        return
    end
    
    self:RouteState()
end

---@param furnitureId number
function CityTileAssetBubbleFurnitureWork:OnRadarEntryChanged(furnitureId)
    if self.furnitureId ~= furnitureId then
        return
    end
    
    self:RouteState()
end

return CityTileAssetBubbleFurnitureWork