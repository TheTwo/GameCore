
---@class CityManageCenterUIParameter
---@field new fun():CityManageCenterUIParameter
local CityManageCenterUIParameter = class("CityManageCenterUIParameter")
local CityManageCenterTabIndex = {
    Overview = 1,
    Development = 2,
    HatchEgg = 3,
    ResourceProcessing = 4,
    FoodProcessing = 5,
    TextileProcessing = 6,
    Making = 7,
}
local CityManageCenterTabName = {
    [CityManageCenterTabIndex.Overview] = "UI_Btn_PageOverview",
    [CityManageCenterTabIndex.Development] = "Development",
    [CityManageCenterTabIndex.HatchEgg] = "HatchEgg",
    [CityManageCenterTabIndex.ResourceProcessing] = "ResourceProcessing",
    [CityManageCenterTabIndex.FoodProcessing] = "FoodProcessing",
    [CityManageCenterTabIndex.TextileProcessing] = "TextileProcessing",
    [CityManageCenterTabIndex.Making] = "Making",
}
local I18N = require("I18N")
local CityManageCenterTabData = require("CityManageCenterTabData")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local CityManageOverviewUpgradeCellData = require("CityManageOverviewUpgradeCellData")
local CityManageOverviewHatchEggCellData = require("CityManageOverviewHatchEggCellData")
local CityManageCenterI18N = require("CityManageCenterI18N")
local NumberFormatter = require("NumberFormatter")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local EventConst = require("EventConst")
local QueuedTask = require("QueuedTask")

---@param city City
function CityManageCenterUIParameter:ctor(city)
    self.city = city
end

function CityManageCenterUIParameter:GetCurrentJobCount()
    local currentJobCount = self.city.petManager:GetAssignedPetCount()
    local maxJobCount = 0
    for id, furniture in pairs(self.city.furnitureManager.hashMap) do
        maxJobCount = maxJobCount + furniture:GetPetWorkSlotCount()
    end
    return currentJobCount, maxJobCount
end

---@return CityManageCenterTabData[]
function CityManageCenterUIParameter:GetTabDataList()
    local ret = {}
    for _, tabIdx in pairs(CityManageCenterTabIndex) do
        if self:IsTabVisible(tabIdx) then
            local tabData = CityManageCenterTabData.new(self, tabIdx)
            table.insert(ret, tabData)
        end
    end
    return ret
end

function CityManageCenterUIParameter:IsTabVisible(tabIdx)
    if tabIdx == CityManageCenterTabIndex.Overview then
        return true
    else
        --- 本版本屏蔽其他分页
        return false
    end

    if tabIdx == CityManageCenterTabIndex.Development then
        return self:HasAnyDevelopmentFurniture()
    elseif tabIdx == CityManageCenterTabIndex.HatchEgg then
        return self:HasAnyHatchEggFurniture()
    elseif tabIdx == CityManageCenterTabIndex.ResourceProcessing then
        return self:HasAnyResourceProcessingFurniture()
    elseif tabIdx == CityManageCenterTabIndex.FoodProcessing then
        return self:HasAnyFoodProcessingFurniture()
    elseif tabIdx == CityManageCenterTabIndex.TextileProcessing then
        return self:HasAnyTextileProcessingFurniture()
    elseif tabIdx == CityManageCenterTabIndex.Making then
        return self:HasAnyMakingFurniture()
    end
end

function CityManageCenterUIParameter:OnTabClick(index)
    if self.index == index then return end
    if index == CityManageCenterTabIndex.Overview then
        self:ShowOverviewPage()
    elseif index == CityManageCenterTabIndex.Development then
        self:ShowDevelopmentPage()
    elseif index == CityManageCenterTabIndex.HatchEgg then
        self:ShowHatchEggPage()
    elseif index == CityManageCenterTabIndex.ResourceProcessing then
        self:ShowResourceProcessingPage()
    elseif index == CityManageCenterTabIndex.FoodProcessing then
        self:ShowFoodProcessingPage()
    elseif index == CityManageCenterTabIndex.TextileProcessing then
        self:ShowTextileProcessingPage()
    elseif index == CityManageCenterTabIndex.Making then
        self:ShowMakingPage()
    end
end

function CityManageCenterUIParameter:GetButtonName(index)
    return I18N.Get(CityManageCenterTabName[index])
end

function CityManageCenterUIParameter:HasAnyDevelopmentFurniture()
    for i = 1, ConfigRefer.CityConfig:BuildingMasterStatuesLength() do
        local buildMaster = ConfigRefer.CityConfig:BuildingMasterStatues(i)
        if self.city.furnitureManager:HasFurnitureByTypeCfgId(buildMaster) then
            return true
        end
    end
    local sprinthot = ConfigRefer.CityConfig:HotSpringFurniture()
    return self.city.furnitureManager:HasFurnitureByTypeCfgId(sprinthot)
end

function CityManageCenterUIParameter:HasAnyHatchEggFurniture()
    return self.city.furnitureManager:HasFurnitureCountByCityWorkType(CityWorkType.Incubate)
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(ConfigRefer.CityConfig:TemperatureBooster())
end

function CityManageCenterUIParameter:HasAnyResourceProcessingFurniture()
    return self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000201'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000301'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000401'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003001'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003101'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003201'])
end

function CityManageCenterUIParameter:HasAnyFoodProcessingFurniture()
    return self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000501'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000601'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000701'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000801'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1000901'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1001201'])
end

function CityManageCenterUIParameter:HasAnyTextileProcessingFurniture()
    return self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1001001'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1001101'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003301'])
end

function CityManageCenterUIParameter:HasAnyMakingFurniture()
    return self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003401'])
        or self.city.furnitureManager:HasFurnitureByTypeCfgId(CityFurnitureTypeNames['1003501'])
end

function CityManageCenterUIParameter:ShowOverviewPage()
    self.index = CityManageCenterTabIndex.Overview
    self.mediator._p_group_view:SetVisible(true)
    self.mediator._p_group_detail:SetVisible(false)
    self.mediator._p_group_view:FeedData(self)
end

function CityManageCenterUIParameter:ShowDevelopmentPage()
    self.index = CityManageCenterTabIndex.Development
    self.mediator._p_group_view:SetVisible(false)
    self.mediator._p_group_detail:SetVisible(true)
    self.mediator._p_group_detail:FeedData(self)
end

function CityManageCenterUIParameter:ShowHatchEggPage()
    self.index = CityManageCenterTabIndex.Development
    self.mediator._p_group_view:SetVisible(false)
    self.mediator._p_group_detail:SetVisible(true)
    self.mediator._p_group_detail:FeedData(self)
end

function CityManageCenterUIParameter:ShowResourceProcessingPage()
    self.index = CityManageCenterTabIndex.Development
    self.mediator._p_group_view:SetVisible(false)
    self.mediator._p_group_detail:SetVisible(true)
    self.mediator._p_group_detail:FeedData(self)
end

function CityManageCenterUIParameter:ShowFoodProcessingPage()
    self.index = CityManageCenterTabIndex.Development
    self.mediator._p_group_view:SetVisible(false)
    self.mediator._p_group_detail:SetVisible(true)
    self.mediator._p_group_detail:FeedData(self)
end

function CityManageCenterUIParameter:ShowTextileProcessingPage()
    self.index = CityManageCenterTabIndex.Development
    self.mediator._p_group_view:SetVisible(false)
    self.mediator._p_group_detail:SetVisible(true)
    self.mediator._p_group_detail:FeedData(self)
end

function CityManageCenterUIParameter:ShowMakingPage()
    
end

---@param mediator CityManageCenterUIMediator
function CityManageCenterUIParameter:OnMediatorOpened(mediator)
    self.mediator = mediator
    self:InitHungryPetCache()
    self:ShowOverviewPage()
end

---@param mediator CityManageCenterUIMediator
function CityManageCenterUIParameter:OnMediatorClosed(mediator)
    self.mediator = nil
end

function CityManageCenterUIParameter:InitHungryPetCache()
    self.hunryPetIds = {}
    for id, petDatum in pairs(self.city.petManager.cityPetData) do
        if petDatum:IsHungry() then
            table.insert(self.hunryPetIds, id)
        end
    end

    if #self.hunryPetIds > 0 then
        table.sort(self.hunryPetIds, function(a, b)
            return self.city.petManager.cityPetData[a].hp < self.city.petManager.cityPetData[b].hp
        end)
        self.mostHungryPet = self.city.petManager.cityPetData[self.hunryPetIds[1]]
    end
end

function CityManageCenterUIParameter:GetAllPetsEmojiStatus()
    if self:GetExaustedPetCount() > 0 then
        return 2, I18N.Get("animal_work_interface_desc40")
    end

    if self:GetHungryPetCount() > 0 then
        local mostHungryPet = self.mostHungryPet
        local decreaseInterval = ConfigRefer.CityConfig:PetDecreaseHpInterval()
        local decreaseAmount = self.city.petManager:GetDecreaseHpAmountPerTime()
        local time = math.ceil(mostHungryPet.hp / decreaseAmount) * decreaseInterval
        return 2, I18N.GetWithParams("animal_work_interface_desc40", TimeFormatter.TimerStringFormat(time))
    end

    local remainTime = self.city.petManager:GetRemainFoodCanAffordTime()
    local maxTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:MaxOfflineWorkTime())
    if remainTime >= maxTime then
        return 0, I18N.GetWithParams("animal_work_interface_desc38", TimeFormatter.TimerStringFormat(maxTime))
    else
        return 1, I18N.GetWithParams("animal_work_interface_desc39", TimeFormatter.TimerStringFormat(remainTime))
    end
end

function CityManageCenterUIParameter:GetFoodHintText()
    local petCount = self:GetPetCount()
    local decreaseInterval = ConfigRefer.CityConfig:PetDecreaseHpInterval()
    local decreaseAmount = self.city.petManager:GetDecreaseHpAmountPerTime()
    local maxTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:MaxOfflineWorkTime())
    local forceKeep = self.city.petManager:GetForceKeepFoodCount()
    local needAmount = (maxTime // decreaseInterval) * decreaseAmount * petCount + forceKeep
    local currentFood = self.city.petManager:GetAllFood()
    return ("%s/%s"):format(NumberFormatter.Normal(currentFood), NumberFormatter.Normal(needAmount))
end

function CityManageCenterUIParameter:IsStoreroomFull()
    local castle = self.city:GetCastle()
    for itemId, max in pairs(castle.GlobalAttr.ResCapacity) do
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
        if own >= max then
            return true
        end
    end
    return false
end

function CityManageCenterUIParameter:IsAnyPetHungry()
    return self:GetHungryPetCount() > 0
end

function CityManageCenterUIParameter:GetExaustedPetCount()
    local count = 0
    for id, petDatum in pairs(self.city.petManager.cityPetData) do
        if petDatum:IsExhausted() then
            count = count + 1
        end
    end
    return count
end

function CityManageCenterUIParameter:GetHungryPetCount()
    return #self.hunryPetIds
end

function CityManageCenterUIParameter:GetPetCount()
    return table.nums(self.city.petManager.cityPetData)
end

---@return CityPetDatum
function CityManageCenterUIParameter:GetHungryPet(index)
    if index <= self:GetHungryPetCount() then
        return self.city.petManager.cityPetData[self.hunryPetIds[index]]
    end
    return nil
end

function CityManageCenterUIParameter:GetBuildQueue()
    local currentCount = 0
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    for id, castleFurniture in pairs(castleFurnitureMap) do
        if castleFurniture.LevelUpInfo.Working then
            if castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress then
                currentCount = currentCount + 1
            end
        end
    end
    return currentCount
end

function CityManageCenterUIParameter:GetBuildQueueMax()
    return ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.ConstructQueueCount)
end

function CityManageCenterUIParameter:GetEggQueue()
    local currentCount = 0
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    for id, castleFurniture in pairs(castleFurnitureMap) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
        for i = 1, lvCfg:WorkListLength() do
            local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
            if workCfg:Type() == CityWorkType.Incubate then
                if castleFurniture.ProcessInfo.ConfigId > 0 then
                    currentCount = currentCount + 1
                end
                break
            end
        end
    end
    return currentCount
end

function CityManageCenterUIParameter:GetEggQueueMax()
    return self.city.furnitureManager:GetFurnitureCountByTypeCfgId(CityFurnitureTypeNames["1002801"], false, true)
end

---@return CityManageOverviewUpgradeCellData[]
function CityManageCenterUIParameter:GetBuildQueueList()
    local list = {}
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    for id, castleFurniture in pairs(castleFurnitureMap) do
        if castleFurniture.LevelUpInfo.Working then
            if castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress then
                table.insert(list, CityManageOverviewUpgradeCellData.new(self, id, false))
            end
        end
    end

    local buildQueueMax = self:GetBuildQueueMax()
    for i = #list + 1, buildQueueMax do
        table.insert(list, CityManageOverviewUpgradeCellData.new(self, nil, true))
    end

    ---TODO:看一下礼包怎么加

    return list
end

---@return CityManageOverviewHatchEggCellData[]
function CityManageCenterUIParameter:GetHatchEggQueueList()
    local list = {}
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    for id, castleFurniture in pairs(castleFurnitureMap) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
        for i = 1, lvCfg:WorkListLength() do
            local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
            if workCfg:Type() == CityWorkType.Incubate then
                table.insert(list, CityManageOverviewHatchEggCellData.new(self, id, castleFurniture))
                break
            end
        end
    end

    local eggQueueMax = self:GetEggQueueMax()
    for i = #list + 1, eggQueueMax do
        table.insert(list, CityManageOverviewHatchEggCellData.new(self))
    end

    return list
end

function CityManageCenterUIParameter:UpdateBuildQueue()
    if self.mediator == nil then return end

    self.mediator._p_group_view:UpdateBuildQueueTable()
end

---@param furniture CityFurniture
function CityManageCenterUIParameter:IsMobileUnitNotMatchAllFeature(furniture)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId) or {}
    local petWorkMap = {}
    for petId, _ in pairs(petIdMap) do
        local petData = self.city.petManager.cityPetData[petId]
        for feature, _ in pairs(petData.workAbility) do
            petWorkMap[feature] = true
        end
    end

    local detailCfg = ConfigRefer.HotSpringDetail:Find(furniture.furnitureCell:HotSpringDetailInfo())
    for i = 1, detailCfg:AdditionProductsLength() do
        local addition = detailCfg:AdditionProducts(i)
        if not petWorkMap[addition:PetWorkType()] then
            return true
        end
    end

    return false
end

function CityManageCenterUIParameter:GetNonPetFurnitureCount()
    local count = 0
    for id, furniture in pairs(self.city.furnitureManager.hashMap) do
        if furniture:IsBuildMaster() then
            if self.city.petManager:GetPetCountByWorkFurnitureId(furniture.singleId) == 0 then
                count = count + 1
            end
        elseif furniture:IsHotSpring() then
            if self:IsMobileUnitNotMatchAllFeature(furniture) then
                count = count + 1
            end
        elseif furniture:CanDoCityWork(CityWorkType.ResourceProduce) then
            if self.city.petManager:GetPetCountByWorkFurnitureId(furniture.singleId) == 0 then
                count = count + 1
            end
        end
    end

    return count
end

function CityManageCenterUIParameter:GetNonPetFurnitureList()
    local list = {}
    for id, furniture in pairs(self.city.furnitureManager.hashMap) do
        if furniture:IsBuildMaster() then
            if self.city.petManager:GetPetCountByWorkFurnitureId(furniture.singleId) == 0 then
                table.insert(list, furniture)
            end
        elseif furniture:IsHotSpring() then
            if self:IsMobileUnitNotMatchAllFeature(furniture) then
                table.insert(list, furniture)
            end
        elseif furniture:CanDoCityWork(CityWorkType.ResourceProduce) then
            if self.city.petManager:GetPetCountByWorkFurnitureId(furniture.singleId) == 0 then
                table.insert(list, furniture)
            end
        end
    end

    return list
end

function CityManageCenterUIParameter:GotoUpgradeStoreroom()
    if self.city.showed then
        local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
        if furniture == nil then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityManageCenterI18N.Toast_NoStoreroom))
            return
        end

        local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
        if tile == nil then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityManageCenterI18N.Toast_NoStoreroom))
            return
        end

        local camera = self.city.camera
        if self.mediator then
            self.mediator:CloseSelf()
        end
        camera:LookAt(tile:GetWorldCenter(), 0.5, function()
            furniture:TryOpenLvUpUI()
        end)
    else
        if self.mediator then
            self.mediator:CloseSelf()
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
            local queueTask = QueuedTask.new()
            queueTask:WaitTrue(function()
                return self.city ~= nil and self.city.showed
            end):DoAction(function()
                self:GotoUpgradeStoreroom()
            end):Start()
        end)
    end
end

function CityManageCenterUIParameter:GotoMakingFood()
    if self.city.showed then
        local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(CityFurnitureTypeNames["1001201"])
        if furniture == nil then
            ModuleRefer.GuideModule:CallGuide(1053)
            return
        end

        local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
        if tile == nil then
            ModuleRefer.GuideModule:CallGuide(1053)
            return
        end

        local UIMediatorNames = require("UIMediatorNames")
        local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
        local param = CityProcessV2UIParameter.new(tile)
        local camera = self.city.camera
        if self.mediator then
            self.mediator:CloseSelf()
        end
        camera:LookAt(tile:GetWorldCenter(), 0.5, function()
            g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
        end)
    else
        if self.mediator then
            self.mediator:CloseSelf()
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
            local queueTask = QueuedTask.new()
            queueTask:WaitTrue(function()
                return self.city ~= nil and self.city.showed
            end):DoAction(function()
                self:GotoMakingFood()
            end):Start()
        end)
    end
end

function CityManageCenterUIParameter:GotoUpgradeAny()
    if self.city.showed then
        local tarFurniture = nil
        for id, furniture in pairs(self.city.furnitureManager.hashMap) do
            if furniture:CanUpgrade() then
                tarFurniture = furniture
                break
            end
        end

        if tarFurniture == nil then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityManageCenterI18N.Toast_NoUpgrade))
            return
        end

        local tile = self.city.gridView:GetFurnitureTile(tarFurniture.x, tarFurniture.y)
        if tile == nil then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityManageCenterI18N.Toast_NoUpgrade))
            return
        end

        local camera = self.city.camera
        if self.mediator then
            self.mediator:CloseSelf()
        end
        camera:LookAt(tile:GetWorldCenter(), 0.5, function()
            tarFurniture:TryOpenLvUpUI()
        end)
    else
        if self.mediator then
            self.mediator:CloseSelf()
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
            local queueTask = QueuedTask.new()
            queueTask:WaitTrue(function()
                return self.city ~= nil and self.city.showed
            end):DoAction(function()
                self:GotoUpgradeAny()
            end):Start()
        end)
    end
end

function CityManageCenterUIParameter:GotoHatchEgg(furnitureId)
    if self.city.showed then
        local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
        if furniture == nil then
            return
        end

        local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
        if tile == nil then
            return
        end

        local camera = self.city.camera
        if self.mediator then
            self.mediator:CloseSelf()
        end
        camera:LookAt(tile:GetWorldCenter(), 0.5, function()
            furniture:TryOpenHatchEggUI()
        end)
    else
        if self.mediator then
            self.mediator:CloseSelf()
        end
        g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
            local queueTask = QueuedTask.new()
            queueTask:WaitTrue(function()
                return self.city ~= nil and self.city.showed
            end):DoAction(function()
                self:GotoHatchEgg(furnitureId)
            end):Start()
        end)
    end
end

return CityManageCenterUIParameter