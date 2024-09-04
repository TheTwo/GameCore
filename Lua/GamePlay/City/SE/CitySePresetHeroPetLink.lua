
local CitySeExplorerPetsLogic = require("CitySeExplorerPetsLogic")

---@alias LinkPairContent {h2p:table<number, number>, h2Index:table<number, number>, p2h:table<number, number>, pendingPet:{petId:number, heroEntityId:number}[], createdPets:table<number, CityUnitExplorerPet>, petsGroupLogic:CitySeExplorerPetsLogic}

---@class CitySePresetHeroPetLink
---@field new fun(mgr:CitySeManager):CitySePresetHeroPetLink
local CitySePresetHeroPetLink = sealedClass("CitySePresetHeroPetLink")

---@param mgr CitySePresetHeroPetLink
function CitySePresetHeroPetLink:ctor(mgr)
    ---@type CitySeManager
    self._mgr = mgr
    ---@type table<number, LinkPairContent>
    self._presetDic = {}
end

---@return LinkPairContent
function CitySePresetHeroPetLink:LinkPairContent(preset)
    ---@type LinkPairContent
    local ret = {}
    ret.h2p = {}
    ret.h2Index = {}
    ret.p2h = {}
    ret.pendingPet = {}
    ret.createdPets = {}
    ---@type CitySeExplorerPetsLogic
    ret.petsGroupLogic = CitySeExplorerPetsLogic.new(self._mgr, preset)
    return ret
end

function CitySePresetHeroPetLink:ResetAllHeroAndPetLink()
    for _, link in pairs(self._presetDic) do
        link.h2p = {}
        link.p2h = {}
        link.h2Index = {}
    end
end

function CitySePresetHeroPetLink:AddHeroPetLink(preset, heroId, petId, indexInList)
    local link = self._presetDic[preset]
    if not link then
        link = self:LinkPairContent(preset)
        self._presetDic[preset] = link
    end
    link.h2p[heroId] = petId
    link.h2Index[heroId] = indexInList
    link.p2h[petId] = heroId
end

function CitySePresetHeroPetLink:FilterNoLinkHeroPendingCreatePet()
    for _, link in pairs(self._presetDic) do
        for index = #link.pendingPet, 1, -1 do
            local pending =  link.pendingPet[index]
            if not link.p2h[pending.petId] then
                table.remove(link.pendingPet, index)
            end
        end
    end
end

---@param dbPet2HeroEid table<number, number>
function CitySePresetHeroPetLink:FilterNoHeroCreatedPet(dbPet2HeroEid)
    for _, link in pairs(self._presetDic) do
        for petId, unit in pairs(link.createdPets) do
            if not link.p2h[petId] or not dbPet2HeroEid[petId] then
                link.createdPets[petId] = nil
                link.petsGroupLogic:RemovePet(unit)
                unit:Dispose()
            end
        end
    end
end

---@param dbPet2HeroEid table<number, number>
function CitySePresetHeroPetLink:FilterAddToPendingCreatePet(dbPet2HeroEid)
    for preset, link in pairs(self._presetDic) do
        for petId, _ in pairs(link.p2h) do
            if not link.createdPets[petId] and dbPet2HeroEid[petId] then
                self:AddToPendingCreatePet(preset, petId, dbPet2HeroEid[petId])
            end
        end
    end
end

---@return boolean, number
function CitySePresetHeroPetLink:IsInExplorerCollectResource(presetIndex)
    local link = self._presetDic[presetIndex]
    if not link then return false,0 end
    local petsLogic = link.petsGroupLogic
    return petsLogic:GetSeExplorerCollectResource()
end

---@return CitySeExplorerPetsLogicDefine.SetWorkResult, number|nil
function CitySePresetHeroPetLink:SetSeExplorerCollectResource(presetIndex, tileId)
    local link = self._presetDic[presetIndex]
    if not link then return false,nil end
    local petsLogic = link.petsGroupLogic
    return petsLogic:SetSeExplorerCollectResource(tileId)
end

function CitySePresetHeroPetLink:HeroId2PetId(preset, id)
    local link = self._presetDic[preset]
    if not link then return nil end
    return link.h2p[id]
end

function CitySePresetHeroPetLink:HeroId2IndexInList(preset, id)
    local link = self._presetDic[preset]
    if not link then return nil end
    return link.h2Index[id]
end

function CitySePresetHeroPetLink:PetId2HeroId(preset, id)
    local link = self._presetDic[preset]
    if not link then return nil end
    return link.p2h[id]
end

function CitySePresetHeroPetLink:AddToPendingCreatePet(preset, petId, heroEntityId)
    local link = self._presetDic[preset]
    if not link then
        link = self:LinkPairContent(preset)
        self._presetDic[preset] = link
    end
    ---@type {petId:number, heroEntityId:number}
    local pending
    for index = #link.pendingPet, 1, -1 do
        pending =  link.pendingPet[index]
        if pending.petId == petId then
            pending.heroEntityId = heroEntityId
            return
        end
    end
    pending = {}
    pending.petId = petId
    pending.heroEntityId = heroEntityId
    table.insert(link.pendingPet, pending)
end

function CitySePresetHeroPetLink:RemoveFromPendingCreatePet(preset, petId)
    local link = self._presetDic[preset]
    if not link then return end
    ---@type {petId:number, heroEntityId:number}
    local pending
    for index = #link.pendingPet, 1, -1 do
        pending =  link.pendingPet[index]
        if pending.petId == petId then
            table.remove(link.pendingPet, index)
            return
        end
    end
end

---@param petUnit CityUnitExplorerPet
function CitySePresetHeroPetLink:PetCreated(preset, petId, petUnit)
    local link = self._presetDic[preset]
    if not link then
        link = self:LinkPairContent(preset)
        self._presetDic[preset] = link
    end
    link.createdPets[petId] = petUnit
    link.petsGroupLogic:AddPet(petUnit)
end

function CitySePresetHeroPetLink:RemoveCreatedPeByHeroId(preset, heroId)
    local link = self._presetDic[preset]
    if not link then return end
    local petId = link.h2p[heroId]
    if not petId then return end
    local unit = link.createdPets[petId]
    if not unit then return petId end
    link.petsGroupLogic:RemovePet(unit)
    unit:Dispose()
    link.createdPets[petId] = nil
    return petId
end

---@return CityUnitExplorerPet
function CitySePresetHeroPetLink:GetCreatedPet(preset, petId)
    local link = self._presetDic[preset]
    if not link then return end
    return link.createdPets[petId]
end

function CitySePresetHeroPetLink:Tick(dt, nowTime)
    for _, link in pairs(self._presetDic) do
        link.petsGroupLogic:Tick(dt, nowTime)
        for _, unit in pairs(link.createdPets) do
            unit:Tick(dt, nowTime)
        end
    end
end

function CitySePresetHeroPetLink:PopOneInPending()
    for presetIndex, link in pairs(self._presetDic) do
        if #link.pendingPet > 0 then
            ---@type {petId:number, heroEntityId:number}
            local ret = table.remove(link.pendingPet, 1)
            return presetIndex, ret.petId, ret.heroEntityId
        end
    end
    return nil, nil, nil
end

function CitySePresetHeroPetLink:Dispose()
    for _, link in pairs(self._presetDic) do
        table.clear(link.pendingPet)
        for petId, petUnit in pairs(link.createdPets) do
            link.petsGroupLogic:RemovePet(petUnit)
            petUnit:Dispose()
            link.createdPets[petId] = nil
        end
        table.clear(link.h2p)
        table.clear(link.h2Index)
        table.clear(link.p2h)
    end
    table.clear(self._presetDic)
end

return CitySePresetHeroPetLink