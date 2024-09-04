---@class CityHatchEggSpeedUpHolder
---@field new fun():CityHatchEggSpeedUpHolder
local CityHatchEggSpeedUpHolder = class("CityHatchEggSpeedUpHolder")
local CastleWorkSpeedUpByItemsParameter = require("CastleWorkSpeedUpByItemsParameter")
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")

---@param furniture CityFurniture
function CityHatchEggSpeedUpHolder:ctor(furniture)
    self.furniture = furniture
    self.city = furniture.manager.city
end

function CityHatchEggSpeedUpHolder:GetBIId()
    return self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate]
end

function CityHatchEggSpeedUpHolder:GetBIType()
    return 1
end

function CityHatchEggSpeedUpHolder:UseItemSpeedUp(itemCfgId, count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate]
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

function CityHatchEggSpeedUpHolder:UseMultiItemSpeedUp(itemCfgId2Count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate]
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

function CityHatchEggSpeedUpHolder:CanSkipConfirmTwice(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local remainTime = self:GetRemainTime()
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    return remainTime >= speedUpTime
end

function CityHatchEggSpeedUpHolder:GetProgress()
    local gap = self.city:GetWorkTimeSyncGap()
    local castleFurniture = self.furniture:GetCastleFurniture()
    local processInfo = castleFurniture.ProcessInfo
    local done = processInfo.CurProgress + gap
    local target = processInfo.TargetProgress * processInfo.LeftNum
    return done, target
end

function CityHatchEggSpeedUpHolder:GetRemainTime()
    local done, target = self:GetProgress()
    local remainTime = math.max(0, (target - done))
    return remainTime
end

function CityHatchEggSpeedUpHolder:GetBubbleText(itemCfgId)
    local count = self:GetCount(itemCfgId)
    if count == 0 then return string.Empty end
    return ("x%d"):format(count)
end

function CityHatchEggSpeedUpHolder:GetExpectCount(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    local remainTime = self:GetRemainTime()
    return math.ceil(remainTime / speedUpTime)
end

function CityHatchEggSpeedUpHolder:GetCount(itemCfgId)
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
function CityHatchEggSpeedUpHolder:OnMediatorShow(uiMediator)
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
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnWorkBatchUpdate))
end

---@param uiMediator UseResourceMediator
function CityHatchEggSpeedUpHolder:OnMediatorHide(uiMediator)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnWorkBatchUpdate))
    g_Game.ServiceManager:RemoveResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.Refresh))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.uiMediator = nil
end

function CityHatchEggSpeedUpHolder:OnTick(delta)
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

function CityHatchEggSpeedUpHolder:Refresh()
    self.uiMediator:RefreshItems()

    self.current, self.target = self:GetProgress()
    self.uiMediator.sliderProgress.value = math.clamp01(self.current / self.target)
    self.uiMediator.textTime.text = TimeFormatter.SimpleFormatTime(math.max(0, (self.target - self.current)))
end

function CityHatchEggSpeedUpHolder:OnWorkBatchUpdate(city, batchEvt)
    if city ~= self.city then return end

    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate] or 0
    if workId == 0 then
        if self.uiMediator then
            self.uiMediator:CloseSelf()
        end
        return
    end
end

function CityHatchEggSpeedUpHolder:GetPayButtonText()
    return I18N.Get("animal_work_interface_desc22")
end

function CityHatchEggSpeedUpHolder:GetPayButtonItemName()
    return I18N.Get("animal_work_interface_desc22")
end

function CityHatchEggSpeedUpHolder:GetPayButtonItemDesc()
    return I18N.Get("#消费水晶立刻完成孵化")
end

function CityHatchEggSpeedUpHolder:RequestConsume(rectTransform)
    local remainTime = self:GetRemainTime()
    ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(remainTime, function()
        return self:OnConfirmPay(rectTransform)
    end)
end

function CityHatchEggSpeedUpHolder:OnConfirmPay(rectTransform)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate]
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.Incubate)

    self.city.cityWorkManager:RequestSpeedUpWorking(workId, rectTransform, function ()
        self.city.cityWorkManager:RequestCollectProcessLike(self.furniture:UniqueId(), nil, workCfgId, rectTransform)
    end)
    return true
end

return CityHatchEggSpeedUpHolder
