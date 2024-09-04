local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")

---@class CityMobileUnitPetCell:BaseTableViewProCell
local CityMobileUnitPetCell = class('CityMobileUnitPetCell', BaseTableViewProCell)

function CityMobileUnitPetCell:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_btn_pet = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnClick))

    ---@type CommonPetIconSmall
    self._p_pet = self:LuaObject("p_pet")
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickDelete))
    self._p_btn_hint = self:GameObject("p_btn_hint")
    self._p_btn_hint:SetActive(false)

    self._p_progress_blood = self:Slider("p_progress_blood")
end

---@param data CityMobileUnitPetCellData
function CityMobileUnitPetCell:OnFeedData(data)
    self.data = data
    self._statusRecord:ApplyStatusRecord(self.data:GetStatus())
    if self.data.petData ~= nil then
        self._p_pet:FeedData(self.data.petData)

        local pet = ModuleRefer.PetModule:GetPetByID(self.data.petData.id)
        local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()]
        if maxHp then
            local petDatum = self.data.param.city.petManager.cityPetData[self.data.petData.id]
            local curHp = petDatum.hp
            self._p_progress_blood.value = curHp / maxHp
        end
    end
end

function CityMobileUnitPetCell:OnClick()
    if self.data:GetStatus() == 0 then
        if self.data.lockTaskId ~= nil and self.data.lockTaskId > 0 then
            local content = ModuleRefer.QuestModule:GetTaskDesc(self.data.lockTaskId)
            ModuleRefer.ToastModule:AddSimpleToast(content)
        end
        return
    end
    return self.data.param:OpenAssignPopupUI(self._p_btn_pet.transform)
end

function CityMobileUnitPetCell:OnClickDelete()
    return self.data.param:RequestDeletePet(self.data.petData.id, self._p_btn_delete.transform)
end

return CityMobileUnitPetCell