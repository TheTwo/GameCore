local CityProcessV2SpeedUpHolder = require("CityProcessV2SpeedUpHolder")
---@class CityMaterialProcessV2SpeedUpHolder:CityProcessV2SpeedUpHolder
---@field new fun():CityMaterialProcessV2SpeedUpHolder
local CityMaterialProcessV2SpeedUpHolder = class("CityMaterialProcessV2SpeedUpHolder", CityProcessV2SpeedUpHolder)
local CityWorkType = require("CityWorkType")
local CastleWorkSpeedUpByItemsParameter = require("CastleWorkSpeedUpByItemsParameter")
local ModuleRefer = require("ModuleRefer")

function CityMaterialProcessV2SpeedUpHolder:GetBIId()
    return self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.MaterialProcess]
end

function CityMaterialProcessV2SpeedUpHolder:UseItemSpeedUp(itemCfgId, count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.MaterialProcess]
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

function CityMaterialProcessV2SpeedUpHolder:UseMultiItemSpeedUp(itemCfgId2Count)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.MaterialProcess]
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

function CityMaterialProcessV2SpeedUpHolder:OnConfirmPay(rectTransform)
    local workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.MaterialProcess]
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.MaterialProcess)

    self.city.cityWorkManager:RequestSpeedUpWorking(workId, rectTransform, function ()
        self.city.cityWorkManager:RequestCollectProcessLike(self.furniture:UniqueId(), nil, workCfgId, rectTransform)
    end)
    return true
end

return CityMaterialProcessV2SpeedUpHolder