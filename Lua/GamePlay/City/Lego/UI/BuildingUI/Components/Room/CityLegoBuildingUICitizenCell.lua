local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local HeroUIUtilities = require("HeroUIUtilities")

---@class CityLegoBuildingUICitizenCell:BaseTableViewProCell
local CityLegoBuildingUICitizenCell = class('CityLegoBuildingUICitizenCell', BaseTableViewProCell)

function CityLegoBuildingUICitizenCell:OnCreate()
    self._base_furniture = self:GameObject("base_furniture")
    self._p_img_furniture = self:Image("p_img_furniture")

    self._p_base_resident_0 = self:GameObject("p_base_resident_0")
    self._p_base_pet_0 = self:GameObject("p_base_pet_0")

    self._p_btn_resident_add = self:Button("p_btn_resident_add", Delegate.GetOrCreate(self, self.OnClickAddResident))

    self._p_resident = self:GameObject("p_resident")
    self._p_base_resident = self:Image("p_base_resident")
    ---@type CommonCitizenCellComponent
    self._p_item_resident = self:LuaObject("p_item_resident")
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickRemoveResident))

    self._p_pet = self:GameObject("p_pet")
    self._p_base_pet = self:Image("p_base_pet")
    ---@type CommonPetIconBaseData
    self._child_card_pet_s = self:LuaObject("child_card_pet_s")
end

---@param data {citizenData:CityCitizenData, isEmpty:boolean, onAdd:fun(), onRemove:fun()}
function CityLegoBuildingUICitizenCell:OnFeedData(data)
    self.data = data

    self._base_furniture:SetActive(false)
    
    --- 这版本不考虑宠物在这里显示
    self._p_base_resident_0:SetActive(not data.isEmpty)
    self._p_base_pet_0:SetActive(false)

    self._p_btn_resident_add:SetVisible(data.isEmpty)
    self._p_resident:SetActive(not data.isEmpty)

    self._p_pet:SetActive(false)

    if data.citizenData then
        local quality = data.citizenData:GetCitizenQuality()
        local path = HeroUIUtilities.GetQualitySpriteID(quality)
        self:LoadSprite(path, self._p_base_resident)

        ---@type CommonCitizenCellComponentParameter
        local parameter = {}
        parameter.citizenData = data.citizenData
        self._p_item_resident:FeedData(parameter)
    end
end

function CityLegoBuildingUICitizenCell:OnClickAddResident()
    if self.data.onAdd then
        self.data.onAdd()
    end
end

function CityLegoBuildingUICitizenCell:OnClickRemoveResident()
    if self.data.onRemove then
        self.data.onRemove(self.data.citizenData)
    end
end

return CityLegoBuildingUICitizenCell