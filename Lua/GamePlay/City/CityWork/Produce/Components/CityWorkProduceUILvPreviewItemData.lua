---@class CityWorkProduceUILvPreviewItemData
---@field new fun():CityWorkProduceUILvPreviewItemData
local CityWorkProduceUILvPreviewItemData = class("CityWorkProduceUILvPreviewItemData")

---@param processCfg CityProcessConfigCell
function CityWorkProduceUILvPreviewItemData:ctor(processCfg, isCurrent)
    self.processCfg = processCfg
    self.label = string.Empty
    self.isCurrent = isCurrent
end

function CityWorkProduceUILvPreviewItemData:GetSortIndex()
    return self.processCfg:Index()
end

function CityWorkProduceUILvPreviewItemData:SetLabel(label)
    self.label = label
end

return CityWorkProduceUILvPreviewItemData