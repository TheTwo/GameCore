local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateProduce:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateProduce
local CityFurWorkBubbleStateProduce = class("CityFurWorkBubbleStateProduce", CityFurWorkBubbleStateBase)
local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local TimeFormatter = require("TimeFormatter")

function CityFurWorkBubbleStateProduce:GetName()
    return CityFurWorkBubbleStateBase.Names.Produce
end

function CityFurWorkBubbleStateProduce:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function CityFurWorkBubbleStateProduce:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    self._bubble = nil
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function CityFurWorkBubbleStateProduce:OnFrameTick()
    if self._bubble == nil then return end
    if not self.needTick then return end

    if self._reload then
        self:OnBubbleLoaded(self._bubble)
        self._reload = false
    else
        self._reload = self:UpdateBubbleProgress()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateProduce:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    if castleFurniture.ResourceProduceInfo.ResourceType == 0 then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    local paused = castleFurniture.WorkType2Id[CityWorkType.ResourceProduce] == nil
    self.needTick = not paused
    local icon = ConfigRefer.Item:Find(castleFurniture.ResourceProduceInfo.ResourceType):Icon()
    local progress = CityWorkProduceWdsHelper.GetProduceProgress(castleFurniture, self.tileAsset:GetCity())
    if progress < 1 then
        local previewProcess = CityWorkProduceWdsHelper.GetProduceSingleProgress(castleFurniture, self.tileAsset:GetCity())
        self._bubble:ShowProgress(previewProcess, icon, paused):ShowNumberText(("%d"):format(math.floor(castleFurniture.ResourceProduceInfo.CurCount)))
        self._full = false
    else
        self._bubble:ShowBubble(icon):ShowBubbleText(("%d"):format(math.floor(castleFurniture.ResourceProduceInfo.CurCount))):PlayRewardAnim()
        self._full = true
    end
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateProduce:OnBubbleUnload()
    self._bubble = nil
    self.needTick = false
end

function CityFurWorkBubbleStateProduce:UpdateBubbleProgress()
    if not self._bubble then return false end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then return true end

    local progress = CityWorkProduceWdsHelper.GetProduceProgress(castleFurniture, self.tileAsset:GetCity())
    local previewProcess = CityWorkProduceWdsHelper.GetProduceSingleProgress(castleFurniture, self.tileAsset:GetCity())
    self._bubble:UpdateProgress(previewProcess)
    self._bubble:ShowNumberText(("%d"):format(math.floor(castleFurniture.ResourceProduceInfo.CurCount)))
    if not self._full then
        return progress >= 1
    end
    return false
end

function CityFurWorkBubbleStateProduce:OnClick()
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        return true
    end

    if castleFurniture.ResourceProduceInfo.CurCount == 0 then
        return true
    end

    local workId = castleFurniture.WorkType2Id[CityWorkType.ResourceProduce] or 0
    ---@type CityWorkData
    local workData = self.tileAsset:GetCity().cityWorkManager:GetWorkData(workId)
    if workData == nil then
        return true
    end

    local param = CastleGetProcessOutputParameter.new()
    param.args.FurnitureId = self.furnitureId
    param.args.WorkCfgId = workData.workCfgId
    param:Send()

    self.city.petManager:BITraceBubbleClick(self.furnitureId, "claim_resource_produce")
    g_Game.SoundManager:Play("sfx_ui_reward_crop")
    return true
end

return CityFurWorkBubbleStateProduce