local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityHatchEggUIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityHatchEggUIParameter
local CityHatchEggUIParameter = class("CityHatchEggUIParameter", CityCommonRightPopupUIParameter)
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")
local CastleDirectOpenEggsParameter = require("CastleDirectOpenEggsParameter")
local CastleDirectFinishWorkByCashParameter = require("CastleDirectFinishWorkByCashParameter")
local CastleSpeedUpByCashParameter = require("CastleSpeedUpByCashParameter")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CityHatchEggSpeedUpHolder = require("CityHatchEggSpeedUpHolder")
local UIMediatorNames = require("UIMediatorNames")
local CityHatchI18N = require("CityHatchI18N")
local CityProcessUtils = require("CityProcessUtils")

---@param cellTile CityFurnitureTile
function CityHatchEggUIParameter:ctor(cellTile)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.city = cellTile:GetCity()
    self.recipeId = 0
    self.onlyShowCanHatchImmediately = false
    self.isTipsCell = false
    self:UpdateWorkData()
end

function CityHatchEggUIParameter:UpdateWorkData()
    self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.Incubate] or 0
    ---@type CityWorkData
    self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    self.workCfg = nil
    local furLvCfg = self.cellTile:GetCell().furnitureCell
    for i = 1, furLvCfg:WorkListLength() do
        local workCfgId = furLvCfg:WorkList(i)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        if workCfg and workCfg:Type() == CityWorkType.Incubate then
            self.workCfg = workCfg
            break
        end
    end

    if self.workCfg == nil then
        g_Logger.ErrorChannel("CityProcessV2UIParameter", "制造界面数据异常")
    end
end

function CityHatchEggUIParameter:GetTitle()
    return self.cellTile:GetName()
end

function CityHatchEggUIParameter:GetOwnedEggCount()
    local ownCount = 0
    local unlockedRecipes, _ = self:GetAllRecipeOrdered()
    for i, v in ipairs(unlockedRecipes) do
        ownCount = ownCount + self:GetCostEnoughTimes(v)
    end
    return ownCount
end

function CityHatchEggUIParameter:GetCostEnoughTimes(processCfg)
    return CityProcessUtils.GetCostEnoughTimes(processCfg)
end

function CityHatchEggUIParameter:GetCanHatchImmediatelyCount()
    local count = 0
    local unlockedRecipes, _ = self:GetAllRecipeOrdered()
    for i, v in ipairs(unlockedRecipes) do
        if self:GetTargetRecipeOriginCostTime(v) <= 0 then
            count = count + self:GetCostEnoughTimes(v)
        end
    end
    return count
end

---@private
function CityHatchEggUIParameter:GetFirstRecipeId()
    if self.workCfg:ProcessCfgLength() > 0 then
        return self.workCfg:ProcessCfg(1)
    end
    return 0
end

function CityHatchEggUIParameter:GetHatchTimeDecrease()
    local recipeId = self.recipeId
    if recipeId == 0 or recipeId == nil then
        recipeId = self:GetFirstRecipeId()
    end
    if recipeId == 0 then
        return 0
    end
    local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
    return ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:TimeDecFixedAttr(), self.cellTile:GetCell().singleId)
end

function CityHatchEggUIParameter:GetProcessEggIcon()
    local info = self:GetProcessInfo()
    if info.ConfigId > 0 then
        local processCfg = ConfigRefer.CityWorkProcess:Find(info.ConfigId)
        return processCfg:OutputIcon()
    end
    return string.Empty
end

function CityHatchEggUIParameter:GetSelectedEggIcon()
    if self.recipeId > 0 then
        local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
        return processCfg:OutputIcon()
    end
    return string.Empty
end

function CityHatchEggUIParameter:GetSelectedEggName()
    if self.recipeId > 0 then
        local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
        local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
        local valid, itemCfg = ItemGroupHelper.GetItem(itemGroup)
        if valid then
            return I18N.Get(itemCfg:NameKey())
        end
    end
    return string.Empty
end

function CityHatchEggUIParameter:IsUndergoing()
    local info = self:GetProcessInfo()
    return info.ConfigId > 0 and info.LeftNum > 0
end

function CityHatchEggUIParameter:IsFinished()
    local info = self:GetProcessInfo()
    return info.ConfigId > 0 and info.LeftNum == 0
end

function CityHatchEggUIParameter:GetProcessInfo()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    return castleFurniture.ProcessInfo
end

---@param mediator CityHatchEggUIMediator
function CityHatchEggUIParameter:OnMediatorOpen(mediator)
    self.mediator = mediator
    if self:IsUndergoing() or self:IsFinished() then
        local info = self:GetProcessInfo()
        self.recipeId = info.ConfigId
        self.mediator:CloseSelectPanel()
    else
        local unlockedRecipes, _ = self:GetAllRecipeOrdered()
        if #unlockedRecipes > 0 and self:GetOwnedEggCount() > 0 then
            self.mediator:OnClickSelectEgg()
        else
            self.mediator:CloseSelectPanel()
        end
    end

    g_Game.ServiceManager:AddResponseCallback(CastleDirectOpenEggsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:AddResponseCallback(CastleGetProcessOutputParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:AddResponseCallback(CastleDirectFinishWorkByCashParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:AddResponseCallback(CastleSpeedUpByCashParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
end

---@param mediator CityHatchEggUIMediator
function CityHatchEggUIParameter:OnMediatorClose(mediator)
    g_Game.ServiceManager:RemoveResponseCallback(CastleDirectOpenEggsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:RemoveResponseCallback(CastleGetProcessOutputParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDirectFinishWorkByCashParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    g_Game.ServiceManager:RemoveResponseCallback(CastleSpeedUpByCashParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CheckIfRecipeUseOut))
    self.mediator = nil
end

function CityHatchEggUIParameter:GetSelectPanelData()
    return self
end

function CityHatchEggUIParameter:GetSpeedUpCoinIcon()
    local itemCfg = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg()
    return itemCfg:Icon()
end

function CityHatchEggUIParameter:GetSpeedUpRemainTimeCoinNeed()
    if not self:IsUndergoing() then return 0 end

    local remainTime = self:GetRemainTime()
    return ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
end

function CityHatchEggUIParameter:GetSpeedUpCoinOwn()
    return ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
end

function CityHatchEggUIParameter:GetHatchProgress()
    if not self:IsUndergoing() then return 0 end
    
    local info = self:GetProcessInfo()
    local gap = self.city:GetWorkTimeSyncGap()
    return math.clamp01((info.CurProgress + gap) / info.TargetProgress)
end

function CityHatchEggUIParameter:GetRemainTime()
    if not self:IsUndergoing() then return 0 end

    local info = self:GetProcessInfo()
    local gap = self.city:GetWorkTimeSyncGap()
    return (info.LeftNum) * info.TargetProgress - info.CurProgress - gap
end

function CityHatchEggUIParameter:IsSelected()
    return self.recipeId ~= 0
end

function CityHatchEggUIParameter:IsSelectImmediatelyRecipe()
    return self:IsSelected() and self:GetTargetRecipeOriginCostTime(ConfigRefer.CityWorkProcess:Find(self.recipeId)) <= 0
end

function CityHatchEggUIParameter:NeedShowBuffBubble()
    ---TODO:需要增温降温逻辑
    return false
end

function CityHatchEggUIParameter:GetRecipeCfgOriginCostTime(processCfg)
    return ConfigTimeUtility.NsToSeconds(processCfg:Time())
end

function CityHatchEggUIParameter:GetCurrentRecipeCfgOriginCostTime()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    return self:GetRecipeCfgOriginCostTime(processCfg)
end

function CityHatchEggUIParameter:GetTargetRecipeOriginCostTime(processCfg)
    local time = self:GetRecipeCfgOriginCostTime(processCfg)
    local decreasePercent = ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:TimeDecAttr(), self.cellTile:GetCell().singleId)
    local decreaseFixed = ModuleRefer.CastleAttrModule:GetValueWithFurniture(processCfg:TimeDecFixedAttr(), self.cellTile:GetCell().singleId)
    return math.max(0, time * (1 - decreasePercent) - decreaseFixed)
end

function CityHatchEggUIParameter:GetOriginalCostTime()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    return self:GetTargetRecipeOriginCostTime(processCfg)
end

function CityHatchEggUIParameter:GetHatchSelectedEggTime()
    local time = self:GetOriginalCostTime()
    if time == 0 then return time end

    local petDecrease = 0
    if self:CurrentRecipeNeedHeating() then
        local heatingFurnitures = self:GetHeatingFurnitures()
        for _, furniture in ipairs(heatingFurnitures) do
            local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
            if petIdMap == nil or next(petIdMap) == nil then
                goto continue
            end

            local furTypCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
            if furTypCfg:PetWorkTypeLimitLength() >= 1 then
                ---这里是个写死的逻辑，增温器的生效工种没有CityWork指定，所以直接从家具配置上指定
                goto continue
            end

            local petWorkType = furTypCfg:PetWorkTypeLimit(1)
            local petFactor = 0
            local attrValue = ModuleRefer.CastleAttrModule:GetValueWithFurniture(ConfigRefer.CityConfig:HeaterTimeDecreaseAttr(), furniture.singleId)
            for petId, _ in pairs(petIdMap) do
                local petDatum = self.city.petManager.cityPetData[petId]
                local workLevel = petDatum:GetWorkLevel(petWorkType)
                local levelFactor = self.city.petManager:GetLandFactor(workLevel)
                local hungry = petDatum.hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
                petFactor = petFactor + levelFactor * hungry
            end
            petDecrease = petDecrease + petFactor * attrValue
            
            ::continue::
        end
    end

    --- 这里文档上没有要求限制在0.9
    petDecrease = math.min(1, petDecrease)
    time = time * (1 - petDecrease)
    return time
end

function CityHatchEggUIParameter:IsAnyHeatingFurnitureActive()
    local heatingFurnitures = self:GetHeatingFurnitures()
    for _, furniture in ipairs(heatingFurnitures) do
        local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
        if petIdMap ~= nil and next(petIdMap) ~= nil then
            return true
        end
    end
    return false
end

function CityHatchEggUIParameter:CurrentRecipeNeedHeating()
    return true
end

function CityHatchEggUIParameter:GetHeatingFurnitures()
    return self.city.furnitureManager:GetFurnituresByTypeCfgId(ConfigRefer.CityConfig:TemperatureBooster())
end

function CityHatchEggUIParameter:GetSpeedUpCoinNeed()
    local time = self:GetHatchSelectedEggTime()
    return ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(time)
end

---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityHatchEggUIParameter:IsRecipeVisible(processCfg)
    return CityProcessUtils.IsRecipeVisible(processCfg)
end

---@protected
---@return boolean
---@param processCfg CityWorkProcessConfigCell
function CityHatchEggUIParameter:IsRecipeUnlocked(processCfg)
    return CityProcessUtils.IsRecipeUnlocked(processCfg)
end

function CityHatchEggUIParameter:GetAllRecipeOrdered()
    ---@type CityWorkProcessConfigCell[]
    local unlockedRecipes = {}
    ---@type CityWorkProcessConfigCell[]
    local lockedRecipes = {}
    for i = 1, self.workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(self.workCfg:ProcessCfg(i))
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
        local outputA = ConfigRefer.Item:Find(a:Output())
        local outputB = ConfigRefer.Item:Find(b:Output())
        if outputA:Quality() ~= outputB:Quality() then
            return outputA:Quality() > outputB:Quality()
        end

        return outputA:Id() < outputB:Id()
    end)

    ---@param a CityWorkProcessConfigCell
    ---@param b CityWorkProcessConfigCell
    table.sort(lockedRecipes, function(a, b)
        local outputA = ConfigRefer.Item:Find(a:Output())
        local outputB = ConfigRefer.Item:Find(b:Output())
        if outputA:Quality() ~= outputB:Quality() then
            return outputA:Quality() > outputB:Quality()
        end

        return outputA:Id() < outputB:Id()
    end)

    return unlockedRecipes, lockedRecipes
end

function CityHatchEggUIParameter:GetAllRecipe()
    local unlockedRecipes, lockedRecipes = self:GetAllRecipeOrdered()
    local allRecipes = {}
    for _, recipe in ipairs(unlockedRecipes) do
        table.insert(allRecipes, recipe)
    end
    for _, recipe in ipairs(lockedRecipes) do
        table.insert(allRecipes, recipe)
    end
    return allRecipes
end

function CityHatchEggUIParameter:OnClickDropdown(dropdownId)
    ---TODO:根据条件过滤
end

function CityHatchEggUIParameter:CloseSelectPanel()
    if self.mediator == nil then return end
    self.mediator:CloseSelectPanel()
    self.mediator:HideTips()
end

function CityHatchEggUIParameter:IsRecipeSelected(processCfg)
    return self.recipeId == processCfg:Id()
end

function CityHatchEggUIParameter:SelectRecipe(processCfg)
    if self.recipeId == processCfg:Id() then return end
    
    self.recipeId = processCfg:Id()
    if self.mediator == nil then return end
    self.mediator:UpdateSelectPanel()
    self.mediator:UpdateUI()
    self.mediator:PlaySelectEggVX()
    self.mediator:ShowTips()
end

function CityHatchEggUIParameter:SelectRecipeInOwnedEggsTips(processCfg)
    if self.recipeId == processCfg:Id() then return end
    self.recipeId = processCfg:Id()
    if self.mediator == nil then return end
    self.mediator:UpdateOwnedEggsList()
    self.mediator:ShowTips()
end

function CityHatchEggUIParameter:CanHatchCurrentEggImmediately()
    return self:GetHatchSelectedEggTime() <= 0
end

function CityHatchEggUIParameter:OpenEggBatch(count, rectTransform)
    local recipeMap = {}
    local counter = count
    local unlockedRecipes, _ = self:GetAllRecipeOrdered()
    for i, v in ipairs(unlockedRecipes) do
        if self:GetTargetRecipeOriginCostTime(v) <= 0 then
            local times = self:GetCostEnoughTimes(v)
            if times > 0 then
                local need = math.min(times, counter)
                recipeMap[v:Id()] = need
                counter = counter - need
            end
        end

        if counter <= 0 then
            break
        end
    end

    if counter > 0 then
        g_Logger.ErrorChannel("CityHatchEggUIParameter", "批量孵化失败，未找到足够的蛋")
        return
    end

    local cb = nil
    if self.mediator then
        self.mediator:CloseSelectPanel()
        self.mediator:HideTips()
        cb = function()
            self.mediator:UpdateUI()
        end
    end
    self:RequestDirectOpenEggs(recipeMap, rectTransform, cb)
end

---@param recipeMap table<number, number> @key:CityWorkProcessConfigCell.Id, value:count
function CityHatchEggUIParameter:RequestDirectOpenEggs(recipeMap, rectTransform, callback)
    local sum = 0
    for id, count in pairs(recipeMap) do
        sum = sum + count
    end
    if self:WillFull(sum, true) then
        return
    end

    local recipeId, _ = next(recipeMap)
    self.city.petManager:RecordLastHatchRecipe(recipeId)
    local param = CastleDirectOpenEggsParameter.new()
    param.args.FurnitureId = self.cellTile:GetCell().singleId
    param.args.WorkCfgId = self.workCfg:Id()
    param.args.ProcessCfgId2Count:AddRange(recipeMap)
    param:SendOnceCallback(rectTransform, nil, nil, function (_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
        end
    end)
end

function CityHatchEggUIParameter:RequestStart(rectTransform)
    local param = CastleStartWorkParameter.new()
    param.args.WorkCfgId = self.workCfg:Id()
    param.args.WorkTarget = self.cellTile:GetCell().singleId
    param.args.SubCfgId = self.recipeId
    param.args.Count = 1
    param:Send(rectTransform)
end

function CityHatchEggUIParameter:RequestClaim(rectTransform)
    if self:WillFull(1, true) then
        return
    end
    
    self.city.petManager:RecordLastHatchRecipe(self.recipeId)
    self.city.cityWorkManager:RequestCollectProcessLike(self.cellTile:GetCell().singleId, nil, self.workCfg:Id(), rectTransform)
end

function CityHatchEggUIParameter:RequestSpeedUp(rectTransform)
    if not self:IsUndergoing() then
        if self:WillFull(1, true) then
            return
        end

        if self:GetSpeedUpCoinNeed() <= self:GetSpeedUpCoinOwn() then
            self.city.petManager:RecordLastHatchRecipe(self.recipeId)
            self.city.cityWorkManager:RequestDirectFinishWorkByCash(self.cellTile:GetCell().singleId, self.workCfg:Id(), self.recipeId, 1, rectTransform, function()
                if self.mediator then
                    self.mediator:UpdateUI()
                end
            end)
        end
    else
        self.city.petManager:RecordLastHatchRecipe(self.recipeId)
        local furniture = self.cellTile:GetCell()
        local holder = CityHatchEggSpeedUpHolder.new(furniture)
        local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.Incubate))
        local provider = require("CitySpeedUpGetMoreProvider").new()
        provider:SetHolder(holder)
        provider:SetItemList(itemList)
        g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
    end
end

function CityHatchEggUIParameter:CheckIfRecipeUseOut(isSuccess, reply, rpc)
    if not isSuccess then return end
    if self.mediator == nil then return end
    if self.recipeId == 0 then
        self.mediator:UpdateUI()
        return
    end
    
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId)
    local count = self:GetCostEnoughTimes(processCfg)
    if count == 0 then
        self.recipeId = 0
    end
    self.mediator:UpdateUI()
end

function CityHatchEggUIParameter:WillFull(count, showToast)
    if ModuleRefer.PetModule:WillFull(count) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_animal_num_max"))
        end
        return true
    end
    return false
end

function CityHatchEggUIParameter:OnlyShowCanHatchImmediately(only)
    if only == nil then
        return self.onlyShowCanHatchImmediately
    end
    self.onlyShowCanHatchImmediately = only
end

function CityHatchEggUIParameter:IsTipsCell(is)
    if is == nil then
        return self.isTipsCell
    end
    self.isTipsCell = is
end

return CityHatchEggUIParameter