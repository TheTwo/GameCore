---@class CityProcessV2SpeedUpHolder
---@field new fun():CityProcessV2SpeedUpHolder
local CityProcessV2SpeedUpHolder = class("CityProcessV2SpeedUpHolder")
local CastleWorkSpeedUpByItemsParameter = require("CastleWorkSpeedUpByItemsParameter")
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")

---@param furniture CityFurniture
function CityProcessV2SpeedUpHolder:ctor(furniture)
    self.furniture = furniture
    self.city = furniture.manager.city
end

function CityProcessV2SpeedUpHolder:GetBIId()
    return self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process]
end

function CityProcessV2SpeedUpHolder:GetBIType()
    return 1
end

function CityProcessV2SpeedUpHolder:UseItemSpeedUp(itemCfgId, count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process]
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

function CityProcessV2SpeedUpHolder:UseMultiItemSpeedUp(itemCfgId2Count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process]
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

function CityProcessV2SpeedUpHolder:CanSkipConfirmTwice(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local remainTime = self:GetRemainTime()
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    return remainTime >= speedUpTime
end

function CityProcessV2SpeedUpHolder:GetProgress()
    local gap = self.city:GetWorkTimeSyncGap()
    local castleFurniture = self.furniture:GetCastleFurniture()
    local processInfo = castleFurniture.ProcessInfo
    local done = processInfo.CurProgress + gap
    local target = processInfo.TargetProgress * processInfo.LeftNum
    return done, target
end

function CityProcessV2SpeedUpHolder:GetRemainTime()
    local done, target = self:GetProgress()
    local remainTime = math.max(0, (target - done))
    return remainTime
end

function CityProcessV2SpeedUpHolder:GetBubbleText(itemCfgId)
    local count = self:GetCount(itemCfgId)
    if count == 0 then return string.Empty end
    return ("x%d"):format(count)
end

function CityProcessV2SpeedUpHolder:GetExpectCount(itemCfgId)
    local speedUpCfg = ModuleRefer.CityWorkSpeedUpModule:GetCitySpeedUpCfgByItem(itemCfgId)
    local speedUpTime = ConfigTimeUtility.NsToSeconds(speedUpCfg:SpeedTime())
    local remainTime = self:GetRemainTime()
    return math.ceil(remainTime / speedUpTime)
end

function CityProcessV2SpeedUpHolder:GetCount(itemCfgId)
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
function CityProcessV2SpeedUpHolder:OnMediatorShow(uiMediator)
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
function CityProcessV2SpeedUpHolder:OnMediatorHide(uiMediator)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnWorkBatchUpdate))
    g_Game.ServiceManager:RemoveResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.Refresh))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.uiMediator = nil
end

function CityProcessV2SpeedUpHolder:OnTick(delta)
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

function CityProcessV2SpeedUpHolder:Refresh()
    self.uiMediator:RefreshItems()

    self.current, self.target = self:GetProgress()
    self.uiMediator.sliderProgress.value = math.clamp01(self.current / self.target)
    self.uiMediator.textTime.text = TimeFormatter.SimpleFormatTime(math.max(0, (self.target - self.current)))
end

function CityProcessV2SpeedUpHolder:OnWorkBatchUpdate(city, batchEvt)
    if city ~= self.city then return end

    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process] or 0
    if workId == 0 then
        if self.uiMediator then
            self.uiMediator:CloseSelf()
        end
        return
    end
end

function CityProcessV2SpeedUpHolder:GetPayButtonText()
    return I18N.Get("btn_auto_speedup")
end

function CityProcessV2SpeedUpHolder:GetPayButtonItemName()
    return I18N.Get("btn_auto_speedup")
end

function CityProcessV2SpeedUpHolder:GetPayButtonItemDesc()
    return I18N.Get("#消费水晶立刻完成制造")
end

function CityProcessV2SpeedUpHolder:RequestConsume(rectTransform)
    local remainTime = self:GetRemainTime()
    ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(remainTime, function()
        return self:OnConfirmPay(rectTransform)
    end)
end

function CityProcessV2SpeedUpHolder:OnConfirmPay(rectTransform)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.Process]
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.Process)

    self.city.cityWorkManager:RequestSpeedUpWorking(workId, rectTransform, function ()
        self.city.cityWorkManager:RequestCollectProcessLike(self.furniture:UniqueId(), nil, workCfgId, rectTransform)
    end)
    return true
end

return CityProcessV2SpeedUpHolder
