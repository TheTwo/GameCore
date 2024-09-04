local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateCollect:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateCollect
local CityFurWorkBubbleStateCollect = class("CityFurWorkBubbleStateCollect", CityFurWorkBubbleStateBase)
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkType = require("CityWorkType")

function CityFurWorkBubbleStateCollect:GetName()
    return CityFurWorkBubbleStateBase.Names.Collect
end

function CityFurWorkBubbleStateCollect:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function CityFurWorkBubbleStateCollect:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    self._bubble = nil
end

function CityFurWorkBubbleStateCollect:OnFrameTick()
    if self._bubble == nil then return end
    if not self.needTick then return end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then return end

    local progress = CityWorkCollectWdsHelper.GetResCollectProgress(castleFurniture, self.collectInfo)
    self._bubble:UpdateProgress(progress)
    local gearAnim = self.collectInfo.CollectingResource > 0
    if self.gearAnim ~= gearAnim then
        self.gearAnim = gearAnim
        self._bubble:EnableGearAnim(self.gearAnim)
    end
    if progress >= 1 then
        self.needTick = false
        self:OnBubbleLoaded(self._bubble)
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateCollect:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    local collectInfo = castleFurniture.FurnitureCollectInfo
    if collectInfo:Count() == 0 then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    if collectInfo[1].FinishedCount > 0 then
        local icon = CityWorkCollectWdsHelper.GetOutputIcon(collectInfo[1])
        self._bubble:ShowBubble(icon, false, ("x%d"):format(collectInfo[1].FinishedCount)):PlayRewardAnim()
        for i = 2, collectInfo:Count() do
            if collectInfo[i].FinishedCount > 0 then
                local subIcon = CityWorkCollectWdsHelper.GetOutputIcon(collectInfo[i])
                self._bubble:ShowSubIcon(subIcon)
                break
            end
        end
        self.needTick = false
    else
        local workPaused = castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] == nil
        self.collectInfo = collectInfo[1]
        local collectPaused = collectInfo[1].CollectingResource == 0
        self.needTick = not workPaused and not collectPaused
        local progress = CityWorkCollectWdsHelper.GetResCollectProgress(castleFurniture, self.collectInfo)
        local icon = CityWorkCollectWdsHelper.GetOutputIcon(self.collectInfo)
        self._bubble:ShowProgress(progress, icon, not self.needTick):ShowGear(collectInfo[1].Auto):EnableGearAnim(collectInfo[1].CollectingResource > 0)
    end

    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
    self.gearAnim = collectInfo[1].CollectingResource > 0
end

function CityFurWorkBubbleStateCollect:OnBubbleUnload()
    self._bubble = nil
    self.needTick = false
end

---@param trigger CityTrigger
function CityFurWorkBubbleStateCollect:OnClick(trigger)
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        return true
    end

    local collectInfo = castleFurniture.FurnitureCollectInfo
    if collectInfo:Count() == 0 then
        return true
    end

    if collectInfo[1].FinishedCount > 0 then
        if self.city and self.city.cityWorkManager then
            self.city.cityWorkManager:RequestCollectProcessLike(self.furnitureId, 0, collectInfo[1].WorkCfgId)
        end
    else
        local furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
        if furniture then
            local castleFurniture = furniture:GetCastleFurniture()
            local legoBuilding = nil
            if castleFurniture.BuildingId > 0 then
                legoBuilding = self.city.legoManager:GetLegoBuilding(castleFurniture.BuildingId)
            end
        
            --- 采集分页已被干掉，不再优先进入采集分页
            -- local param = CityLegoBuildingUIParameter.new(self.city, legoBuilding, self.furnitureId)
            -- g_Game.UIManager:Open(UIMediatorNames.CityLegoBuildingUIMediator, param)
        end
    end
    return true
end

return CityFurWorkBubbleStateCollect