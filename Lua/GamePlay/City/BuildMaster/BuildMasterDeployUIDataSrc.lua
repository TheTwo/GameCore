local CityFurnitureDeployUIDataSrc = require("CityFurnitureDeployUIDataSrc")
---@class BuildMasterDeployUIDataSrc:CityFurnitureDeployUIDataSrc
---@field new fun():BuildMasterDeployUIDataSrc
local BuildMasterDeployUIDataSrc = class("BuildMasterDeployUIDataSrc", CityFurnitureDeployUIDataSrc)
local BuildMasterPetAssignHandle = require("BuildMasterPetAssignHandle")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CityPetAssignmentUIParameter = require("CityPetAssignmentUIParameter")
local CastleAddPetParameter = require("CastleAddPetParameter")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local CastleDelPetParameter = require("CastleDelPetParameter")
local BuildMasterDeployPetCellData = require("BuildMasterDeployPetCellData")

---@param cellTile CityFurnitureTile
function BuildMasterDeployUIDataSrc:ctor(cellTile)
    self.cellTile = cellTile
    self.city = self.cellTile:GetCity()
    self.handle = BuildMasterPetAssignHandle.new(self, Delegate.GetOrCreate(self, self.OnPetClick))
    CityFurnitureDeployUIDataSrc.ctor(self, self.cellTile:GetName(), nil, self:GetNeedFeature())
end

function BuildMasterDeployUIDataSrc:GetMainHint()
    return I18N.Get("animal_work_fur_desc_01")
end

function BuildMasterDeployUIDataSrc:GetNeedFeature()
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

function BuildMasterDeployUIDataSrc:GetLeftTitle()
    return I18N.Get("pet_tip_btn_remove")
end

function BuildMasterDeployUIDataSrc:GetRightTitle()
    return ("%d/%d"):format(self:SelectedPetCount(), self:MaxPetCount())
end

function BuildMasterDeployUIDataSrc:SelectedPetCount()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    return petIdMap and table.nums(petIdMap) or 0
end

function BuildMasterDeployUIDataSrc:MaxPetCount()
    return self.cellTile:GetCell():GetPetWorkSlotCount()
end

function BuildMasterDeployUIDataSrc:OnPetClick(petData, rectTransform)
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

function BuildMasterDeployUIDataSrc:GetBenefitIconAndDesc(petId)
    local time = 0
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg then
            time = time + (petWorkCfg:BuildingReduceTime() * self.city.petManager:GetLandFactor(petWorkCfg:Level()))
        end
    end

    return "sp_city_icon_time_up", ("-%s"):format(TimeFormatter.TimerStringFormat(time, true))
end

function BuildMasterDeployUIDataSrc:OpenAssignmentUI()
    local param = self:GenAssignPopupParam()
    if next(param.handle.allPetsId) then
        g_Game.UIManager:Open(UIMediatorNames.CityPetAssignmentUIMediator, param)
    else
        local itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(param.handle.allPetsId,self:GetNeedFeature()[1])
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
        -- self.city.petManager:GotoEarnPetEgg()
    end
end

---@private
---@return CityPetAssignmentUIParameter
function BuildMasterDeployUIDataSrc:GenAssignPopupParam()
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
function BuildMasterDeployUIDataSrc:PetFilterByFeature(id)
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

function BuildMasterDeployUIDataSrc:PetSort(id1, id2)
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

    local decrease1 = self.city.petManager:GetDecreaseBuildTime(id1)
    local decrease2 = self.city.petManager:GetDecreaseBuildTime(id2)
    return decrease1 > decrease2
end

---@private
function BuildMasterDeployUIDataSrc:SwitchCheck(id, flag)
    if self.city.petManager:IsPetInTroopWork(id) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_remove_tips"))
        return false
    end

    return true
end

---@param selectedPetsId table<number, boolean>
function BuildMasterDeployUIDataSrc:OnAssignmentCallback(selectedPetsId, onAsyncAssignCallback)
    return self.city.petManager:TryAssignPetToWorkFurniture(self.cellTile:GetCell().singleId, selectedPetsId, nil, onAsyncAssignCallback)
end

function BuildMasterDeployUIDataSrc:RequestDeletePet(petId, rectTransform)
    self.city.petManager:RequestRemovePet(petId, self.cellTile:GetCell().singleId, rectTransform)
end

function BuildMasterDeployUIDataSrc:ShowBuffValue()
    return true
end

function BuildMasterDeployUIDataSrc:GetBuffTitle()
    return I18N.Get("total_reduce_time_tips")
end

function BuildMasterDeployUIDataSrc:GetBuffData()
    local castle = self.city:GetCastle()
    local ret = {}
    if castle.GlobalData.BuildingReduceTime > 0 then
        table.insert(ret, {icon = 'sp_city_icon_time_up', value = ("-%s"):format(TimeFormatter.TimerStringFormat(castle.GlobalData.BuildingReduceTime))})
    else
        table.insert(ret, {icon = 'sp_city_icon_time_up', value = ("-0s")})
    end
    return ret
end

function BuildMasterDeployUIDataSrc:GetTableViewCellData()
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(self.cellTile:GetCell().singleId)
    local ret = {}
    if petIdMap then
        for petId, _ in pairs(petIdMap) do
            local petData = self.handle:GetPetData(petId, Delegate.GetOrCreate(self, self.OpenAssignmentUI))
            local cellData = BuildMasterDeployPetCellData.new(self, petData, false)
            table.insert(ret, cellData)
        end
    end

    local slotCount = self:MaxPetCount()
    for i = table.nums(petIdMap) + 1, slotCount do
        local cellData = BuildMasterDeployPetCellData.new(self, nil, false)
        table.insert(ret, cellData)
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

    local maxCount = ConfigRefer.CityConfig:BuildMasterMaxSlot()
    for i = slotCount + 1, maxCount do
        local reasonTaskId = nil
        if reasonGroup and reasonGroup:SlotTaskLength() >= i then
            reasonTaskId = reasonGroup:SlotTask(i)
        end
        local cellData = BuildMasterDeployPetCellData.new(self, nil, true, reasonTaskId)
        table.insert(ret, cellData)
    end

    return ret
end

---@param mediator CityFurnitureDeployUIMediator
function BuildMasterDeployUIDataSrc:OnMediatorOpened(mediator)
    self.mediator = mediator
    g_Game.ServiceManager:AddResponseCallback(CastleAddPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChanged))
    g_Game.ServiceManager:AddResponseCallback(CastleDelPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChanged))
end

---@param mediator CityFurnitureDeployUIMediator
function BuildMasterDeployUIDataSrc:OnMediatorClosed(mediator)
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChanged))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDelPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChanged))
    self.mediator = nil
end

function BuildMasterDeployUIDataSrc:OnPetChanged(isSuccess, reply, rpc)
    if not isSuccess then return end
    if not self.mediator then return end
    self.mediator:UpdateUI()
end

return BuildMasterDeployUIDataSrc