local ModuleRefer = require("ModuleRefer")
---@class PetListSorters
local PetListSorters = {}

---@class PetSortData
---@field fixedSkillLevel number
---@field style number
---@field power number
---@field id number
---@field cfgId number
---@field rarity number
---@field rank number
---@field level number
---@field templateIds number[]
---@field heroBind number
---@field isInTroop boolean

---@param a number
---@param b number
function PetListSorters.SortByPower(a, b)
    local dataA = PetListSorters.ConstructSortData(a)
    local dataB = PetListSorters.ConstructSortData(b)
    if (dataA.isInTroop ~= dataB.isInTroop) then
        return dataA.isInTroop
    elseif (dataA.power ~= dataB.power) then
        return dataA.power > dataB.power
    elseif (dataA.rarity ~= dataB.rarity) then
        return dataA.rarity > dataB.rarity
    elseif (dataA.level ~= dataB.level) then
        return dataA.level > dataB.level
    elseif (dataA.rank ~= dataB.rank) then
        return dataA.rank > dataB.rank
    else
        return dataA.cfgId < dataB.cfgId
    end
end


---@param id number
---@return PetSortData
function PetListSorters.ConstructSortData(id)
    local petData = ModuleRefer.PetModule:GetPetByID(id)
    local cfg = ModuleRefer.PetModule:GetPetCfg(petData.ConfigId)
    ---@type PetSortData
    local data = {}
    data.id = id
    data.cfgId = petData.ConfigId
    data.rarity = cfg:Rarity()
    data.level = petData.Level
    data.rank = ModuleRefer.PetModule:GetStarLevel(id)
    data.templateIds = petData.TemplateIds
    data.fixedSkillLevel = ModuleRefer.PetModule:GetSkillLevel(id, true)
    data.heroBind = ModuleRefer.PetModule:GetPetLinkHero(id)
    data.isInTroop = ModuleRefer.TroopModule:GetPetBelongedTroopIndex(id) ~= 0
    data.power = ModuleRefer.PetModule:GetPetPower(id)

    return data
end

return PetListSorters