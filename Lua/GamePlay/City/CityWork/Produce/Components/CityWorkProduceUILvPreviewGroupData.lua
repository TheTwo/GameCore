---@class CityWorkProduceUILvPreviewGroupData
---@field new fun():CityWorkProduceUILvPreviewGroupData
---@field workCfgList CityWorkConfigCell[]
local CityWorkProduceUILvPreviewGroupData = class("CityWorkProduceUILvPreviewGroupData")
local ConfigRefer = require("ConfigRefer")
local CityWorkProduceUILvPreviewItemData = require("CityWorkProduceUILvPreviewItemData")

function CityWorkProduceUILvPreviewGroupData:ctor(startLevel)
    self.workCfgList = {}
    self.startLevel = startLevel
    self.endLevel = startLevel
    self.isCurrent = false
end

---@param workCfg CityWorkConfigCell
function CityWorkProduceUILvPreviewGroupData:IsSameRecipeWork(workCfg)
    if #self.workCfgList == 0 then
        return true
    end

    local lastWorkCfg = self.workCfgList[#self.workCfgList]
    local lastRecipeCount = lastWorkCfg:GenerateResListLength()
    local recipeCount = workCfg:GenerateResListLength()

    if lastRecipeCount ~= recipeCount then return false end
    
    local lastHash, hash = {}, {}
    for i = 1, lastRecipeCount do
        local lastRes = lastWorkCfg:GenerateResList(i)
        local res = workCfg:GenerateResList(i)
        lastHash[lastRes] = true
        hash[res] = true
    end

    for k, v in pairs(lastHash) do
        if not hash[k] then
            return false
        end
    end
    return true
end

function CityWorkProduceUILvPreviewGroupData:Close()
    self.endLevel = self.startLevel + #self.workCfgList - 1
end

function CityWorkProduceUILvPreviewGroupData:MarkIsCurrent()
    self.isCurrent = true
end

---@param workCfg CityWorkConfigCell
function CityWorkProduceUILvPreviewGroupData:AppendWorkLevel(workCfg)
    table.insert(self.workCfgList, workCfg)
end

function CityWorkProduceUILvPreviewGroupData:GetLabel()
    if self.startLevel == self.endLevel then
        return string.format("Lv.%d", self.startLevel)
    else
        return string.format("Lv.%d~%d", self.startLevel, self.endLevel)
    end
end

function CityWorkProduceUILvPreviewGroupData:GetItemDataList()
    local list = {}
    local lastWorkCfg = self.workCfgList[#self.workCfgList]
    local recipeCount = lastWorkCfg:GenerateResListLength()
    for i = 1, recipeCount do
        local processCfgId = lastWorkCfg:GenerateResList(i)
        local processCfg = ConfigRefer.CityProcess:Find(processCfgId)
        local itemData = CityWorkProduceUILvPreviewItemData.new(processCfg, self.isCurrent)
        table.insert(list, itemData)
    end
    table.sort(list, function(a, b)
        return a:GetSortIndex() > b:GetSortIndex()
    end)
    if #list > 0 then
        list[1]:SetLabel(self:GetLabel())
    end
    return list
end

return CityWorkProduceUILvPreviewGroupData