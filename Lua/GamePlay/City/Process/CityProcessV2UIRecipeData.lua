---@class CityProcessV2UIRecipeData
---@field new fun():CityProcessV2UIRecipeData
local CityProcessV2UIRecipeData = class("CityProcessV2UIRecipeData")
local ConfigRefer = require("ConfigRefer")

---@param processCfg CityWorkProcessConfigCell
---@param param CityProcessV2UIParameter
function CityProcessV2UIRecipeData:ctor(processCfg, param)
    self.processCfg = processCfg
    self.param = param
end

---@return ItemIconData
function CityProcessV2UIRecipeData:GetItemIconData()
    if self.processCfg:Output() == 0 then
        return nil
    end

    local itemCfg = ConfigRefer.Item:Find(self.processCfg:Output())
    return {
        configCell = itemCfg,
        showCount = false,
        showRecommend = false,
        showSelect = self.param:IsRecipeSelected(self.processCfg:Id()),
        onClick = function()
            if self.param:IsRecipeSelected(self.processCfg:Id()) then return end
            self.param:SelectRecipe(self.processCfg)
        end,
        locked = not self.param:IsRecipeUnlocked(self.processCfg)
    }
end

function CityProcessV2UIRecipeData:IsUndergoing()
    if self.param:IsUndergoing() then
        local info = self.param:GetProcessInfo()
        return self.processCfg:Id() == info.ConfigId
    end
    return false
end

function CityProcessV2UIRecipeData:IsWaitClaim()
    if self.param:IsWaitClaim() then
        local info = self.param:GetProcessInfo()
        return self.processCfg:Id() == info.ConfigId
    end
    return false
end

return CityProcessV2UIRecipeData