---@class CityWorkProcessUIUnitBubbleData
---@field new fun():CityWorkProcessUIUnitBubbleData
local CityWorkProcessUIUnitBubbleData = class("CityWorkProcessUIUnitBubbleData")
local CityWorkProcessUIUnitBubbleStatus = require("CityWorkProcessUIUnitBubbleStatus")
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")

function CityWorkProcessUIUnitBubbleData:ctor()
    self.status = CityWorkProcessUIUnitBubbleStatus.Free
end

function CityWorkProcessUIUnitBubbleData:SetFree()
    self.status = CityWorkProcessUIUnitBubbleStatus.Free
end

---@param process wds.CastleProcess
function CityWorkProcessUIUnitBubbleData:SetWorking(process)
    self.status = CityWorkProcessUIUnitBubbleStatus.Working
    self.process = process
end

function CityWorkProcessUIUnitBubbleData:SetFinished(process)
    self.status = CityWorkProcessUIUnitBubbleStatus.Finished
    self.process = process
end

function CityWorkProcessUIUnitBubbleData:IsFree()
    return self.status == CityWorkProcessUIUnitBubbleStatus.Free
end

function CityWorkProcessUIUnitBubbleData:IsWorking()
    return self.status == CityWorkProcessUIUnitBubbleStatus.Working
end

function CityWorkProcessUIUnitBubbleData:IsFinished()
    return self.status == CityWorkProcessUIUnitBubbleStatus.Finished
end

function CityWorkProcessUIUnitBubbleData:GetIcon()
    if self.status == CityWorkProcessUIUnitBubbleStatus.Free then
        return string.Empty
    end

    local processCfg = ConfigRefer.CityProcess:Find(self.process.ConfigId)
    if processCfg == nil then
        return string.Empty
    end

    local outputIcon = processCfg:OutputIcon()
    if not string.IsNullOrEmpty(outputIcon) then
        return outputIcon
    end

    local output = ConfigRefer.ItemGroup:Find(processCfg:Output())
    if output == nil then
        return string.Empty
    end

    local _, icon = ItemGroupHelper.GetItemIcon(output)
    return icon
end

return CityWorkProcessUIUnitBubbleData