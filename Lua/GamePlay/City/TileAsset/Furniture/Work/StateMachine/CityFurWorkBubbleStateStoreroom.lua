local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateStoreroom:CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateStoreroom = class("CityFurWorkBubbleStateStoreroom", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local TimeFormatter = require("TimeFormatter")
local CityOfflineIncomeUIParameter = require("CityOfflineIncomeUIParameter")
local UIMediatorNames = require("UIMediatorNames")

function CityFurWorkBubbleStateStoreroom:GetName()
    return CityFurWorkBubbleStateBase.Names.Storeroom
end

function CityFurWorkBubbleStateStoreroom:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

function CityFurWorkBubbleStateStoreroom:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    self._bubble = nil
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityFurWorkBubbleStateStoreroom:OnTick(dt)
    if not self._bubble then return end

    local progress = self:GetStockProgress()
    if progress >= 1 then
        self._bubble:ShowBubble("sp_city_icon_box_1", false, "full")
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    else
        self._bubble:UpdateProgress(progress)
        self._bubble:ShowTimeText(self:GetRemainTimeText())
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateStoreroom:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())

    local progress = self:GetStockProgress()
    if progress >= 1 then
        self._bubble:ShowBubble("sp_city_icon_box_1", false, "full")
    else
        self._bubble:ShowProgress(progress, "sp_city_icon_box_1", false, self:GetRemainTimeText())
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
end

function CityFurWorkBubbleStateStoreroom:OnBubbleUnload()
    if self._bubble then 
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityFurWorkBubbleStateStoreroom:MaxStockTime()
    return ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)
end

function CityFurWorkBubbleStateStoreroom:GetStockProgress()
    local maxTime = self:MaxStockTime()
    local offlineTime = self:OfflineTimeSum()
    return math.min(offlineTime / maxTime, 1)
end

function CityFurWorkBubbleStateStoreroom:OfflineTimeSum()
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastOfflineIncomeTime = self.city:GetCastle().GlobalData.OfflineData.LastGetOfflineBenefitTime.ServerSecond
    return math.max(0, now - lastOfflineIncomeTime)
end

function CityFurWorkBubbleStateStoreroom:GetRemainTimeText()
    local remainTime = self:MaxStockTime() - self:OfflineTimeSum()
    return TimeFormatter.SimpleFormatTime(math.max(0, remainTime))
end

function CityFurWorkBubbleStateStoreroom:OnClick()
    local param = CityOfflineIncomeUIParameter.new(self.city)
    g_Game.UIManager:Open(UIMediatorNames.CityOfflineIncomeUIMediator, param)
    self.city.petManager:BITraceBubbleClick(self.furnitureId, "claim_mobile_unit_offline_income")
    return true
end

return CityFurWorkBubbleStateStoreroom