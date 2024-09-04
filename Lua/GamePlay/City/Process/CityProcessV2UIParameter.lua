local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityProcessV2UIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityProcessV2UIParameter
local CityProcessV2UIParameter = class("CityProcessV2UIParameter", CityCommonRightPopupUIParameter)
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIStatusEnum = require("CityProcessV2UIStatusEnum")
local CityPetAssignHandleProcessV2 = require("CityPetAssignHandleProcessV2")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local CityPetAssignmentUIParameter = require("CityPetAssignmentUIParameter")
local CastleAddPetParameter = require("CastleAddPetParameter")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local CityConst = require("CityConst")
local ItemGroupHelper = require("ItemGroupHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CityAttrType = require("CityAttrType")
local CityProcessV2SpeedUpHolder = require("CityProcessV2SpeedUpHolder")
local CityProcessV2I18N = require("CityProcessV2I18N")
local CityProcessUtils = require("CityProcessUtils")
local CityUtils = require("CityUtils")
local TimeFormatter = require("TimeFormatter")

---@param cellTile CityFurnitureTile
function CityProcessV2UIParameter:ctor(cellTile, forceRecipeId)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.city = cellTile:GetCity()
    self.forceRecipeId = forceRecipeId
    self.handle = CityPetAssignHandleProcessV2.new(self, Delegate.GetOrCreate(self, self.OnPetClick))
    self:UpdateWorkData()
end

function CityProcessV2UIParameter:UpdateWorkData()
    self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.Process] or 0
    ---@type CityWorkData
    self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    self.workCfg = nil
    local furLvCfg = self.cellTile:GetCell().furnitureCell
    for i = 1, furLvCfg:WorkListLength() do
        local workCfgId = furLvCfg:WorkList(i)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        if workCfg and workCfg:Type() == CityWorkType.Process then
            self.workCfg = workCfg
            break
        end
    end

    if self.workCfg == nil then
        g_Logger.ErrorChannel("CityProcessV2UIParameter", "制造界面数据异常")
    end
end

---@private
---@return table<number, boolean>
function CityProcessV2UIParameter:GetActivePetIdMap()
    if self.workData == nil then return {} end

    local ret = {}
    for id, flag in pairs(self.workData.petIdMap) do
        ret[id] = flag
    end
    return ret
end

---@return boolean @如果是家具制造则需要走另一套显示
function CityProcessV2UIParameter:IsMakingFurniture()
    for i = 1, self.workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(self.workCfg:ProcessCfg(i))
        if self:IsFurnitureRecipe(processCfg) then
            return true
        end
    end
    return false
end

function CityProcessV2UIParameter:GetWorkName()
    return I18N.Get(self.workCfg:Name())
end

function CityProcessV2UIParameter:NeedFeatureList()
    if self.workCfg:RequireWorkerType() ~= 0 then
        return {self.workCfg:RequireWorkerType()}
    end
    return nil
end

function CityProcessV2UIParameter:GetCastleFurniture()
    return self.cellTile:GetCastleFurniture()
end

function CityProcessV2UIParameter:GetProcessInfo()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture then
        return castleFurniture.ProcessInfo
    end
    return nil
end

function CityProcessV2UIParameter:IsMakingMaterial()
    return false
end

function CityProcessV2UIParameter:GetFirstRecipeId()
    return self.recipeId
end

function CityProcessV2UIParameter:GetFirstRecipeIdImp()
    local process = self:GetProcessInfo()
    if process and process.ConfigId > 0 then
        return process.ConfigId
    end
    
    if self.workCfg == nil then
        return 0
    end
    
    local unlockedRecipes, lockedRecipes = self:GetAllRecipeOrdered()
    local recipes = {}
    for _, processCfg in ipairs(unlockedRecipes) do
        local isMakingFurniture = CityProcessUtils.IsFurnitureRecipe(processCfg)
        if isMakingFurniture then
            local lvCfg = CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
            local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
            local ownCount = self.city.furnitureManager:GetFurnitureCountByTypeCfgId(typCfg:Id())
            local realMaxCount = self.city.furnitureManager:GetFurnitureMaxOwnCount(typCfg:Id())
            if ownCount < realMaxCount and
               CityProcessUtils.IsRecipeUnlocked(processCfg) and
               CityProcessUtils.IsRecipeVisible(processCfg) and
               CityProcessUtils.GetCostEnoughTimes(processCfg) > 0
            then
                table.insert(recipes, processCfg)
            end
        else
            if CityProcessUtils.IsRecipeUnlocked(processCfg) and
               CityProcessUtils.IsRecipeVisible(processCfg) and
               CityProcessUtils.GetCostEnoughTimes(processCfg) > 0
            then
                table.insert(recipes, processCfg)
            end
        end
    end

    if #recipes > 0 then
        if self.forceRecipeId then
            for i, v in ipairs(recipes) do
                if v:Id() == self.forceRecipeId then
                    return self.forceRecipeId
                end
            end
        else
            return recipes[#recipes]:Id() 
        end
    end

    if #unlockedRecipes > 0 then
        if self.forceRecipeId then
            for i, v in ipairs(unlockedRecipes) do
                if v:Id() == self.forceRecipeId then
                    return self.forceRecipeId
                end
            end
        else
            return unlockedRecipes[#unlockedRecipes]:Id()
        end
    end
    
    if #lockedRecipes > 0 then
        if self.forceRecipeId then
            for i, v in ipairs(lockedRecipes) do
                if v:Id() == self.forceRecipeId then
                    return self.forceRecipeId
                end
            end
        else
            return lockedRecipes[1]:Id()
        end
    end
    
    return 0
end

function CityProcessV2UIParameter:GetFirstFurnitureCategory()
    return self.furnitureCategory
end

function CityProcessV2UIParameter:GetFirstFurnitureCategoryImp()
    if self.recipeId == 0 then return 0 end

    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    if not self:IsFurnitureRecipe(processCfg) then return 0 end

    local output = ConfigRefer.Item:Find(processCfg:Output())
    local lvCfgId = checknumber(output:UseParam(1))
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    if not lvCfg then return 0 end

    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    return typeCfg:Category()
end

function CityProcessV2UIParameter:GetAllRecipeOrdered()
    ---@type CityWorkProcessConfigCell[]
    local unlockedRecipes = {}
    ---@type CityWorkProcessConfigCell[]
    local lockedRecipes = {}
    local isMakingFurniture = self:IsMakingFurniture()
    for i = 1, self.workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(self.workCfg:ProcessCfg(i))
        if isMakingFurniture then
            if not self:IsFurnitureRecipe(processCfg) then
                goto continue
            end
        end

        if self:IsRecipeVisible(processCfg) then
            if self:IsRecipeUnlocked(processCfg) then
                table.insert(unlockedRecipes, processCfg)
            else
                table.insert(lockedRecipes, processCfg)
            end
        end
        ::continue::
    end

    ---@param a CityWorkProcessConfigCell
    ---@param b CityWorkProcessConfigCell
    table.sort(unlockedRecipes, function(a, b)
        local idxA, idxB = a:Index(), b:Index()
        if idxA ~= idxB then
            return idxA < idxB
        end
        return a:Id() < b:Id()
    end)

    ---@param a CityWorkProcessConfigCell
    ---@param b CityWorkProcessConfigCell
    table.sort(lockedRecipes, function(a, b)
        local idxA, idxB = a:Index(), b:Index()
        if idxA ~= idxB then
            return idxA < idxB
        end
        return a:Id() < b:Id()
    end)

    return unlockedRecipes, lockedRecipes
end

function CityProcessV2UIParameter:GetAllRecipe()
    local ret, lockedRecipes = self:GetAllRecipeOrdered()
    for i, v in ipairs(lockedRecipes) do
        table.insert(ret, v)
    end
    return ret
end

function CityProcessV2UIParameter:GetAllFurnitureRecipes()
    local allRecipe = self:GetAllRecipe()
    if self.furnitureCategory == 0 then
        return allRecipe
    end

    local ret = {}
    for i, recipe in ipairs(allRecipe) do
        local output = ConfigRefer.Item:Find(recipe:Output())
        local lvCfgId = checknumber(output:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        if typeCfg:Category() == self.furnitureCategory then
            table.insert(ret, recipe)
        end
    end
    return ret
end

function CityProcessV2UIParameter:GetFirstMaterialRecipeId()
    return 0, 0
end

---@return CityWorkMatConvertProcessConfigCell[]
function CityProcessV2UIParameter:GetAllMaterialRecipe()
    return {}
end

---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:IsFurnitureRecipe(processCfg)
    return CityProcessUtils.IsFurnitureRecipe(processCfg)
end

---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:IsRecipeVisible(processCfg)
    return CityProcessUtils.IsRecipeVisible(processCfg)
end

---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:IsRecipeUnlocked(processCfg)
    return CityProcessUtils.IsRecipeUnlocked(processCfg)
end

---@protected
---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:IsRecipeCostEnough(processCfg)
    local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
    local costArray = ItemGroupHelper.GetPossibleOutput(itemGroup)
    for i, v in ipairs(costArray) do
        if v.minCount ~= v.maxCount then goto continue end

        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if own < v.minCount then
            return false
        end
        ::continue::
    end
    return true
end

---@private
---@return boolean @是否订单已经到达当前上限，但是没有到达最大上限
function CityProcessV2UIParameter:IsRecipeFull_NotReachLimit(processCfg)
    local lvCfg = CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    local ownCount = self.city.furnitureManager:GetFurnitureCountByTypeCfgId(typCfg:Id())
    local realMaxCount = self.city.furnitureManager:GetFurnitureMaxOwnCount(typCfg:Id())
    return ownCount >= realMaxCount
end

---@private
---@return boolean @是否订单已经到达最大上限
function CityProcessV2UIParameter:IsRecipeFull_ReachLimit(processCfg)
    local output = ConfigRefer.Item:Find(processCfg:Output())
    local lvCfgId = checknumber(output:UseParam(1))
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())

    local ownCount = self.city.furnitureManager:GetFurnitureCountByTypeCfgId(typCfg:Id())
    local maxCount = typCfg:MaxOwnCount()
    return ownCount >= maxCount
end

function CityProcessV2UIParameter:GetFurnitureOwnCountUpTasks(processCfg)
    local output = ConfigRefer.Item:Find(processCfg:Output())
    local lvCfgId = checknumber(output:UseParam(1))
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    local maxCount = typCfg:MaxOwnCount()
    local ret = {}
    for i = 1, math.min(typCfg:MaxOwnCountConditionLength(), maxCount) do
        local condition = typCfg:MaxOwnCountCondition(i)
        local taskGroupCfg = ConfigRefer.TaskGroup:Find(condition)
        if taskGroupCfg then
            for j = 1, taskGroupCfg:TasksLength() do
                local taskId = taskGroupCfg:Tasks(j)
                if not ModuleRefer.QuestModule:IsTaskFinishedAtLocalCache(taskId) then
                    table.insert(ret, taskId)
                end
            end     
        end
    end
    return ret
end

function CityProcessV2UIParameter:GetUIStatusByRecipeId(recipeId, skipCheckProcess)
    local info = self:GetProcessInfo()
    if not skipCheckProcess and info ~= nil and info.ConfigId > 0 then
        if info.LeftNum > 0 then
            return UIStatusEnum.Working_Undergoing
        else
            return UIStatusEnum.Working_Finished
        end
    end

    local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
    local isMakingFurniture = self:IsFurnitureRecipe(processCfg)
    if not self:IsRecipeUnlocked(processCfg) then
        return UIStatusEnum.NotWorking_Locked
    end
    if isMakingFurniture and self:IsRecipeFull_ReachLimit(processCfg) then
        return UIStatusEnum.NotWorking_LimitReach
    end
    if isMakingFurniture and self:IsRecipeFull_NotReachLimit(processCfg) then
        return UIStatusEnum.NotWorking_LimitNotReach
    end
    return UIStatusEnum.NotWorking_Process
end

function CityProcessV2UIParameter:GetUndergoingProcessCfg()
    local info = self:GetProcessInfo()
    if info ~= nil and info.ConfigId > 0 then
        return ConfigRefer.CityWorkProcess:Find(info.ConfigId)
    end
    return ConfigRefer.CityWorkProcess:Find(self.recipeId)
end

---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:GetMaxTimes()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    local fullTime = ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:DurationAttr(), self.cellTile:GetCell().singleId)
    local singleTime = self:GetRealCostTime()

    --- 制造时间如果为0了，那么就是时间上无限制
    if singleTime == 0 then
        return math.min(999, self:GetCostEnoughTimes())
    end

    if self:IsMakingFurniture() then
        local output = ConfigRefer.Item:Find(processCfg:Output())
        local lvCfgId = checknumber(output:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local furType = lvCfg:Type()
        local maxTimes = self.city.furnitureManager:GetFurnitureMaxOwnCount(furType)
        
        local existedCount = self.city.furnitureManager:GetFurnitureCountByTypeCfgId(furType)
        if existedCount >= maxTimes then return 0 end

        maxTimes = maxTimes - existedCount
        return math.min(maxTimes, self:GetCostEnoughTimes())
    end

    return math.min(math.floor(fullTime / singleTime), self:GetCostEnoughTimes())
end

---@private
function CityProcessV2UIParameter:GetCostEnoughTimes()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    return CityProcessUtils.GetCostEnoughTimes(processCfg)
end

function CityProcessV2UIParameter:IsMaterialEnough()
    return self:GetCostEnoughTimes() > 0
end

function CityProcessV2UIParameter:OpenExchangePanel()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
    local costArray = ItemGroupHelper.GetPossibleOutput(itemGroup)
    ---@type {id:number, num:number}[]
    local list = {}
    for i, v in ipairs(costArray) do
        if v.minCount ~= v.maxCount then goto continue end

        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if own < v.minCount then
            table.insert(list, {id = v.id, num = v.minCount - own})
        end
        ::continue::
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(list)
end

function CityProcessV2UIParameter:AutoSelectFullTimes()
    return true
end

---@return boolean
function CityProcessV2UIParameter:IsAssignedPetReduceTime()
    if not self:IsAssignedPet() then return false end

    return self:GetOriginalCostTime() > self:GetRealCostTime()
end

function CityProcessV2UIParameter:IsAssignedPet()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    return petIdMap ~= nil and next(petIdMap) ~= nil
end

function CityProcessV2UIParameter:IsUndergoing()
    local info = self:GetProcessInfo()
    if info then
        return info.LeftNum > 0
    end
    return false 
end

function CityProcessV2UIParameter:IsWaitClaim()
    local info = self:GetProcessInfo()
    if info then
        return info.LeftNum == 0 and info.FinishNum > 0
    end
    return false
end

---@return PetAssignComponentData
function CityProcessV2UIParameter:GetPetAssignData()
    ---@type CommonPetIconBaseData[]
    local assignedPets = {}
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            local petData = self.handle:GetPetData(petId, Delegate.GetOrCreate(self, self.OpenAssignPopupUI))
            table.insert(assignedPets, petData)
        end
    end

    return {
        assignedPets = assignedPets,
        slotCount = self.cellTile:GetCell():GetPetWorkSlotCount(),
        selectFunc = Delegate.GetOrCreate(self, self.OnPetSelect),
        isFullEfficiencyFunc = Delegate.GetOrCreate(self, self.IsAssignedPetFullEfficiency),
        feature = self.workCfg:RequireWorkerType(),
        getBlood = Delegate.GetOrCreate(self.city.petManager, self.city.petManager.GetHpPercent),
    }
end

function CityProcessV2UIParameter:IsAssignedPetFullEfficiency(petId)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if not pet then return false end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg and petWorkCfg:Type() == self.workCfg:RequireWorkerType() then
            return not self.city.petManager:IsLandNotFit(petWorkCfg:Level())
        end
    end
    return false
end

function CityProcessV2UIParameter:GetLastPetId()
    return nil
end

function CityProcessV2UIParameter:OnPetSelect(rectTransform, petAssignComponent)
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        local itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(param.handle.allPetsId,self.workCfg:RequireWorkerType())
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
    end
end

function CityProcessV2UIParameter:OpenAssignPopupUI(rectTransform)
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        local itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(param.handle.allPetsId,self.workCfg:RequireWorkerType())
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
    end
end

---@private
---@return CityPetAssignmentUIParameter
function CityProcessV2UIParameter:GenAssignPopupParam()
    local selectedPetsId = {}
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            selectedPetsId[petId] = true
        end
    end
    self.handle:Initialize(self.city, selectedPetsId,
        Delegate.GetOrCreate(self, self.OnPetClick),
        Delegate.GetOrCreate(self, self.PetFilterByFeature),
        Delegate.GetOrCreate(self, self.PetSort),
        Delegate.GetOrCreate(self, self.SwitchCheck),
        self.cellTile:GetCell():GetPetWorkSlotCount()
    )
    local title = I18N.Get("animal_work_popup_title")
    local features = self:NeedFeatureList()
    local param = CityPetAssignmentUIParameter.new(title, self.handle, features,
        Delegate.GetOrCreate(self, self.OnAssignmentCallback), true)
    return param
end

---@private
function CityProcessV2UIParameter:PetFilterByFeature(id)
    local features = self:NeedFeatureList()
    if features == nil or #features == 0 then
        return true
    end

    local map = {}
    for _, feature in ipairs(features) do
        map[feature] = true
    end

    local pet = ModuleRefer.PetModule:GetPetByID(id)
    if pet then
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if petWorkCfg and map[petWorkCfg:Type()] then
                return true
            end
        end
    end
    return false
end

function CityProcessV2UIParameter:PetSort(id1, id2)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        local assigned1 = petIdMap[id1]
        local assigned2 = petIdMap[id2]
        if assigned1 ~= assigned2 then
            return assigned1
        end
    end

    local free1 = self.handle:IsFreeById(id1)
    local free2 = self.handle:IsFreeById(id2)
    if free1 ~= free2 then
        return free1
    end

    local workSpeed1 = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, id1)
    local workLevel1 = self.city.petManager:GetWorkLevel(id1, self.workCfg:RequireWorkerType())
    local levelFactor1 = self.city.petManager:GetLandFactor(workLevel1)
    local hp1 = self.city.petManager:GetHp(id1)
    local hungry1 = hp1 == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1

    local workSpeed2 = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, id2)
    local workLevel2 = self.city.petManager:GetWorkLevel(id2, self.workCfg:RequireWorkerType())
    local levelFactor2 = self.city.petManager:GetLandFactor(workLevel2)
    local hp2 = self.city.petManager:GetHp(id2)
    local hungry2 = hp2 == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1

    return workSpeed1 * levelFactor1 * hungry1 > workSpeed2 * levelFactor2 * hungry2
end

---@private
---@return boolean @检查特定Id的宠物是否可以改选
function CityProcessV2UIParameter:SwitchCheck(id, flag)
    if self.city.petManager:IsPetInTroopWork(id) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_remove_tips"))
        return false
    end

    if self.cellTile:GetCell():GetPetWorkSlotCount() > 1 then
        return true
    end

    if flag then return true end
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap and next(petIdMap) then
        return id ~= next(petIdMap)
    end
    return true
end

---@private
---@param selectedPetsId table<number, boolean>
function CityProcessV2UIParameter:OnAssignmentCallback(selectedPetsId, onAsyncAssignCallback)
    return self.city.petManager:TryAssignPetToWorkFurniture(self.cellTile:GetCell().singleId, selectedPetsId, function()
        if not self.mediator then return end
        self.mediator:OnRecipeSelect(self.recipeId)
    end, onAsyncAssignCallback)
end

---@param petData CommonPetIconBaseData
function CityProcessV2UIParameter:OnPetClick(petData, rectTransform)
    local workTimeFunc = nil
    if self.city.petManager.cityPetData[petData.id] then
        workTimeFunc = Delegate.GetOrCreate(self.city.petManager, self.city.petManager.GetRemainWorkDesc)
    end
    local benefitFunc = Delegate.GetOrCreate(self, self.GetBenefitIconAndDesc)
    ---@type CityPetDetailsTipUIParameter
    local param = {
        id = petData.id,
        cfgId = petData.cfgId,
        Level = petData.level,
        removeFunc = nil,
        workTimeFunc = workTimeFunc,
        benefitFunc = benefitFunc,
        rectTransform = rectTransform,
    }
    g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, param)
    self.city.petManager:BITraceTipsOpen(self.cellTile:GetCell().singleId)
end

---@param mediator CityProcessV2UIMediator
function CityProcessV2UIParameter:OnMediatorOpen(mediator)
    self.mediator = mediator
    self.recipeId = self:GetFirstRecipeIdImp()
    if self:IsMakingFurniture() then
        self.furnitureCategory = self:GetFirstFurnitureCategoryImp()
    end
end

---@param mediator CityProcessV2UIMediator
function CityProcessV2UIParameter:OnMediatorClose(mediator)
    self.mediator = nil
end

function CityProcessV2UIParameter:GetBenefitIconAndDesc(petId)
    local param1 = self.workCfg:CustomParam1()
    local param2 = self.workCfg:CustomParam2()
    
    local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
    local workLevel = self.city.petManager:GetWorkLevel(petId, self.workCfg:RequireWorkerType())
    local levelFactor = self.city.petManager:GetLandFactor(workLevel)
    local hp = self.city.petManager:GetHp(petId)
    local hungry = hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
    local petDecrease = (workSpeed + param1) / param2 * levelFactor * hungry
    petDecrease = math.min(0.9, petDecrease)
    local originTime = self:GetOriginalCostTime()
    return "sp_city_icon_time_up", ("-%s"):format(TimeFormatter.TimerStringFormat(petDecrease * originTime, true))
end

function CityProcessV2UIParameter:IsRecipeSelected(recipeId)
    return self.recipeId == recipeId
end

---@param processCfg CityWorkProcessConfigCell
function CityProcessV2UIParameter:SelectRecipe(processCfg)
    if not self.mediator then return end

    if self.recipeId == processCfg:Id() then
        return
    end
    self.recipeId = processCfg:Id()
    self.mediator:OnRecipeSelect(self.recipeId)
end

function CityProcessV2UIParameter:GetCfgCostTime()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    return ConfigTimeUtility.NsToSeconds(processCfg:Time())
end

function CityProcessV2UIParameter:GetOriginalCostTime()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    local decreasePercent = ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:TimeDecAttr(), self.cellTile:GetCell().singleId)
    local decreaseFixed = ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:TimeDecFixedAttr(), self.cellTile:GetCell().singleId)
    return math.max(0, self:GetCfgCostTime() * (1 - decreasePercent) - decreaseFixed)
end

function CityProcessV2UIParameter:GetRealCostTime()
    local time = self:GetOriginalCostTime()
    if time == 0 then
        return time
    end

    if self:IsAssignedPet() then
        local petDecrease = 0
        local param1 = self.workCfg:CustomParam1()
        local param2 = self.workCfg:CustomParam2()
        local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
        for petId, _ in pairs(petIdMap) do
            local petDatum = self.city.petManager.cityPetData[petId]
            local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
            local workLevel = petDatum:GetWorkLevel(self.workCfg:RequireWorkerType())
            local levelFactor = self.city.petManager:GetLandFactor(workLevel)
            local hungry = petDatum.hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
            local value = (workSpeed + param1) / param2 * levelFactor * hungry
            petDecrease = petDecrease + value
        end

        petDecrease = math.min(0.9, petDecrease)
        time = time * (1 - petDecrease)
    end
    return time
end

function CityProcessV2UIParameter:GetFinishedTimes()
    local info = self:GetProcessInfo()
    if info == nil then return 0 end

    return info.FinishNum
end

function CityProcessV2UIParameter:GetSingleOutputProgress()
    local info = self:GetProcessInfo()
    if info == nil then return 0 end

    local gap = self.city:GetWorkTimeSyncGap()
    local now = info.CurProgress
    return math.clamp01((now + gap) / info.TargetProgress)
end

function CityProcessV2UIParameter:GetTotalOutputProgress()
    local info = self:GetProcessInfo()
    if info == nil then return 0 end

    local allTimes = info.FinishNum + info.LeftNum
    if allTimes == 0 then return 0 end

    return (info.FinishNum + self:GetSingleOutputProgress()) / allTimes
end

function CityProcessV2UIParameter:GetProcessingRemainTime()
    local info = self:GetProcessInfo()
    if info == nil then return 0 end

    local gap = self.city:GetWorkTimeSyncGap()
    local now = info.CurProgress
    local target = info.TargetProgress
    local remain = target - now - gap
    return math.max(0, info.LeftNum - 1) * target + remain
end

function CityProcessV2UIParameter:IsFurnitureCategorySelected(category)
    return self.furnitureCategory == category
end

function CityProcessV2UIParameter:SelectFurnitureCategory(category)
    if not self.mediator then return end
    if not self:IsMakingFurniture() then return end
    if self.furnitureCategory == category then
        return
    end

    self.furnitureCategory = category
    local recipeList = self:GetAllRecipe()
    for i, recipe in ipairs(recipeList) do
        local output = ConfigRefer.Item:Find(recipe:Output())
        local lvCfgId = checknumber(output:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        if typeCfg:Category() == category then
            self.recipeId = recipe:Id()
            break
        end
    end
    self.mediator:OnRecipeSelect(self.recipeId)
end

function CityProcessV2UIParameter:GetFoodAddIcon()
    return "sp_common_icon_blood"
end

function CityProcessV2UIParameter:OpenSpeedUpPanel()
    local furniture = self.cellTile:GetCell()
    local holder = CityProcessV2SpeedUpHolder.new(furniture)
    local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.Process))
    local provider = require("CitySpeedUpGetMoreProvider").new()
    provider:SetHolder(holder)
    provider:SetItemList(itemList)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function CityProcessV2UIParameter:RequestFinishImmediately(count, rectTransform)
    if count == 0 then return end
    local singleTime = self:GetRealCostTime()
    if ModuleRefer.ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(singleTime * count) then
        ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(singleTime * count, function ()
            self.city.cityWorkManager:RequestDirectFinishWorkByCash(self.cellTile:GetCell().singleId, self.workCfg:Id(), self.recipeId, count, rectTransform, function()
                if not self.mediator then return end
                self.mediator:OnRecipeSelect(self.recipeId)
            end)
            return true
        end)
    else
        ModuleRefer.ConsumeModule:GotoShop()
    end
end

function CityProcessV2UIParameter:RequestStartWork(rectTransform, workerIds, count)
    local param = CastleStartWorkParameter.new()
    param.args.WorkerIds:AddRange(workerIds)
    param.args.WorkCfgId = self.workCfg:Id()
    param.args.WorkTarget = self.cellTile:GetCell().singleId
    param.args.SubCfgId = self.recipeId
    param.args.Count = count
    param:SendOnceCallback(rectTransform, nil, true, Delegate.GetOrCreate(self, self.UpdateWorkData))
end

function CityProcessV2UIParameter:RequestCancel(rectTransform)
    if self.workId == 0 then return end

    CityUtils.OpenCommonConfirmUI(I18N.Get("se_quit_title"), I18N.Get("animal_work_interface_desc02"), function()
        if self.workId == 0 then return true end
        self.city.cityWorkManager:StopWork(self.workId, rectTransform, Delegate.GetOrCreate(self, self.UpdateWorkData))
        return true
    end)
end

function CityProcessV2UIParameter:RequestClaim(rectTransform)
    local isMakingFurniture = self:IsMakingFurniture()
    if isMakingFurniture then
        local castleFurniture = self:GetCastleFurniture()
        local recipeId = castleFurniture.ProcessInfo.ConfigId
        local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
        local output = ConfigRefer.Item:Find(processCfg:Output())
        local lvCfgId = checknumber(output:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local param = CastleGetProcessOutputParameter.new()
        param.args.FurnitureId = self.cellTile:GetCell().singleId
        param.args.WorkCfgId = self.workCfg:Id()
        param:SendOnceCallback(rectTransform, nil, true, function()
            g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
            g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
            self.city:EnterBuildFurniture(lvCfg)
        end)
    else
        local param = CastleGetProcessOutputParameter.new()
        param.args.FurnitureId = self.cellTile:GetCell().singleId
        param.args.WorkCfgId = self.workCfg:Id()
        param:Send(rectTransform)
    end
end

function CityProcessV2UIParameter:HasAnyCategoryFurniture(category)
    local isMakingFurniture = self:IsMakingFurniture()
    if not isMakingFurniture then return false end

    local recipeList = self:GetAllRecipe()
    for i, recipe in ipairs(recipeList) do
        local output = ConfigRefer.Item:Find(recipe:Output())
        local lvCfgId = checknumber(output:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        if typeCfg:Category() == category then
            return true
        end
    end

    return false
end

return CityProcessV2UIParameter