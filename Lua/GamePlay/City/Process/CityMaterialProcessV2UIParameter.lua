local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
---@class CityMaterialProcessV2UIParameter:CityProcessV2UIParameter
---@field new fun():CityMaterialProcessV2UIParameter
local CityMaterialProcessV2UIParameter = class("CityMaterialProcessV2UIParameter", CityProcessV2UIParameter)
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
local UIStatusEnum = require("CityProcessV2UIStatusEnum")
local CityProcessUtils = require("CityProcessUtils")
local CityMaterialProcessV2SpeedUpHolder = require("CityMaterialProcessV2SpeedUpHolder")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CityProcessV2I18N = require("CityProcessV2I18N")

function CityMaterialProcessV2UIParameter:UpdateWorkData()
    self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.MaterialProcess] or 0
    ---@type CityWorkData
    self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    self.workCfg = nil
    local furLvCfg = self.cellTile:GetCell().furnitureCell
    for i = 1, furLvCfg:WorkListLength() do
        local workCfgId = furLvCfg:WorkList(i)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        if workCfg and workCfg:Type() == CityWorkType.MaterialProcess then
            self.workCfg = workCfg
            break
        end
    end

    if self.workCfg == nil then
        g_Logger.ErrorChannel("CityProcessV2UIParameter", "制造界面数据异常")
    end
end

function CityMaterialProcessV2UIParameter:IsMakingMaterial()
    return true
end

function CityMaterialProcessV2UIParameter:GetFirstMaterialRecipeId()
    return self.matConvertRecipeId, self.recipeId
end

function CityMaterialProcessV2UIParameter:GetFirstMaterialRecipeIdImp()
    local process = self:GetProcessInfo()
    if process and process.ConfigId > 0 then
        return self:GetConvertCfgIdByRecipeId(process.ConfigId), process.ConfigId
    end

    local unlockedRecipes, lockedRecipes = self:GetAllMaterialRecipeOrdered()

    local recipePairs = {}
    
    for _, recipe in ipairs(unlockedRecipes) do
        for i = 1, recipe:RecipesLength() do
            local processCfg = ConfigRefer.CityWorkProcess:Find(recipe:Recipes(i))
            if CityProcessUtils.IsRecipeUnlocked(processCfg) and
               CityProcessUtils.IsRecipeVisible(processCfg) and
               CityProcessUtils.GetCostEnoughTimes(processCfg) > 0
            then
                table.insert(recipePairs, {recipeId = recipe:Id(), processId = processCfg:Id()})
            end
        end
    end

    if #recipePairs > 0 then
        local pair = recipePairs[#recipePairs]
        return pair.recipeId, pair.processId
    end

    if #unlockedRecipes > 0 then
        if self.forceRecipeId then
            local convertCfgId = self:GetConvertCfgIdByRecipeId(self.forceRecipeId)
            for i, v in ipairs(unlockedRecipes) do
                if v:Id() == convertCfgId then
                    return convertCfgId, self.forceRecipeId
                end
            end
        else
            return unlockedRecipes[#unlockedRecipes]:Id(), self:GetLargestIndexedMaterialRecipeId(unlockedRecipes[#unlockedRecipes])
        end
    end

    if #lockedRecipes > 0 then
        if self.forceRecipeId then
            local convertCfgId = self:GetConvertCfgIdByRecipeId(self.forceRecipeId)
            for i, v in ipairs(lockedRecipes) do
                if v:Id() == convertCfgId then
                    return convertCfgId, self.forceRecipeId
                end
            end
        else
            return lockedRecipes[1]:Id(), self:GetFirstRecipeIdInConvertCfg(lockedRecipes[1])
        end
    end

    return 0, 0
end

---@private
---@return CityWorkMatConvertProcessConfigCell[], CityWorkMatConvertProcessConfigCell[]
function CityMaterialProcessV2UIParameter:GetAllMaterialRecipeOrdered()
    local unlockedRecipes = {}
    local lockedRecipes = {}

    for i = 1, self.workCfg:ConvertProcessCfgLength() do
        local convertProcessCfg = ConfigRefer.CityWorkMatConvertProcess:Find(self.workCfg:ConvertProcessCfg(i))
        if not self:IsConvertProcessVisible(convertProcessCfg) then
            goto continue
        end

        if self:IsConvertProcessUnlocked(convertProcessCfg) then
            table.insert(unlockedRecipes, convertProcessCfg)
        else
            table.insert(lockedRecipes, convertProcessCfg)
        end
        ::continue::
    end

    ---@param a CityWorkMatConvertProcessConfigCell
    ---@param b CityWorkMatConvertProcessConfigCell
    table.sort(unlockedRecipes, function(a, b)
        return a:Id() < b:Id()
    end)

    ---@param a CityWorkMatConvertProcessConfigCell
    ---@param b CityWorkMatConvertProcessConfigCell
    table.sort(lockedRecipes, function(a, b)
        return a:Id() < b:Id()
    end)

    return unlockedRecipes, lockedRecipes
end

---@private
---@param convertProcessCfg CityWorkMatConvertProcessConfigCell
function CityMaterialProcessV2UIParameter:GetFirstRecipeIdInConvertCfg(convertProcessCfg)
    for j = 1, convertProcessCfg:RecipesLength() do
        local recipeId = convertProcessCfg:Recipes(j)
        local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
        if self:IsRecipeVisible(processCfg) and self:IsRecipeUnlocked(processCfg) and self:IsRecipeCostEnough(processCfg) then
            return recipeId
        end
    end
    if convertProcessCfg:RecipesLength() > 0 then
        return convertProcessCfg:Recipes(1)
    end
    return 0
end

---@private
---@param convertProcessCfg CityWorkMatConvertProcessConfigCell
function CityMaterialProcessV2UIParameter:GetLargestIndexedMaterialRecipeId(convertProcessCfg)
    if convertProcessCfg:RecipesLength() > 0 then
        return convertProcessCfg:Recipes(convertProcessCfg:RecipesLength())
    end
    return 0
end

function CityMaterialProcessV2UIParameter:IsConvertProcessVisible(convertProcessCfg)
    return CityProcessUtils.IsConvertRecipeVisible(convertProcessCfg)
end

function CityMaterialProcessV2UIParameter:IsConvertProcessUnlocked(convertProcessCfg)
    return CityProcessUtils.IsConvertRecipeUnlocked(convertProcessCfg)
end

function CityMaterialProcessV2UIParameter:GetConvertCfgIdByRecipeId(recipeId)
    for i = 1, self.workCfg:ConvertProcessCfgLength() do
        local convertProcessCfg = ConfigRefer.CityWorkMatConvertProcess:Find(self.workCfg:ConvertProcessCfg(i))
        for j = 1, convertProcessCfg:RecipesLength() do
            if convertProcessCfg:Recipes(j) == recipeId then
                return convertProcessCfg:Id()
            end
        end
    end
    return 0
end

function CityMaterialProcessV2UIParameter:GetFirstRecipeId()
    return 0
end

function CityMaterialProcessV2UIParameter:GetAllRecipe()
    return {}
end

function CityMaterialProcessV2UIParameter:GetAllMaterialRecipe()
    local ret, lockedMaterialRecipe = self:GetAllMaterialRecipeOrdered()
    for _, materialRecipeCfg in ipairs(lockedMaterialRecipe) do
        table.insert(ret, materialRecipeCfg)
    end
    return ret
end

function CityMaterialProcessV2UIParameter:GetUIStatusByRecipeId(recipeId, skipCheckProcess)
    local info = self:GetProcessInfo()
    if not skipCheckProcess and info ~= nil and info.ConfigId > 0 then
        if info.LeftNum > 0 then
            return UIStatusEnum.Working_Undergoing
        else
            return UIStatusEnum.Working_Finished
        end
    end
    
    local convertCfgId = self:GetConvertCfgIdByRecipeId(recipeId)
    local processCfg = ConfigRefer.CityWorkMatConvertProcess:Find(convertCfgId)
    if not self:IsConvertProcessUnlocked(processCfg) then
        return UIStatusEnum.NotWorking_Locked
    end
    return UIStatusEnum.NotWorking_Convert
end

function CityMaterialProcessV2UIParameter:IsMatConvertRecipeSelected(id)
    return self.matConvertRecipeId == id
end

---@param matConvertProcessCfg CityWorkMatConvertProcessConfigCell
function CityMaterialProcessV2UIParameter:SelectMatConvertRecipe(matConvertProcessCfg)
    if not self.mediator then return end

    if self.matConvertRecipeId == matConvertProcessCfg:Id() then
        return
    end
    self.matConvertRecipeId = matConvertProcessCfg:Id()
    self.recipeId = self:GetFirstRecipeIdInConvertCfg(matConvertProcessCfg)
    self.mediator:OnMaterialRecipeSelect(self.matConvertRecipeId, self.recipeId)
end

function CityMaterialProcessV2UIParameter:OnMediatorOpen(mediator)
    self.mediator = mediator
    self.matConvertRecipeId, self.recipeId = self:GetFirstMaterialRecipeIdImp()
end

function CityMaterialProcessV2UIParameter:OpenSpeedUpPanel()
    local furniture = self.cellTile:GetCell()
    local holder = CityMaterialProcessV2SpeedUpHolder.new(furniture)
    local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.MaterialProcess))
    local provider = require("CitySpeedUpGetMoreProvider").new()
    provider:SetHolder(holder)
    provider:SetItemList(itemList)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

return CityMaterialProcessV2UIParameter