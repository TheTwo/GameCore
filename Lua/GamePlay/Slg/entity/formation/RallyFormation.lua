local ConfigRefer = require("ConfigRefer")
local FormationUtility = require("FormationUtility")
local DBEntityType = require("DBEntityType")
local ExtraInfoType = require("ExtraInfoType")
local SlgUtils = require("SlgUtils")

---@class RallyFormation
local RallyFormation = {}

local RadiusScale = 1

local RowSpacing = 65 / 100 * RadiusScale
local RowHeight = 2 * RowSpacing

local ColSpacing = 68 / 100 * RadiusScale
local ColWidth = 2.5 * ColSpacing
local HalfColWidth = ColWidth / 2

local HeroPos =
{
    [1] = {X =  0,          Y = 0},
    [2] = {X = -ColSpacing, Y = 0},
    [3] = {X =  ColSpacing, Y = 0},
}

local PetPos =
{
    [1] = {X =  0,          Y = -RowSpacing},
    [2] = {X = -ColSpacing, Y = -RowSpacing},
    [3] = {X =  ColSpacing, Y = -RowSpacing},
}

local function CalculateOffset(rowIndex, isOdd, heroPos, offsetX, offsetY)
    if isOdd and rowIndex == 0 then
        heroPos = {X = heroPos.X, Y = heroPos.Y}
    else
        heroPos = {X = heroPos.X + offsetX, Y = heroPos.Y + offsetY}
    end
    return heroPos
end

---@param troopData CS.DragonReborn.SLG.Troop.TroopData
---@param army wds.Army
---@param radius number
function RallyFormation.Create(troopData, army, radius)
    ---@type wds.ArmyMemberInfo[]
    local members = {}

    for _, value in pairs(army.PlayerTroopIDs) do
        table.insert(members, value)
    end

    ---@param x wds.ArmyMemberInfo
    ---@param y wds.ArmyMemberInfo
    local function compare(x, y)
        return x.Index < y.Index
    end

    table.sort(members, compare)

    ---@type wds.Troop[]
    local troops = {}
    for _, value in ipairs(members) do
        local troop = g_Game.DatabaseManager:GetEntity(value.Id, DBEntityType.Troop)
        table.insert(troops, troop)
    end

    return RallyFormation.CreateByTroops(troops, radius, troopData)
end

---@param troops wds.Troop[]
---@param radius number
---@param troopData CS.DragonReborn.SLG.Troop.TroopData
function RallyFormation.CreateByTroops(troops, radius, troopData)
    local heroPetIndices = {}
    heroPetIndices.heros = {}
    heroPetIndices.pets = {}
    heroPetIndices.heroIndexCount = 0
    heroPetIndices.petIndexCount = 0
    heroPetIndices.type = ExtraInfoType.HeroPetIndex

    local troopCount = #troops
    local isOdd = troopCount % 2 ~= 0

    for troopIndex = 1, troopCount do
        local troop = troops[troopIndex]
        local rowIndex = RallyFormation.CalculateRowIndex(troopIndex - 1, isOdd)
        local colIndex = RallyFormation.CalculateColIndex(troopIndex - 1, isOdd)
        local heroIndexMap = RallyFormation.GetLocalToGlablIndexMap(troop.ID, heroPetIndices.heros)
        local petIndexMap = RallyFormation.GetLocalToGlablIndexMap(troop.ID, heroPetIndices.pets)
        local heros = troop.Battle.Group.Heros

        heroPetIndices.heroIndexCount, heroPetIndices.petIndexCount = RallyFormation.Append(rowIndex, colIndex, 
            isOdd, heros, radius, troopData, heroIndexMap, petIndexMap,
            heroPetIndices.heroIndexCount, heroPetIndices.petIndexCount)
    end

    return heroPetIndices
end

---@param rowIndex number @部队行索引，从0开始
---@param colIndex number @部队列索引，从0开始
---@param isOdd boolean
---@param heros table<number, wds.TroopHero> | MapField
---@param radius number
---@param troopData CS.DragonReborn.SLG.Troop.TroopData
---@param heroIndexMap table<number, number>
---@param petIndexMap table<number, number>
---@param heroCount number
---@param petCount number
---@return number, number
function RallyFormation.Append(rowIndex, colIndex, isOdd, heros, radius, troopData, heroIndexMap, petIndexMap, heroIndexCount, petIndexCount)
    local maxIndex = FormationUtility.GetMaxIndex(heros)
    local heroCount = maxIndex + 1

    local heroPoses = FormationUtility.GetScaledPoses(heroCount,radius, HeroPos)
    local petPoses = FormationUtility.GetScaledPoses(heroCount,radius, PetPos)
    local offsetX = (-HalfColWidth + colIndex * ColWidth) * radius
    local offsetY = (-rowIndex * RowHeight) * radius

    for index = 0, maxIndex do
        local i = index + 1
        local heroIndex = heroIndexCount + 1
        local petIndex = petIndexCount + 1

        local heroPos = CalculateOffset(rowIndex, isOdd, heroPoses[i], offsetX, offsetY)
        local petPos = CalculateOffset(rowIndex, isOdd, petPoses[i], offsetX, offsetY)

        troopData.heroName[heroIndex] = ''
        troopData.heroScale[heroIndex] = 1
        troopData.heroType[heroIndex] = 1 -- 1：近战；2：远程；3：宠物；4：战争堡垒；5：BOSS
        troopData.heroState[heroIndex] = 0
        troopData.heroOffset[heroIndex] = {x = heroPos.X, y = heroPos.Y}
        troopData.heroBattleOffset[heroIndex] = {x = heroPos.X, y = heroPos.Y}
        troopData.heroNormalAtkId[heroIndex] = 0

        troopData.petName[petIndex] = ''
        troopData.petScale[petIndex] = 1
        troopData.petState[petIndex] = 0
        troopData.petOffset[petIndex] = {x = petPos.X, y = petPos.Y}
        troopData.petBattleOffset[petIndex] = {x = petPos.X, y = petPos.Y}
        troopData.petNormalAtkId[petIndex] = 0

        local hero = heros[index]
        if hero and hero.HeroID > 0 then
            local heroConfig = ConfigRefer.Heroes:Find(hero.HeroID)
            if heroConfig then
                local heroName, heroScale = FormationUtility.GetHeroModelInfo(heroConfig)
                troopData.heroName[heroIndex] = heroName
                troopData.heroScale[heroIndex] = heroScale
                troopData.heroType[heroIndex] = heroConfig:TheFront() and 1 or 2
                troopData.heroState[heroIndex] = string.IsNullOrEmpty(heroName) and 0 or (hero.Hp > 0 and 1 or 0)
                troopData.heroNormalAtkId[heroIndex] = SlgUtils.GetHeroNormalAttackId(hero)
            end

            if hero.Pets then
                for _, pet in pairs(hero.Pets) do
                    local petConfig = ConfigRefer.Pet:Find(pet.PetID)
                    if petConfig then
                        local petName, petScale = FormationUtility.GetPetModelInfo(petConfig)
                        troopData.petName[petIndex] = petName
                        troopData.petScale[petIndex] = petScale
                        troopData.petState[petIndex] = string.IsNullOrEmpty(petName) and 0 or (pet.Hp > 0 and 1 or 0)
                        troopData.petNormalAtkId[petIndex] = SlgUtils.GetPetNormalAttackId(pet)
                    end
                    break
                end
            end
        end

        heroIndexMap[i] = heroIndex -- wrpc.IndexParam里的索引从1开始
        petIndexMap[i] = petIndex -- wrpc.IndexParam里的索引从1开始

        heroIndexCount = heroIndexCount + 1
        petIndexCount = petIndexCount + 1
    end

    return heroIndexCount, petIndexCount
end

---@param index number @成员数组索引，从0开始
---@param isOdd boolean @成员个数是否为奇数
---@return number @部队行索引，从0开始
function RallyFormation.CalculateRowIndex(index, isOdd)
    if isOdd then
        return math.floor((index + 1) / 2)
    else
        return math.floor(index / 2)
    end
end

---@param index number @成员数组索引，从0开始
---@param isOdd boolean @成员个数是否为奇数
---@return number @部队列索引，从0开始
function RallyFormation.CalculateColIndex(index, isOdd)
    if isOdd then
        if index == 0 then
            return 0
        end
        return (index - 1) % 2
    else
        return index % 2
    end
end

function RallyFormation.GetLocalToGlablIndexMap(id, heroPetIndices)
    local localToGlobal = heroPetIndices[id]
    if localToGlobal == nil then
        localToGlobal = {}
        heroPetIndices[id] = localToGlobal
    end
    return localToGlobal
end

return RallyFormation