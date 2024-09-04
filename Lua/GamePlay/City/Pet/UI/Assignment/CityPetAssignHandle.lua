---@class CityPetAssignHandle
---@field new fun():CityPetAssignHandle
local CityPetAssignHandle = class("CityPetAssignHandle")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")

---@param onPetClick fun(id:CommonPetIconBaseData, rectTransform:UnityEngine.RectTransform)
function CityPetAssignHandle:ctor(onPetClick)
    ---@type City
    self.city = nil
    ---@type table<number, boolean>
    self.allPetsId = nil
    ---@type table<number, boolean>
    self.selectedPetsId = nil
    ---@type fun():boolean
    self.switchPreCheck = nil
    ---@type fun(number):boolean
    self.petFilter = nil
    ---@type fun(...:number)
    self.onSelectedChange = nil
    ---@type fun(id1:number, id2:number):boolean
    self.petSort = nil
    self.maxSelectCount = 0
    self.onPetClick = onPetClick
end

---@param city City
---@param selectedPetsId table<number, boolean>
---@param onPetClick fun(data:CommonPetIconBaseData, rectTransform:CS.UnityEngine.RectTransform)
---@param petFilter fun(number):boolean
---@param petSort fun(a:number, b:number):boolean
---@param switchPreCheck fun(id:number, oldStatus:boolean):boolean
---@param maxSelectCount number
function CityPetAssignHandle:Initialize(city, selectedPetsId, onPetClick, petFilter, petSort, switchPreCheck, maxSelectCount)
    self.city = city
    self.onPetClick = onPetClick
    self.petFilter = petFilter
    self.switchPreCheck = switchPreCheck
    self.maxSelectCount = maxSelectCount or 1
    
    self.allPetsId = {}
    self.selectedPetsId = {}
    self.originSelectedPetsId = {}
    for id, flag in pairs(selectedPetsId) do
        self.selectedPetsId[id] = flag
        self.originSelectedPetsId[id] = flag
    end

    local allPets = ModuleRefer.PetModule:GetPetList()
    for id, v in pairs(allPets) do
        if not self.petFilter or self.petFilter(id) then
            self.allPetsId[id] = true
        end
    end

    self.petSort = petSort
end

function CityPetAssignHandle:GetCurrentSelectCount()
    return table.nums(self.selectedPetsId)
end

function CityPetAssignHandle:SetSelectedChange(onSelectedChange)
    self.onSelectedChange = onSelectedChange
    return self
end

---@param onPetClick fun(data:CommonPetIconBaseData, rectTransform:CS.UnityEngine.RectTransform)
function CityPetAssignHandle:SetOnPetClick(onPetClick)
    self.onPetClick = onPetClick
    return self
end

function CityPetAssignHandle:Dispose()
    self.city = nil
    self.allPetsId = nil
    self.selectedPetsId = nil
    self.switchPreCheck = nil
    self.petFilter = nil
    self.onSelectedChange = nil
    self.maxSelectCount = nil
end

function CityPetAssignHandle:SwitchSelect(id)
    if not self.allPetsId[id] then
        g_Logger.ErrorChannel("CityPetAssignHandle", "Cant select pet that isn't in list")
        return false
    end

    if self.switchPreCheck and not self.switchPreCheck(id, self.selectedPetsId[id] == true) then
        return false
    end

    if self.selectedPetsId[id] then
        self.selectedPetsId[id] = nil
        if self.onSelectedChange then
            self.onSelectedChange(id)
        end
    else
        if self.maxSelectCount == 1 then
            local oldId, value = next(self.selectedPetsId)
            if oldId and oldId ~= id then
                self.selectedPetsId[oldId] = nil
                self.selectedPetsId[id] = true
                if self.onSelectedChange then
                    self.onSelectedChange(oldId, id)
                end
            elseif not oldId then
                self.selectedPetsId[id] = true
                if self.onSelectedChange then
                    self.onSelectedChange(id)
                end
            end
        else
            if self:GetCurrentSelectCount() >= self.maxSelectCount then
                return false
            end
            self.selectedPetsId[id] = true
            if self.onSelectedChange then
                self.onSelectedChange(id)
            end
        end
    end
    return true
end

---@return CommonPetIconBaseData
function CityPetAssignHandle:GetPetData(id, customClick)
    local pet = ModuleRefer.PetModule:GetPetByID(id)
    if pet == nil then return nil end

    ---@type CommonPetIconBaseData
    local petData = {
        id = id,
        cfgId = pet.ConfigId,
        level = pet.Level,
        rank = pet.RankLevel,
    }
    if not customClick then
        petData.onClick = Delegate.GetOrCreate(self, self.OnPetClick)
    else
        petData.onClick = customClick
    end
    return petData
end

function CityPetAssignHandle:GetPetName(petId)
    return ModuleRefer.PetModule:GetPetName(petId)
end

function CityPetAssignHandle:NeedShowBuff()
    return false
end

---@protected
---@return CityPetAssignPropertyData[]
function CityPetAssignHandle:GetRelativeAttrs(petId)
    return {}
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandle:GetBuffValueText(data)
    return string.Empty
end

function CityPetAssignHandle:GetWorkRelativeBuffData(petId)
    return self:GetRelativeAttrs(petId)
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandle:IsBetterThanCurrentPet(data)
    if next(self.originSelectedPetsId) == nil then return false end

    local current = nil
    for id, _ in pairs(self.originSelectedPetsId) do
        if id == data.petId then return false end

        local buffValues = self:GetWorkRelativeBuffData(id)
        for _, v in ipairs(buffValues) do
            if v.attrType == data.attrType then
                if current == nil then
                    current = v.value
                elseif v.value < current then
                    current = v.value
                end
            end
        end
    end
    return data.value > current
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandle:IsWorseThanCurrentPet(data)
    if next(self.originSelectedPetsId) == nil then return false end

    local current = nil
    for id, _ in pairs(self.originSelectedPetsId) do
        if id == data.petId then return false end

        local buffValues = self:GetWorkRelativeBuffData(id)
        for _, v in ipairs(buffValues) do
            if v.attrType == data.attrType then
                if current == nil then
                    current = v.value
                elseif v.value > current then
                    current = v.value
                end
            end
        end
    end
    return data.value < current
end

function CityPetAssignHandle:NeedShowPosition()
    return false
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandle:IsFree(data)
    return self:IsFreeById(data.id)
end

function CityPetAssignHandle:IsFreeById(petId)
    if self.city.petManager:IsPetInTroopWork(petId) then return false end

    local petData = self.city.petManager.cityPetData[petId]
    return petData == nil
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandle:GetWorkPositionName(data)
    if not self.city.petManager:IsDataReady() then return string.Empty end

    return self.city.petManager:GetWorkPosition(data.id)
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandle:IsLandNotFit(data)
    return false
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandle:GetBloodPercent(data)
    return self.city.petManager:GetHpPercent(data.id)
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandle:IsInTroop(data)
    return self.city.petManager:IsPetInTroopWork(data.id)
end

---@param data CommonPetIconBaseData
function CityPetAssignHandle:OnPetClick(data, rectTransform)
    if self.onPetClick then
        self.onPetClick(data, rectTransform)
    end
end

function CityPetAssignHandle:GetLandFactorPercent(data)
    return string.Empty
end

function CityPetAssignHandle:GetSuitableLandName(data)
    return string.Empty
end

---@param data CommonPetIconBaseData
function CityPetAssignHandle:ShowLandNotFitHint(data, rectTransform)
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = rectTransform
    tipParameter.text = I18N.GetWithParams("pet_tip_work_percent", self:GetLandFactorPercent(data).."%", self:GetSuitableLandName(data))
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

function CityPetAssignHandle:NeedShowExtraHint()
    return false
end

function CityPetAssignHandle:GetExtraHintText(fontSize)
    return string.Empty
end

function CityPetAssignHandle:NeedShowFeature()
    return false
end

function CityPetAssignHandle:GetPetWorkCfgs(petId)
    local ret = {}
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then return ret end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    if petCfg == nil then return ret end

    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg then
            table.insert(ret, petWorkCfg)
        end
    end
    return ret
end

---@param mediator CityPetAssignmentUIMediator
function CityPetAssignHandle:OnMediatorOpened(mediator)
    self.mediator = mediator
end

function CityPetAssignHandle:OnMediatorClosed(mediator)
    self.mediator = nil
end

---@vararg number
function CityPetAssignHandle:OnMultiSelectChange(...)
    ---override
end

return CityPetAssignHandle