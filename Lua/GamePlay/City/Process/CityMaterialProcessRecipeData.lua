---@class CityMaterialProcessRecipeData
---@field new fun():CityMaterialProcessRecipeData
local CityMaterialProcessRecipeData = class("CityMaterialProcessRecipeData")
local ItemGroupHelper = require("ItemGroupHelper")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@param recipeId number
---@param param CityMaterialProcessV2UIParameter
function CityMaterialProcessRecipeData:ctor(processCfg, param, times)
    self.processCfg = processCfg
    local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
    if itemGroup then
        local costArray = ItemGroupHelper.GetPossibleOutput(itemGroup)
        self.costMonitor = costArray[1]
    end
    self.param = param
    self.times = times or 1
end

function CityMaterialProcessRecipeData:IsValid()
    return self.costMonitor ~= nil
end

function CityMaterialProcessRecipeData:UpdateTimes(times)
    self.times = times
end

function CityMaterialProcessRecipeData:AddCountListener(callback)
    self.listener = ModuleRefer.InventoryModule:AddCountChangeListener(self.costMonitor.id, callback)
end

function CityMaterialProcessRecipeData:ReleaseCountListener()
    if self.listener then
        self.listener()
        self.listener = nil
    end
end

function CityMaterialProcessRecipeData:IsSelected()
    return self.param:IsRecipeSelected(self.processCfg:Id())
end

---@return string, string
function CityMaterialProcessRecipeData:GetItemIcon()
    if not self:IsValid() then
        return string.Empty, string.Empty
    end
    local itemCfg = ConfigRefer.Item:Find(self.costMonitor.id)
    return itemCfg:Icon(), ('sp_item_frame_%d'):format(itemCfg:Quality())
end

return CityMaterialProcessRecipeData