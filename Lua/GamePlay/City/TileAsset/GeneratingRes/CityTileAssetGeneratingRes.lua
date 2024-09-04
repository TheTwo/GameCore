local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetGeneratingRes:CityTileAsset
---@field new fun():CityTileAssetGeneratingRes
local CityTileAssetGeneratingRes = class("CityTileAssetGeneratingRes", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

function CityTileAssetGeneratingRes:GetPrefabName()
    ---@type CityWorkProduceResGenUnit
    local unit = self.tileView.tile:GetCell()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local fullDuration = unit.plan.FinishTime.ServerSecond - unit.plan.StartTime.ServerSecond
    local duration = unit.plan.Auto and fullDuration or fullDuration / unit.plan.TargetCount
    local progress = unit.plan.Auto and (nowTime - unit.plan.StartTime.ServerSecond)
        or (nowTime - (unit.plan.StartTime.ServerSecond + unit.plan.FinishedCount * duration))

    self.isStage2 = (progress / duration) > 0.5
    self.customScale = nil
    if self.isStage2 then
        return self:GetModelStage2()
    else
        return self:GetModel()
    end
end

function CityTileAssetGeneratingRes:GetModel()
    ---@type CityWorkProduceResGenUnit
    local unit = self.tileView.tile:GetCell()
    local resCfg = ConfigRefer.CityElementResource:Find(unit.resCfgId)
    if resCfg == nil then return string.Empty end
    self.customScale = ArtResourceUtils.GetItem(resCfg:ModelGenerating(), "ModelScale") or 1
    return ArtResourceUtils.GetItem(resCfg:ModelGenerating())
end

function CityTileAssetGeneratingRes:GetModelStage2()
    ---@type CityWorkProduceResGenUnit
    local unit = self.tileView.tile:GetCell()
    local resCfg = ConfigRefer.CityElementResource:Find(unit.resCfgId)
    if resCfg == nil then return string.Empty end

    local stage2 = ArtResourceUtils.GetItem(resCfg:ModelGeneratingStage2())
    self.customScale = ArtResourceUtils.GetItem(resCfg:ModelGeneratingStage2(), "ModelScale") or 1
    if string.IsNullOrEmpty(stage2) then
        self.customScale = ArtResourceUtils.GetItem(resCfg:ModelGenerating(), "ModelScale") or 1
        return ArtResourceUtils.GetItem(resCfg:ModelGenerating())
    else
        return stage2
    end
end

function CityTileAssetGeneratingRes:OnTileViewInit()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetGeneratingRes:OnTileViewRelease()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetGeneratingRes:OnTick()
    if self.isStage2 then return end
    
    ---@type CityWorkProduceResGenUnit
    local unit = self.tileView.tile:GetCell()
    if unit == nil then return end

    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local fullDuration = unit.plan.FinishTime.ServerSecond - unit.plan.StartTime.ServerSecond
    local duration = unit.plan.Auto and fullDuration or fullDuration / unit.plan.TargetCount
    local progress = unit.plan.Auto and (nowTime - unit.plan.StartTime.ServerSecond)
        or (nowTime - (unit.plan.StartTime.ServerSecond + unit.plan.FinishedCount * duration))

    local isStage2 = (progress / duration) > 0.5
    if self.isStage2 ~= isStage2 then
        self:ForceRefresh()
    end
end

function CityTileAssetGeneratingRes:GetScale()
    if self.customScale == nil then
        return 1
    end
    return self.customScale
end

function CityTileAssetGeneratingRes:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    
    local trigger = go:GetLuaBehaviour("CityTrigger")
    if Utils.IsNull(trigger) then return end

    ---@type CityTrigger
    self.trigger = trigger.Instance
    if self.trigger == nil then return end

    self.trigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self.tileView.tile, false)
end

function CityTileAssetGeneratingRes:OnAssetUnload(go)
    if self.trigger ~= nil then
        self.trigger:SetOnTrigger(nil, nil, false)
        self.trigger = nil
    end
end

function CityTileAssetGeneratingRes:OnClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_resource_tree_growing"))
    return true
end

return CityTileAssetGeneratingRes