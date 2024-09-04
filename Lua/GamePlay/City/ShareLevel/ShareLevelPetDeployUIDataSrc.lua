local CityFurnitureDeployUIDataSrc = require("CityFurnitureDeployUIDataSrc")
---@class ShareLevelPetDeployUIDataSrc:CityFurnitureDeployUIDataSrc
---@field new fun():ShareLevelPetDeployUIDataSrc
local ShareLevelPetDeployUIDataSrc = class("ShareLevelPetDeployUIDataSrc", CityFurnitureDeployUIDataSrc)
local ModuleRefer = require("ModuleRefer")
local ShareLevelPetDeployPetCellData = require("ShareLevelPetDeployPetCellData")
local I18N = require("I18N")

---@param cellTile CityFurnitureTile
function ShareLevelPetDeployUIDataSrc:ctor(cellTile)
    self.cellTile = cellTile
    self.city = cellTile:GetCity()
    CityFurnitureDeployUIDataSrc.ctor(self, self.cellTile:GetName())
end

function ShareLevelPetDeployUIDataSrc:GetMainHint()
    ---@type ShareLevelPetDeployPetCellData[]
    local ret = {}
    for i, petId in ipairs(self.petIds) do
        local data = ShareLevelPetDeployPetCellData.new(petId)
        table.insert(ret, data)
    end

    table.sort(ret, function(l, r)
        if l.petData.Level ~= r.petData.Level then
            return l.petData.Level < r.petData.Level
        end
        return l.petId < r.petId
    end)

    if #ret > 0 then
        return I18N.GetWithParams("animal_work_fur_desc_03", ret[1].petData.Level, ModuleRefer.PetModule:GetPetName(ret[1].petId))
    else
        return I18N.GetWithParams("animal_work_fur_desc_03", 0, "unknown")
    end
end

---@return string
function ShareLevelPetDeployUIDataSrc:GetLeftTitle()
    return I18N.Get("bw_newcircle_info_3")
end

---@return CityFurnitureDeployCellData[]
function ShareLevelPetDeployUIDataSrc:GetTableViewCellData()
    ---@type ShareLevelPetDeployPetCellData[]
    local ret = {}
    for i, petId in ipairs(self.petIds) do
        local data = ShareLevelPetDeployPetCellData.new(petId)
        table.insert(ret, data)
    end

    table.sort(ret, function(l, r)
        if l.petData.Level ~= r.petData.Level then
            return l.petData.Level > r.petData.Level
        end
        return l.petId > r.petId
    end)
    
    if #ret > 0 then
        ret[#ret].shareTarget = true
    end

    return ret
end

---@param mediator CityFurnitureDeployUIMediator
function ShareLevelPetDeployUIDataSrc:OnMediatorOpened(mediator)
    self.mediator = mediator
    self.level, self.petIds = ModuleRefer.PetModule:GetHighestLevelPets()
end

---@param mediator CityFurnitureDeployUIMediator
function ShareLevelPetDeployUIDataSrc:OnMediatorClosed(mediator)
    self.mediator = nil
    self.level = nil
    self.petIds = nil
end

return ShareLevelPetDeployUIDataSrc