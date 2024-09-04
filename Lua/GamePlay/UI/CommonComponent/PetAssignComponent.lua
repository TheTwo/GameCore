local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityPetUtils = require("CityPetUtils")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

local I18N = require("I18N")

---@class PetAssignComponent:BaseUIComponent
local PetAssignComponent = class('PetAssignComponent', BaseUIComponent)

---@class PetAssignComponentData
---@field assignedPets CommonPetIconBaseData[]
---@field slotCount number
---@field selectFunc fun(comp:PetAssignComponent)
---@field getBlood fun(petId:number):number
---@field isFullEfficiencyFunc boolean
---@field feature number

function PetAssignComponent:OnCreate()
    self._root = self:Transform("")
    ---@type PetAssignSingleComponent
    self._p_item_pet = self:LuaBaseComponent("p_item_pet")
    self._pool_pet = LuaReusedComponentPool.new(self._p_item_pet, self._root)
end

---@param data PetAssignComponentData
function PetAssignComponent:OnFeedData(data)
    self.data = data

    self._pool_pet:HideAll()
    for i = 1, data.slotCount do
        ---@type PetAssignSingleComponent
        local item = self._pool_pet:GetItem()
        local petIconBaseData = self.data.assignedPets[i]
        ---@type PetAssignSingleComponentData
        local data = {
            assignedPet = petIconBaseData,
            isFullEfficiency = petIconBaseData ~= nil and self.data.isFullEfficiencyFunc(petIconBaseData.id) or false,
            feature = self.data.feature,
            selectFunc = data.selectFunc,
            blood = petIconBaseData ~= nil and data.getBlood(petIconBaseData.id) or 1
        }
        item:FeedData(data)
    end
end

function PetAssignComponent:GetAssignedPetId()
    local ids = {}
    for _, petId in ipairs(self.data.assignedPets) do
        table.insert(ids, petId.id)
    end
    return ids
end

return PetAssignComponent