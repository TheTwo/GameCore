---@class CityFurnitureUpgradeSpeedUpHolder
---@field new fun():CityFurnitureUpgradeSpeedUpHolder
local CityFurnitureUpgradeSpeedUpHolder = class("CityFurnitureUpgradeSpeedUpHolder")
local CastleWorkSpeedUpByItemsParameter = require("CastleWorkSpeedUpByItemsParameter")
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")

---@param furniture CityFurniture
function CityFurnitureUpgradeSpeedUpHolder:ctor(furniture)
    self.furniture = furniture
    self.city = furniture.manager.city
end

function CityFurnitureUpgradeSpeedUpHolder:GetBIId()
    return self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureLevelUp]
end

function CityFurnitureUpgradeSpeedUpHolder:GetBIType()
    return 0
end

function CityFurnitureUpgradeSpeedUpHolder:UseItemSpeedUp(itemCfgId, count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureLevelUp]
    if workId == 0 then
        if self.uiMediator then
            self.uiMediator:CloseSelf()
        end
        return
    end

    local param = CastleWorkSpeedUpByItemsParameter.new()
    param.args.WorkId = workId
    param.args.SpeedUpCfgId2Count:Add(ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId):Id(), count)
    param:Send()
end

function CityFurnitureUpgradeSpeedUpHolder:UseMultiItemSpeedUp(itemCfgId2Count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureLevelUp]
    if workId == 0 then
        if self.uiMediator then
            self.uiMediator:CloseSelf()
        end
        return
    end

    local param = CastleWorkSpeedUpByItemsParameter.new()
    param.args.WorkId = workId
    for itemCfgId, count in pairs(itemCfgId2Count) do
        local speedUpCfgId = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId):Id()
        param.args.SpeedUpCfgId2Count:Add(speedUpCfgId, count)
        param.args.OneKey = true
    end
    param:Send()
end

function CityFurnitureUpgradeSpeedUpHolder:CanSkipConfirmTwice(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local remainTime = self:GetRemainTime()
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    return remainTime >= speedUpTime
end

function CityFurnitureUpgradeSpeedUpHolder:GetProgress()
    local gap = self.city:GetWorkTimeSyncGap()
    local castleFurniture = self.furniture:GetCastleFurniture()
    local levelUpInfo = castleFurniture.LevelUpInfo
    local done = levelUpInfo.CurProgress + gap
    local target = levelUpInfo.TargetProgress
    return done, target
end

function CityFurnitureUpgradeSpeedUpHolder:GetRemainTime()
    local done, target = self:GetProgress()
    local remainTime = math.max(0, (target - done))
    return remainTime
end

function CityFurnitureUpgradeSpeedUpHolder:GetBubbleText(itemCfgId)
    local count = self:GetCount(itemCfgId)
    if count == 0 then return string.Empty end
    return ("x%d"):format(count)
end

function CityFurnitureUpgradeSpeedUpHolder:GetExpectCount(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    local remainTime = self:GetRemainTime()
    return math.ceil(remainTime / speedUpTime)
end

function CityFurnitureUpgradeSpeedUpHolder:GetCount(itemCfgId)
    local own = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfgId)
    if own <= 0 then
        return 0
    end

    local remainTime = self:GetRemainTime()
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    return math.min(own, math.ceil(remainTime / speedUpTime))
end

---@param uiMediator UseResourceMediator
function CityFurnitureUpgradeSpeedUpHolder:OnMediatorShow(uiMediator)
    uiMediator.goProgressbar:SetActive(true)
    
    local done, target = self:GetProgress()

    uiMediator.sliderProgress.value = math.clamp01(done / target)
    uiMediator.textTime.text = TimeFormatter.SimpleFormatTime(math.max(0, (target - done)))
    g_Game.SpriteManager:LoadSprite("sp_city_icon_upgrade", uiMediator.imgBase)

    self.current = done
    self.target = target

    self.uiMediator = uiMediator
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.ServiceManager:AddResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.Refresh))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self.uiMediator, self.uiMediator.CloseSelf))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnWorkBatchUpdate))
end

---@param uiMediator UseResourceMediator
function CityFurnitureUpgradeSpeedUpHolder:OnMediatorHide(uiMediator)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnWorkBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self.uiMediator, self.uiMediator.CloseSelf))
    g_Game.ServiceManager:RemoveResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.Refresh))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.uiMediator = nil
end

function CityFurnitureUpgradeSpeedUpHolder:OnTick(delta)
    if self.current >= self.target then
        if self.uiMediator then
            self.uiMediator:CloseSelf()
        end
        return
    end

    self.current = self.current + delta
    if self.uiMediator then
        self.uiMediator.sliderProgress.value = math.clamp01(self.current / self.target)
        self.uiMediator.textTime.text = TimeFormatter.SimpleFormatTime(math.max(0, (self.target - self.current)))
    end
end

function CityFurnitureUpgradeSpeedUpHolder:Refresh()
    self.uiMediator:RefreshItems()
    self.current, self.target = self:GetProgress()
    
    self.uiMediator.sliderProgress.value = math.clamp01(self.current / self.target)
    self.uiMediator.textTime.text = TimeFormatter.SimpleFormatTime(math.max(0, (self.target - self.current)))
end

function CityFurnitureUpgradeSpeedUpHolder:OnWorkBatchUpdate(city, batchEvt)
    if city ~= self.city then return end
end

function CityFurnitureUpgradeSpeedUpHolder:GetPayButtonText()
    return I18N.Get("speedup_title")
end

function CityFurnitureUpgradeSpeedUpHolder:GetPayButtonItemName()
    return I18N.Get("speedup_des")
end

function CityFurnitureUpgradeSpeedUpHolder:GetPayButtonItemDesc()
    return I18N.Get("speedup_btn")
end

function CityFurnitureUpgradeSpeedUpHolder:RequestConsume(rectTransform)
    local remainTime = self:GetRemainTime()
    ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(remainTime, function()
        return self:OnConfirmPay(rectTransform)
    end)
end

function CityFurnitureUpgradeSpeedUpHolder:OnConfirmPay(rectTransform)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureLevelUp]
    self.city.cityWorkManager:RequestSpeedUpWorking(workId, rectTransform)
    return true
end

return CityFurnitureUpgradeSpeedUpHolder
