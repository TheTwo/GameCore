local CityFurnitureDeployUIDataSrc = require("CityFurnitureDeployUIDataSrc")
---@class HeaterPetDeployUIDataSrc:CityFurnitureDeployUIDataSrc
---@field new fun():HeaterPetDeployUIDataSrc
local HeaterPetDeployUIDataSrc = class("HeaterPetDeployUIDataSrc", CityFurnitureDeployUIDataSrc)
local HeaterPetAssignHandle = require("HeaterPetAssignHandle")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local CityPetAssignmentUIParameter = require("CityPetAssignmentUIParameter")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local HeaterPetDeployPetCellData = require("HeaterPetDeployPetCellData")
local NumberFormatter = require("NumberFormatter")

---@param cellTile CityFurnitureTile
function HeaterPetDeployUIDataSrc:ctor(cellTile)
    self.cellTile = cellTile
    self.city = self.cellTile:GetCity()
    self.handle = HeaterPetAssignHandle.new(self)
    CityFurnitureDeployUIDataSrc.ctor(self, self.cellTile:GetName(), nil, self:GetNeedFeature())
end

function HeaterPetDeployUIDataSrc:GetNeedFeature()
    local ret = {}
    local typCfg = self.cellTile:GetFurnitureTypesCell()
    if typCfg then
        for i = 1, typCfg:PetWorkTypeLimitLength() do
            local feature = typCfg:PetWorkTypeLimit(i)
            if feature > 0 then
                table.insert(ret, feature)
            end
        end
    end
    return ret
end

function HeaterPetDeployUIDataSrc:GetLeftTitle()
    return I18N.Get("#烧水师傅")
end

function HeaterPetDeployUIDataSrc:GetRightTitle()
    return ("%d/%d"):format(self:SelectedPetCount(), self:MaxPetCount())
end

function HeaterPetDeployUIDataSrc:SelectedPetCount()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    return petIdMap and table.nums(petIdMap) or 0
end

function HeaterPetDeployUIDataSrc:MaxPetCount()
    return self.cellTile:GetCell():GetPetWorkSlotCount()
end

function HeaterPetDeployUIDataSrc:OnPetClick(petData, rectTransform)
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

function HeaterPetDeployUIDataSrc:OpenAssignmentUI()
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        self.city.petManager:GotoEarnPetEgg()
    end
end

---@private
---@return CityPetAssignmentUIParameter
function HeaterPetDeployUIDataSrc:GenAssignPopupParam()
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
        self:MaxPetCount()
    )
    local title = I18N.Get("animal_work_popup_title")
    local features = self:GetNeedFeature()
    local param = CityPetAssignmentUIParameter.new(title, self.handle, features,
        Delegate.GetOrCreate(self, self.OnAssignmentCallback), true)
    return param
end

---@private
function HeaterPetDeployUIDataSrc:PetFilterByFeature(id)
    local features = self:GetNeedFeature()
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

function HeaterPetDeployUIDataSrc:PetSort(id1, id2)
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

---@private
function HeaterPetDeployUIDataSrc:SwitchCheck(id, flag)
    if self.city.petManager:IsPetInTroopWork(id) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_remove_tips"))
        return false
    end
    
    return true
end

---@param selectedPetsId table<number, boolean>
function HeaterPetDeployUIDataSrc:OnAssignmentCallback(selectedPetsId, onAsyncAssignCallback)
    return self.city.petManager:TryAssignPetToWorkFurniture(self.cellTile:GetCell().singleId, selectedPetsId, nil, onAsyncAssignCallback)
end

function HeaterPetDeployUIDataSrc:RequestDeletePet(petId, rectTransform)
    self.city.petManager:RequestRemovePet(petId, self.cellTile:GetCell().singleId, rectTransform)
end

function HeaterPetDeployUIDataSrc:ShowBuffValue()
    return self:SelectedPetCount() > 0
end

function HeaterPetDeployUIDataSrc:GetBuffTitle()
    return I18N.Get("#当前增温器效果")
end

function HeaterPetDeployUIDataSrc:GetBuffData()
    local ret = {}
    local value = ModuleRefer.CastleAttrModule:GetValueWithFurniture(ConfigRefer.CityConfig:HeaterTimeDecreaseAttr(), self.cellTile:GetCell().singleId)
    if value > 0 then
        table.insert(ret, {icon = 'sp_city_icon_time_up', value = ("-%s"):format(NumberFormatter.Percent(value))})
    end
    return ret
end

function HeaterPetDeployUIDataSrc:GetTableViewCellData()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    local ret = {}
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            local petData = self.handle:GetPetData(petId, Delegate.GetOrCreate(self, self.OpenAssignmentUI))
            local cellData = HeaterPetDeployPetCellData.new(self, petData)
            table.insert(ret, cellData)
        end
    end

    local maxCount = self:MaxPetCount()
    for i = table.nums(petIdMap) + 1, maxCount do
        local cellData = HeaterPetDeployPetCellData.new(self, nil)
        table.insert(ret, cellData)
    end
    return ret
end

---@param data HeaterPetDeployPetCellData
function HeaterPetDeployUIDataSrc:IsLandNotFit(data)
    local features = self:GetNeedFeature()
    for _, feature in ipairs(features) do
        local petCfg = ConfigRefer.Pet:Find(data.petData.cfgId)
        local workLevel = 0
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if petWorkCfg:Type() == feature then
                workLevel = petWorkCfg:Level()
                break
            end
        end
        return self.param.city.petManager:IsLandNotFit(workLevel)
    end
    return false
end

return HeaterPetDeployUIDataSrc