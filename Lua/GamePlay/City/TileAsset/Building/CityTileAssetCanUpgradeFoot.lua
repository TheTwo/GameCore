local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetCanUpgradeFoot:CityTileAsset
---@field new fun():CityTileAssetCanUpgradeFoot
local CityTileAssetCanUpgradeFoot = class("CityTileAssetCanUpgradeFoot", CityTileAsset)
local CityWorkType = require("CityWorkType")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityWorkFormula = require("CityWorkFormula")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")
local CityAttrType = require("CityAttrType")

function CityTileAssetCanUpgradeFoot:ctor()
    CityTileAsset.ctor(self)
end

function CityTileAssetCanUpgradeFoot:OnTileViewInit()
    self.furnitureId = self.tileView.tile:GetCell().singleId
    self._canLevelUp = false
    self.furniture = self:GetCity().furnitureManager:GetFurnitureById(self.furnitureId)
    if self.furniture and self.furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp) then
        self._canLevelUp = true
    end
    
    if self._canLevelUp then
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedChange))
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedChange))
        g_Game.EventManager:AddListener(EventConst.TASK_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnTaskChanged))
        g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLockedChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneChangedStatus))
        g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnAttrChange))
        self.notPolluted = not self.furniture:IsPolluted()
        self.notUndergoing = self:IsNotUndergoing()
        self.levelConditionMeet = self:IsLevelUpConditionMeet()
        self.levelCostEnough = self:IsLevelUpCostEnough()
        self.unlocked = self:IsUnlocked()
        self.notFogMask = self:IsNotFogMask()
        self.hasBuildMaster = self.furniture.manager:GetUpgradeQueueMaxCount() > 0
        self.isRecoverd = self:IsAtRecoveredZone()
    end
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdateBatch))
end

function CityTileAssetCanUpgradeFoot:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedChange))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedChange))
    g_Game.EventManager:RemoveListener(EventConst.TASK_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnTaskChanged))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLockedChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdateBatch))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneChangedStatus))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnAttrChange))
end

function CityTileAssetCanUpgradeFoot:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    return ManualResourceConst.mdl_city_levelup_01
end

function CityTileAssetCanUpgradeFoot:CheckCanShow()
    return self._canLevelUp
        and self.notPolluted
        and self.notUndergoing
        and self.levelConditionMeet
        and self.levelCostEnough
        and self.unlocked
        and self.notFogMask
        and not self.moving
        and self.hasBuildMaster
        and self.isRecoverd
end

function CityTileAssetCanUpgradeFoot:OnPollutedChange()
    self.notPolluted = not self.furniture:IsPolluted()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnTaskChanged()
    self.levelConditionMeet = self:IsLevelUpConditionMeet()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnItemCountChanged()
    self.levelCostEnough = self:IsLevelUpCostEnough()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnLockedChanged(city, batchEvt)
    if batchEvt.Change == nil then return end
    if batchEvt.Change[self.furnitureId] == nil then return end
    self.unlocked = self:IsUnlocked()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnZoneChangedStatus()
    self.notFogMask = self:IsNotFogMask()
    self.isRecoverd = self:IsAtRecoveredZone()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnAttrChange()
    self.hasBuildMaster = self.furniture.manager:GetUpgradeQueueMaxCount() > 0
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:IsNotUndergoing()
    local castleFurniture = self:GetCity().furnitureManager:GetCastleFurniture(self.furnitureId)
    return castleFurniture ~= nil and not castleFurniture.LevelUpInfo.Working
end

---@protected
function CityTileAssetCanUpgradeFoot:IsLevelUpConditionMeet()
    local conditionCount = self.furniture.furnitureCell:LevelUpConditionLength()
    for i = 1, conditionCount do
        local taskId = self.furniture.furnitureCell:LevelUpCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg ~= nil then
            local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskCfg:Id())
            local finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
            if not finished then
                return false
            end
        end
    end
    return true
end

function CityTileAssetCanUpgradeFoot:IsLevelUpCostEnough()
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

function CityTileAssetCanUpgradeFoot:IsUnlocked()
    return not self.furniture:IsLocked()
end

function CityTileAssetCanUpgradeFoot:IsNotFogMask()
    return not self.furniture:IsFogMask()
end

function CityTileAssetCanUpgradeFoot:IsAtRecoveredZone()
    return self.furniture:IsZoneRecovered()
end

function CityTileAssetCanUpgradeFoot:OnFurnitureUpdateBatch(city, batchEvt)
    if city ~= self:GetCity() then return end

    if not batchEvt.Change[self.furnitureId] then return end
    self._canLevelUp = false
    local furniture = self:GetCity().furnitureManager:GetFurnitureById(self.furnitureId)
    if furniture and furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp) then
        self._canLevelUp = true
    end
    if not self._canLevelUp then
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedChange))
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedChange))
        g_Game.EventManager:RemoveListener(EventConst.TASK_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnTaskChanged))
        g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLockedChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneChangedStatus))
        g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnAttrChange))
    else
        --- 升级会产生新的材料需求和条件变化，需要重新判断
        self.levelCostEnough = self:IsLevelUpCostEnough()
        self.notUndergoing = self:IsNotUndergoing()
        self.levelConditionMeet = self:IsLevelUpConditionMeet()
    end
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeFoot:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    local city = self:GetCity()
    if not city then return end
    go.transform:SetPositionAndRotation(city:GetWorldPositionFromCoord(self.tileView.tile.x, self.tileView.tile.y), CS.UnityEngine.Quaternion.Euler(0, 225, 0))
end

function CityTileAssetCanUpgradeFoot:OnMoveBegin()
    self.moving = true
    self:Hide()
end

function CityTileAssetCanUpgradeFoot:OnMoveEnd()
    self.moving = false
    self:Show()
end

return CityTileAssetCanUpgradeFoot