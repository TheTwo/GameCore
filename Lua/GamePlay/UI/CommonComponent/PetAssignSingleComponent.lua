local BaseUIComponent = require ('BaseUIComponent')
local CityPetUtils = require('CityPetUtils')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class PetAssignSingleComponent:BaseUIComponent
local PetAssignSingleComponent = class('PetAssignSingleComponent', BaseUIComponent)

---@class PetAssignSingleComponentData
---@field assignedPet CommonPetIconBaseData
---@field isFullEfficiency boolean
---@field feature number
---@field blood number
---@field selectFunc fun(comp:PetAssignSingleComponent)

function PetAssignSingleComponent:OnCreate()
    self._p_item_pet = self:StatusRecordParent("")
    ---@type CommonPetIconSmall
    self._p_pet = self:LuaObject("p_pet")
    self._p_progress_blood = self:Slider("p_progress_blood")
    self:Button("", Delegate.GetOrCreate(self, self.OnClickEmpty))

    self._p_btn_type = self:GameObject("p_btn_type")
    self._p_text_type = self:Text("p_text_type", "animal_work_interface_desc06")
    self._p_icon_type = self:Image("p_icon_type")
end

---@param data PetAssignSingleComponentData
function PetAssignSingleComponent:OnFeedData(data)
    self.data = data

    if self.data.assignedPet == nil then
        self._p_item_pet:ApplyStatusRecord(0)
        self._p_btn_type:SetActive(self.data.feature ~= nil)
        if self.data.feature then
            local icon = CityPetUtils.GetFeatureIcon(self.data.feature)
            g_Game.SpriteManager:LoadSprite(icon, self._p_icon_type)
        end
    else
        if self.data.isFullEfficiency then
            self._p_item_pet:ApplyStatusRecord(1)
        else
            self._p_item_pet:ApplyStatusRecord(2)
        end
        self._p_pet:FeedData(self.data.assignedPet)
    end
    self._p_progress_blood.value = self.data.blood
end

function PetAssignSingleComponent:OnClickEmpty()
    if self.data.selectFunc then
        self.data.selectFunc(self._p_item_pet.transform, self)
    end
end

return PetAssignSingleComponent