local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityMobileUnitUIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityMobileUnitUIParameter
local CityMobileUnitUIParameter = class("CityMobileUnitUIParameter", CityCommonRightPopupUIParameter)
local CityMobileUnitPetAssignHandle = require("CityMobileUnitPetAssignHandle")
local CityMobileUnitPetCellData = require("CityMobileUnitPetCellData")
local Delegate = require("Delegate")
local I18N = require("I18N")
local CityPetAssignmentUIParameter = require("CityPetAssignmentUIParameter")
local CastleAddPetParameter = require("CastleAddPetParameter")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local EfficiencyConditionType = require("EfficiencyConditionType")
local NumberFormatter = require("NumberFormatter")
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local TimeFormatter = require("TimeFormatter")
local CityPetUtils = require("CityPetUtils")
local UIHelper = require("UIHelper")

function CityMobileUnitUIParameter:ctor(cellTile)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.city = cellTile:GetCity()
    self.handle = CityMobileUnitPetAssignHandle.new(self)
    self.detailCfg = ConfigRefer.HotSpringDetail:Find(cellTile:GetCell().furnitureCell:HotSpringDetailInfo())
end

---@param uiMediator CityMobileUnitUIMediator
function CityMobileUnitUIParameter:OnMediatorOpen(uiMediator)
    self.mediator = uiMediator
end

---@param uiMediator CityMobileUnitUIMediator
function CityMobileUnitUIParameter:OnMediatorClosed(uiMediator)
    self.mediator = nil
end

function CityMobileUnitUIParameter:GetName()
    return I18N.Get("hotspring_subtitle01")
end

---@return {icon:string, value:string}
function CityMobileUnitUIParameter:GetOutputList()
    local itemMap = {}
    local multi = self:GetMulti()

    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        if self:HasTargetWorkType(addition:PetWorkType()) then
            local itemGroup = ConfigRefer.ItemGroup:Find(addition:Product())
            local itemArray = ItemGroupHelper.GetPossibleOutput(itemGroup)
            for i, item in ipairs(itemArray) do
                itemMap[item.id] = (itemMap[item.id] or 0) + multi * item.minCount
            end
        end
    end

    local perHour = 1--3600 / ConfigRefer.CityConfig:OfflineBenefitInterval()
    local ret = {}
    for i = 1, self.detailCfg:DisplayOutputLength() do
        local itemId = self.detailCfg:DisplayOutput(i)
        local itemCfg = ConfigRefer.Item:Find(itemId)
        local count = itemMap[itemId] or 0
        table.insert(ret, {icon = itemCfg:Icon(), value = ("%s/h"):format(NumberFormatter.NumberAbbr(math.floor(count * perHour), true))})
    end
    return ret
end

function CityMobileUnitUIParameter:GetMulti()
    local base = 1
    for i = 1, self.detailCfg:ConditionsLength() do
        local condition = self.detailCfg:Conditions(i)
        local conditionType = condition:EfficiencyConditionType()
        if conditionType == EfficiencyConditionType.AssociatedTagNumAbove then
            local num = self:GetAssociatedTagInfoPetCount(condition:EfficiencyConditionLeftValue())
            if num >= condition:EfficiencyConditionRightValue() then
                base = base + (condition:EfficiencyAdd() / 100)
            end
        elseif conditionType == EfficiencyConditionType.PetQualityNumAbove then
            local num = self:GetPetQualityCount(condition:EfficiencyConditionLeftValue())
            if num >= condition:EfficiencyConditionRightValue() then
                base = base + (condition:EfficiencyAdd() / 100)
            end
        elseif conditionType == EfficiencyConditionType.PetLevelSumAbove then
            local num = self:GetPetWorkTypeLevelSum(condition:EfficiencyConditionLeftValue())
            if num >= condition:EfficiencyConditionRightValue() then
                base = base + (condition:EfficiencyAdd() / 100)
            end
        end
    end
    return base
end

function CityMobileUnitUIParameter:GetAssociatedTagInfoPetCount(associatedTag)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if not petIdMap then return 0 end

    local ret = 0
    for petId, _ in pairs(petIdMap) do
        local petData = self.city.petManager.cityPetData[petId]
        if petData and petData.petCfg:AssociatedTagInfo() == associatedTag then
            ret = ret + 1
        end
    end
    return ret
end

function CityMobileUnitUIParameter:GetPetQualityCount(quality)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if not petIdMap then return 0 end

    local ret = 0
    for petId, _ in pairs(petIdMap) do
        local petData = self.city.petManager.cityPetData[petId]
        if petData and petData:GetQuality() >= quality then
            ret = ret + 1
        end
    end
    return ret
end

function CityMobileUnitUIParameter:GetPetWorkTypeLevelSum(petWorkType)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if not petIdMap then return 0 end

    local ret = 0
    for petId, _ in pairs(petIdMap) do
        local petData = self.city.petManager.cityPetData[petId]
        if petData and petData:HasWorkType(petWorkType) then
            ret = ret + petData:GetWorkLevel(petWorkType)
        end
    end
    return ret
end

function CityMobileUnitUIParameter:HasTargetWorkType(petWorkType)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if not petIdMap then return false end

    for petId, _ in pairs(petIdMap) do
        local petData = self.city.petManager.cityPetData[petId]
        if petData and petData:HasWorkType(petWorkType) then
            return true
        end
    end

    return false
end

function CityMobileUnitUIParameter:ShowFeatureNeed()
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        if not self:HasTargetWorkType(addition:PetWorkType()) then
            return true
        end
    end
    return false
end

---@return number[] @PetWorkType[]
function CityMobileUnitUIParameter:NeedFeatureList(isMap)
    local ret = {}
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        if isMap then
            ret[addition:PetWorkType()] = true
        else
            table.insert(ret, addition:PetWorkType())
        end
    end
    return ret
end

---@return number[] @PetWorkType[]
function CityMobileUnitUIParameter:GetCurrentNeedFeatureList()
    local ret = {}
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        if not self:HasTargetWorkType(addition:PetWorkType()) then
            table.insert(ret, addition:PetWorkType())
        end
    end
    return ret
end

function CityMobileUnitUIParameter:ShowBonus()
    return self.detailCfg:ConditionsLength() > 0
end

function CityMobileUnitUIParameter:GetBonusText()
    return NumberFormatter.PercentWithSignSymbol(self:GetMulti() - 1, 0, true)
end

---@return {param:CityMobileUnitUIParameter, condition:EfficiencyCondition}[]
function CityMobileUnitUIParameter:GetBonusList()
    local ret = {}
    for i = 1, self.detailCfg:ConditionsLength() do
        local data = {param = self, condition = self.detailCfg:Conditions(i)}
        table.insert(ret, data)
    end
    return ret
end

function CityMobileUnitUIParameter:GetSlotCount()
    return self.cellTile:GetCell():GetPetWorkSlotCount()
end

function CityMobileUnitUIParameter:GetMaxCount()
    return 6
end

---@return CityMobileUnitPetCellData[]
function CityMobileUnitUIParameter:GetPetCellData()
    local ret = {}
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            local petData = self.handle:GetPetData(petId, Delegate.GetOrCreate(self, self.OpenAssignPopupUI))
            if petData then
                local data = CityMobileUnitPetCellData.new(petData, self, false)
                table.insert(ret, data)
            end
        end
    end

    if #ret < self:GetSlotCount() then
        for i = #ret + 1, self:GetSlotCount() do
            local data = CityMobileUnitPetCellData.new(nil, self, false)
            table.insert(ret, data)
        end
    end
    
    ---@type TempFurnitureSlotUnlockTaskCfg
    local reasonGroup = nil
    for i = 1, ConfigRefer.CityConfig:V080TempFurnitureSlotUnlockTaskCfgLength() do
        local slotCfg = ConfigRefer.CityConfig:V080TempFurnitureSlotUnlockTaskCfg(i)
        if slotCfg:FurType() == self.cellTile:GetFurnitureType() then
            reasonGroup = slotCfg
            break
        end
    end


    if #ret < self:GetMaxCount() then
        for i = #ret + 1, self:GetMaxCount() do
            local reasonTaskId = nil
            if reasonGroup and reasonGroup:SlotTaskLength() >= i then
                reasonTaskId = reasonGroup:SlotTask(i)
            end
            local data = CityMobileUnitPetCellData.new(nil, self, true, reasonTaskId)
            table.insert(ret, data)
        end
    end

    return ret
end

function CityMobileUnitUIParameter:GenAssignPopupParam()
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
        self:GetSlotCount()
    )
    local title = I18N.Get("animal_work_popup_title")
    local features = self:NeedFeatureList()
    local param = CityPetAssignmentUIParameter.new(title, self.handle, features,
        Delegate.GetOrCreate(self, self.OnAssignmentCallback), true)
    return param
end

function CityMobileUnitUIParameter:OpenAssignPopupUI(rectTransform)
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        local itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(param.handle.allPetsId,self:NeedFeatureList()[1])
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
        -- self.city.petManager:GotoEarnPetEgg()
    end
end

function CityMobileUnitUIParameter:OnPetClick(petData, rectTransform)
    local workTimeFunc = nil
    if self.city.petManager.cityPetData[petData.id] then
        workTimeFunc = Delegate.GetOrCreate(self.city.petManager, self.city.petManager.GetRemainWorkDesc)
    end
    ---@type CityPetDetailsTipUIParameter
    local param = {
        id = petData.id,
        cfgId = petData.cfgId,
        Level = petData.level,
        removeFunc = nil,
        workTimeFunc = workTimeFunc,
        benefitFunc = nil,
        rectTransform = rectTransform,
    }
    g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, param)
    self.city.petManager:BITraceTipsOpen(self.cellTile:GetCell().singleId)
end

function CityMobileUnitUIParameter:PetFilterByFeature(petId)
    if self.detailCfg:AdditionProductsLength() == 0 then return true end
    
    local needFeature = self:NeedFeatureList(true)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet then
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if needFeature[petWorkCfg:Type()] then
                return true
            end
        end
    end
    return false
end

function CityMobileUnitUIParameter:PetSort(id1, id2)
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

    return id1 < id2
end

function CityMobileUnitUIParameter:SwitchCheck(id, flag)
    if self.city.petManager:IsPetInTroopWork(id) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_remove_tips"))
        return false
    end

    return true
end

---@param selectedPetsId table<number, boolean>
function CityMobileUnitUIParameter:OnAssignmentCallback(selectedPetsId, onAsyncAssignCallback)
    return self.city.petManager:TryAssignPetToWorkFurniture(self.cellTile:GetCell().singleId, selectedPetsId, function()
        if not self.mediator then return end
        self.mediator:UpdateUI()
    end, onAsyncAssignCallback)
end

---@param petCfg PetConfigCell
function CityMobileUnitUIParameter:GetWorkMap(petCfg)
    local ret = {}
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        ret[petWorkCfg:Type()] = petWorkCfg:Level()
    end
    return ret
end

function CityMobileUnitUIParameter:AutoBatchAssign(rectTransform)
    local allPets = ModuleRefer.PetModule._pets
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId) or {}
    local needFeature = self:NeedFeatureList(true)
    local suitablePets = {}
    for petId, pet in pairs(allPets) do
        --- 已经在本工位上的宠物和没有工作的宠物参与本次筛选
        if not self.city.petManager:IsPetInTroopWork(petId) and (petIdMap[petId] or self.city.petManager.cityPetData[petId] == nil) then
            local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
            for i = 1, petCfg:PetWorksLength() do
                local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
                if needFeature[petWorkCfg:Type()] then
                    table.insert(suitablePets, {id = petId, levelMap = self:GetWorkMap(petCfg), tag = petCfg:AssociatedTagInfo(), quality = petCfg:Quality(), score = 0})
                    break
                end
            end
        end
    end

    local bonusAssociatedCount = {}
    local bonusQualityCount = {}
    local bonusLevelSum = {}
    for i = 1, self.detailCfg:ConditionsLength() do
        local condition = self.detailCfg:Conditions(i)
        local conditionType = condition:EfficiencyConditionType()
        if conditionType == EfficiencyConditionType.AssociatedTagNumAbove then
            bonusAssociatedCount[condition:EfficiencyConditionLeftValue()] = condition:EfficiencyConditionRightValue()
        elseif conditionType == EfficiencyConditionType.PetQualityNumAbove then
            bonusQualityCount[condition:EfficiencyConditionLeftValue()] = condition:EfficiencyConditionRightValue()
        elseif conditionType == EfficiencyConditionType.PetLevelSumAbove then
            bonusLevelSum[condition:EfficiencyConditionLeftValue()] = condition:EfficiencyConditionRightValue()
        end
    end

    local basicNeed = {}
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        basicNeed[addition:PetWorkType()] = true
    end
    local slotCount = self.cellTile:GetCell():GetPetWorkSlotCount()
    local ret = {}
    while(#suitablePets > 0 and #ret < slotCount and (next(bonusAssociatedCount) or next(bonusQualityCount) or next(bonusLevelSum) or next(basicNeed))) do
        local maxScore, bestPet, index = 0, nil, 0
        for i, v in ipairs(suitablePets) do
            v.score = 0
            for workType, _ in pairs(basicNeed) do
                if v.levelMap[workType] then
                    v.score = v.score + 10000
                end
            end

            for tag, count in pairs(bonusAssociatedCount) do
                if v.tag == tag then
                    v.score = v.score + 1000
                end
            end

            for tag, count in pairs(bonusQualityCount) do
                if v.quality >= tag then
                    v.score = v.score + 1000
                end
            end

            for tag, count in pairs(bonusLevelSum) do
                if v.levelMap[tag] then
                    v.score = v.score + 100 * v.levelMap[tag]
                end
            end

            if maxScore == nil then
                maxScore = v.score
                bestPet = v
                index = i
            elseif v.score > maxScore then
                maxScore = v.score
                bestPet = v
                index = i
            end
        end

        if not bestPet then break end

        table.insert(ret, bestPet.id)
        table.remove(suitablePets, index)
         
        for workType, level in pairs(bestPet.levelMap) do
            if basicNeed[workType] then
                basicNeed[workType] = nil
            end

            if bonusLevelSum[workType] then
                bonusLevelSum[workType] = bonusLevelSum[workType] - level
                if bonusLevelSum[workType] <= 0 then
                    bonusLevelSum[workType] = nil
                end
            end
        end

        if bonusQualityCount[bestPet.quality] then
            bonusQualityCount[bestPet.quality] = bonusQualityCount[bestPet.quality] - 1
            if bonusQualityCount[bestPet.quality] <= 0 then
                bonusQualityCount[bestPet.quality] = nil
            end
        end

        if bonusAssociatedCount[bestPet.tag] then
            bonusAssociatedCount[bestPet.tag] = bonusAssociatedCount[bestPet.tag] - 1
            if bonusAssociatedCount[bestPet.tag] <= 0 then
                bonusAssociatedCount[bestPet.tag] = nil
            end
        end
    end

    if #ret == 0 then return end

    local param = CastleAddPetParameter.new()
    param.args.FurnitureId = self.cellTile:GetCell().singleId
    for _, petId in pairs(ret) do
        param.args.PetId:Add(petId)
    end
    param:SendOnceCallback(rectTransform, nil, true, function()
        if not self.mediator then return end
        self.mediator:UpdateUI()
    end)
end

function CityMobileUnitUIParameter:RequestDeletePet(petId, rectTransform)
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if not petIdMap then return end

    local find = false
    for id, flag in pairs(petIdMap) do
        if id == petId then
            find = true
            break
        end
    end

    if not find then return end

    self.city.petManager:RequestRemovePet(petId, self.cellTile:GetCell().singleId, rectTransform, function()
        if not self.mediator then return end
        self.mediator:UpdateUI()
    end)
end

function CityMobileUnitUIParameter:GetOfflineTimeStr()
    local maxSum = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)
    return I18N.GetWithParams("hotspring_desc_offline", TimeFormatter.TimerStringFormat(maxSum))
end

function CityMobileUnitUIParameter:IsLackBasicNeed()
    local basicNeed = {}
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        basicNeed[addition:PetWorkType()] = true
    end

    local petIdMap = self.handle.selectedPetsId
    if not petIdMap then
        return next(basicNeed) ~= nil
    end

    for petId, flag in pairs(petIdMap) do
        local pet = ModuleRefer.PetModule:GetPetByID(petId)
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            basicNeed[petWorkCfg:Type()] = nil
        end
    end

    return next(basicNeed) ~= nil
end

function CityMobileUnitUIParameter:GetLackBasicInfoTable()
    local basicNeed = {}
    local displayOutputLen = self.detailCfg:DisplayOutputLength()
    for i = 1, self.detailCfg:AdditionProductsLength() do
        local addition = self.detailCfg:AdditionProducts(i)
        if i <= displayOutputLen then
            basicNeed[addition:PetWorkType()] = self.detailCfg:DisplayOutput(i)
        else
            basicNeed[addition:PetWorkType()] = 0
        end
    end

    local petIdMap = self.handle.selectedPetsId
    if not petIdMap then
        return basicNeed
    end

    for petId, flag in pairs(petIdMap) do
        local pet = ModuleRefer.PetModule:GetPetByID(petId)
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            basicNeed[petWorkCfg:Type()] = nil
        end
    end

    return basicNeed
end

function CityMobileUnitUIParameter:GetLackBasicNeedText(fontSize)
    local basicNeed = self:GetLackBasicInfoTable()
    local featureContent = {}
    local outputContent = {}
    for feature, itemId in pairs(basicNeed) do
        local featureImg = CityPetUtils.GetFeatureIcon(feature)
        table.insert(featureContent, ("<quad name=%s size=%d width=1 />"):format(featureImg, fontSize))

        local itemCfg = ConfigRefer.Item:Find(itemId)
        if itemCfg then
            table.insert(outputContent, ("<quad name=%s size=%d width=1 />"):format(UIHelper.IconOrMissing(itemCfg and itemCfg:SubIcon()), fontSize))
        end
    end

    return I18N.GetWithParams("animal_work_popup_mention_tips", table.concat(featureContent, " "), table.concat(outputContent, " "))
end

return CityMobileUnitUIParameter