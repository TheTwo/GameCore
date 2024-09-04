local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkType = require("CityWorkType")
local CatchPetHelper = require("CatchPetHelper")

---@class CityFurWorkBubbleStateAutoPetCatch:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateAutoPetCatch
local CityFurWorkBubbleStateAutoPetCatch = class("CityFurWorkBubbleStateAutoPetCatch", CityFurWorkBubbleStateBase)

function CityFurWorkBubbleStateAutoPetCatch:GetName()
    return CityFurWorkBubbleStateBase.Names.AutoPetCatch
end

function CityFurWorkBubbleStateAutoPetCatch:Enter()
    CityFurWorkBubbleStateBase.Enter(self)

    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function CityFurWorkBubbleStateAutoPetCatch:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    self._bubble = nil
end

function CityFurWorkBubbleStateAutoPetCatch:OnFrameTick()
    if self._bubble == nil then return end
    if not self.needTick then return end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then return end

    local progress, leftSeconds = CatchPetHelper.GetAutoPetCatchWorkInfo(castleFurniture)
    self._bubble:UpdateProgress(progress)
    if progress >= 1 then
        self.needTick = false
        self:OnBubbleLoaded(self._bubble)
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateAutoPetCatch:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    local status = castleFurniture.CastleCatchPetInfo.Status
    -- 空闲状态
    if status == wds.AutoCatchPetStatus.AutoCatchPetStatusIdle then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    if status == wds.AutoCatchPetStatus.AutoCatchPetStatusCatching then
        -- 抓宠中
        local progress, leftSeconds = CatchPetHelper.GetAutoPetCatchWorkInfo(castleFurniture)
        self.needTick = progress < 1 or leftSeconds > 0
        self._bubble:ShowProgress(progress, 'sp_icon_item_drone')
        
    else
        -- 抓宠结束
        self._bubble:ShowBubble('sp_icon_item_drone')
        self.needTick = false
    end

    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateAutoPetCatch:OnBubbleUnload()
    self._bubble = nil
    self.needTick = false
end

---@param trigger CityTrigger
function CityFurWorkBubbleStateAutoPetCatch:OnClick(trigger)
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        return true
    end

    local legoBuilding = self.city.legoManager:GetLegoBuilding(castleFurniture.BuildingId)
    -- local param = CityLegoBuildingUIParameter.new(self.city, legoBuilding, self.furnitureId)
    -- g_Game.UIManager:Open(UIMediatorNames.CityLegoBuildingUIMediator, param)
    return true
end

return CityFurWorkBubbleStateAutoPetCatch