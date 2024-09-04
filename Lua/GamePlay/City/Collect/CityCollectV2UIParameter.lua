local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityCollectV2UIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityCollectV2UIParameter
local CityCollectV2UIParameter = class("CityCollectV2UIParameter", CityCommonRightPopupUIParameter)
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local CityPetAssignmentUIParameter = require("CityPetAssignmentUIParameter")
local CityPetAssignHandleCollectV2 = require("CityPetAssignHandleCollectV2")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local CityWorkType = require("CityWorkType")
local CityPetUtils = require("CityPetUtils")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local TimeFormatter = require("TimeFormatter")
local NumberFormatter = require("NumberFormatter")
local CityAttrType = require("CityAttrType")
local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")

---@param cellTile CityFurnitureTile
---@param city City
---@param furnitureId number @家具id
function CityCollectV2UIParameter:ctor(cellTile)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.city = cellTile:GetCity()
    self.handle = CityPetAssignHandleCollectV2.new(self, Delegate.GetOrCreate(self, self.OnPetClick))
    self:UpdateWorkData()
end

function CityCollectV2UIParameter:UpdateWorkData()
    self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.ResourceProduce] or 0
    ---@type CityWorkData
    self.workData = self.city.cityWorkManager:GetWorkData(self.workId)

    local furLvCfg = self.cellTile:GetCell().furnitureCell
    for i = 1, furLvCfg:WorkListLength() do
        local workCfgId = furLvCfg:WorkList(i)
        local workCfg = ConfigRefer.CityWork:Find(workCfgId)
        if workCfg and workCfg:Type() == CityWorkType.ResourceProduce then
            self.workCfg = workCfg
            break
        end
    end

    if self.workCfg == nil then
        g_Logger.ErrorChannel("CityCollectV2UIParameter", "资源生产界面数据异常")
    end
end

---@return string @工作名
function CityCollectV2UIParameter:GetWorkName()
    if self.workCfg then
        return I18N.Get(self.workCfg:Name())
    end
    return string.Empty
end

---@return number[] @所需特性列表
function CityCollectV2UIParameter:NeedFeatureList()
    if self.workCfg:RequireWorkerType() ~= 0 then
        return {self.workCfg:RequireWorkerType()}
    end
    return nil
end

function CityCollectV2UIParameter:GetCastleFurniture()
    return self.cellTile:GetCastleFurniture()
end

function CityCollectV2UIParameter:GetResourceProduceInfo()
    local castleFurniture = self:GetCastleFurniture()
    if castleFurniture then
        return castleFurniture.ResourceProduceInfo
    end
    return nil
end

---@return string 获取产物图标
function CityCollectV2UIParameter:GetOutputIcon()
    local resourceProduceInfo = self:GetResourceProduceInfo()
    if resourceProduceInfo and resourceProduceInfo.ResourceType > 0 then
        local itemCfg = ConfigRefer.Item:Find(resourceProduceInfo.ResourceType)
        return itemCfg:Icon()
    end
    if self.workCfg then
        local workSubCfg = ConfigRefer.CityWorkProduceResource:Find(self.workCfg:ResProduceCfg())
        if workSubCfg then
            local itemCfg = ConfigRefer.Item:Find(workSubCfg:ResType())
            if itemCfg then
                return itemCfg:Icon()
            end
        end
    end
    return string.Empty
end

---@return string 获取产物描述
function CityCollectV2UIParameter:GetWorkStatDesc()
    if self:IsFull() then
        return I18N.Get("animal_work_res_status11")
    elseif not self:IsUndergoing() then
        return I18N.Get("animal_work_res_status")
    else
        local workSubCfg = ConfigRefer.CityWorkProduceResource:Find(self.workCfg:ResProduceCfg())
        return I18N.Get(workSubCfg:ProcessingHint())
    end
end

---@return number 当IsUndergoing时返回产物数量
function CityCollectV2UIParameter:GetOutputNumber()
    if self:IsUndergoing() then
        local info = self:GetResourceProduceInfo()
        if info then
            return math.floor(info.CurCount)
        end
    end
    return 0
end

---@return PetAssignComponentData
function CityCollectV2UIParameter:GetPetAssignData()
    ---@type CommonPetIconBaseData[]
    local assignedPets = {}

    local petAssignedMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petAssignedMap then
        for petId, _ in pairs(petAssignedMap) do
            table.insert(assignedPets, self.handle:GetPetData(petId, Delegate.GetOrCreate(self, self.OpenAssignPopupUI)))
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

function CityCollectV2UIParameter:IsAssignedPetFullEfficiency(petId)
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

---@param uiMediator CityCollectV2UIMediator
function CityCollectV2UIParameter:OnUIMediatorOpened(uiMediator)
    self.timer = uiMediator:StartFrameTicker(Delegate.GetOrCreate(self, self.OnTick), 1, -1, false)
    ---TODO:监听上宠物的消息, 把宠物选择界面再关一次
end

---@param uiMediator CityCollectV2UIMediator
function CityCollectV2UIParameter:OnUIMediatorClosed(uiMediator)
    uiMediator:StopTimer(self.timer) 
end

function CityCollectV2UIParameter:OnTick()
    
end

function CityCollectV2UIParameter:GetSingleOutputProgress()
    if self:IsUndergoing() then
        return CityWorkProduceWdsHelper.GetProduceSingleProgress(self.cellTile:GetCastleFurniture(), self.city)
    end
    return 0
end

function CityCollectV2UIParameter:IsAssignedPet()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    return petIdMap ~= nil and next(petIdMap) ~= nil
end

---@return CityCollectV2PropertyCellData[]
function CityCollectV2UIParameter:GetProperties()
    local ret = {}
    local produceCfg = ConfigRefer.CityWorkProduceResource:Find(self.workCfg:ResProduceCfg())
    if produceCfg then
        local durationAttr = ModuleRefer.CastleAttrModule:GetValueWithFurniture(produceCfg:DurationAttr(), self.cellTile:GetCell().singleId)
        table.insert(ret, {
            name = I18N.Get("animal_work_attr01"),
            value = TimeFormatter.TimerStringFormat(durationAttr)
        })
        local outputSpeedAttr = ModuleRefer.CastleAttrModule:GetValueWithFurniture(produceCfg:OutputSpeedAttr(), self.cellTile:GetCell().singleId)
        table.insert(ret, {
            name = I18N.Get("animal_work_attr02"),
            value = ("%s/h"):format(NumberFormatter.Normal(outputSpeedAttr))
        })
        
        if self:IsAssignedPet() then
            local plusValue = 0
            local param1 = self.workCfg:CustomParam1()
            local param2 = self.workCfg:CustomParam2()
            local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
            for petId, _ in pairs(petIdMap) do
                local petDatum = self.city.petManager.cityPetData[petId]
                local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
                local workLevel = petDatum:GetWorkLevel(self.workCfg:RequireWorkerType())
                local levelFactor = self.city.petManager:GetLandFactor(workLevel)
                local hungry = petDatum.hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
                plusValue = plusValue + ((param1 + workSpeed) / param2 * outputSpeedAttr * levelFactor * hungry)
            end

            table.insert(ret, {
                name = I18N.Get("animal_work_attr03"),
                value = ("%s/h"):format(NumberFormatter.Normal(plusValue)),
                fromPet = true,
            })
        end
    end
    return ret
end

function CityCollectV2UIParameter:GetHintText()
    if self:IsFull() then
        return I18N.Get("animal_work_res_status12")
    elseif not self:IsUndergoing() then
        return I18N.GetWithParams("animal_work_res_status13", CityPetUtils.GetFeatureName(self.workCfg:RequireWorkerType()))
    elseif self:IsCurrentPetLowEfficiency() then
        local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
        local percent = nil
        local landName = nil
        if petIdMap then
            for petId, _ in pairs(petIdMap) do
                local petDatum = self.city.petManager.cityPetData[petId]
                local workLevel = petDatum:GetWorkLevel(self.workCfg:RequireWorkerType())
                if self.city.petManager:IsLandNotFit(workLevel) then
                    percent = NumberFormatter.Percent(self.city.petManager:GetLandFactor(workLevel) / self.city.petManager:GetMaxLandFactor(workLevel)).."%"
                    landName = self.city.petManager:GetBestLandName(workLevel)
                end
            end
        end

        if percent and landName then
            return I18N.GetWithParams("pet_tip_work_percent", percent, landName)
        else
            return string.Empty
        end
    else
        return string.Empty
    end
end

function CityCollectV2UIParameter:IsUndergoing()
    local info = self:GetResourceProduceInfo()
    if info then
        local startTime = info.StartTime.ServerSecond
        if startTime <= 0 then
            return false
        end
        local duration = info.Duration.ServerSecond
        if duration <= 0 then
            return false
        end
        local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        return now - startTime < duration
    end
    return false
end

---@param rectTransform CS.UnityEngine.RectTransform
function CityCollectV2UIParameter:RequestClaim(rectTransform)
    local param = CastleGetProcessOutputParameter.new()
    param.args.FurnitureId = self.cellTile:GetCell().singleId
    param.args.WorkCfgId = self.workCfg:Id()
    param:Send(rectTransform)
end

---@param rectTransform CS.UnityEngine.RectTransform
function CityCollectV2UIParameter:OpenAssignPopupUI(rectTransform)
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        local itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(param.handle.allPetsId,self:NeedFeatureList()[1])
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
        -- self.city.petManager:GotoEarnPetEgg()
    end
end

---@private
---@return number|nil @上一次在这个家具上工作的宠物id
function CityCollectV2UIParameter:GetLastPetId()
    return nil
end

---@private
---@param petData CommonPetIconBaseData
function CityCollectV2UIParameter:OnPetClick(petData, rectTransform)
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

---@return string, string @icon, benefitDesc
function CityCollectV2UIParameter:GetBenefitIconAndDesc(petId)
    local produceCfg = ConfigRefer.CityWorkProduceResource:Find(self.workCfg:ResProduceCfg())
    local outputSpeedAttr = ModuleRefer.CastleAttrModule:GetValueWithFurniture(produceCfg:OutputSpeedAttr(), self.cellTile:GetCell().singleId)
    local param1 = self.workCfg:CustomParam1()
    local param2 = self.workCfg:CustomParam2()
    local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
    local workLevel = self.city.petManager:GetWorkLevel(petId, self.workCfg:RequireWorkerType())
    local levelFactor = self.city.petManager:GetLandFactor(workLevel)
    local hp = self.city.petManager:GetHp(petId)
    local hungry = hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
    local value = (param1 + workSpeed) / param2 * outputSpeedAttr * levelFactor * hungry
    local output = ConfigRefer.Item:Find(produceCfg:ResType())
    return output:Icon(), NumberFormatter.WithSign(value) .. "/h"
end

---@private
function CityCollectV2UIParameter:OnPetSelect(rectTransform, petAssignComponent)
    self:OpenAssignPopupUI(rectTransform)
end

---@private
---@return CityPetAssignmentUIParameter
function CityCollectV2UIParameter:GenAssignPopupParam()
    local selectedPetsId = {}
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        for id, _ in pairs(petIdMap) do
            selectedPetsId[id] = true
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
function CityCollectV2UIParameter:PetFilterByFeature(id)
    local features = self:NeedFeatureList()
    if features == nil or #features == 0 then
        return true
    end

    local map = {}
    for _, feature in ipairs(features) do
        map[feature] = true
    end

    local petTypeFilter = {}
    if self.workCfg:PetTypeFilterLength() > 0 then
        for i = 1, self.workCfg:PetTypeFilterLength() do
            petTypeFilter[self.workCfg:PetTypeFilter(i)] = true
        end
    end
        

    local pet = ModuleRefer.PetModule:GetPetByID(id)
    if pet then
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWork = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if petWork and map[petWork:Type()] then
                if next(petTypeFilter) then
                    if petTypeFilter[petCfg:Type()] then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end

function CityCollectV2UIParameter:PetSort(id1, id2)
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
function CityCollectV2UIParameter:SwitchCheck(id, flag)
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
function CityCollectV2UIParameter:OnAssignmentCallback(selectedPetsId, onAsyncAssignCallback)
    return self.city.petManager:TryAssignPetToWorkFurniture(self.cellTile:GetCell().singleId, selectedPetsId, Delegate.GetOrCreate(self, self.UpdateWorkData), onAsyncAssignCallback)
end

---@private
---@return boolean @是否生产到达最大存储时间
function CityCollectV2UIParameter:IsFull()
    local info = self:GetResourceProduceInfo()
    if info and info.ResourceType ~= 0 then
        local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local startTime = info.StartTime.ServerSecond
        local duration = info.Duration.ServerSecond
        return now - startTime >= duration
    end
    return false
end

---@private
---@return boolean @是否当前宠物生产效率未发挥最大水平
function CityCollectV2UIParameter:IsCurrentPetLowEfficiency()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            local petDatum = self.city.petManager.cityPetData[petId]
            local workLevel = petDatum:GetWorkLevel(self.workCfg:RequireWorkerType())
            if self.city.petManager:IsLandNotFit(workLevel) then
                return true
            end
        end
    end

    return false
end

return CityCollectV2UIParameter