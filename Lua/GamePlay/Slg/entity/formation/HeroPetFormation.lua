local VisibleType = require("VisibleType")
local ConfigRefer = require("ConfigRefer")
local FormationUtility = require("FormationUtility")
local SlgUtils = require("SlgUtils")

local TroopFormationSole = {}
local RadiusScale = 1

TroopFormationSole.radiusScale = RadiusScale
TroopFormationSole.heros = {}
TroopFormationSole.herosBattle = {
    near = {},
    far = {}
}

TroopFormationSole.pets = {}
TroopFormationSole.petsBattle = {}

local function InitFormation()
    local heroNormalPos =
    {
        [1] = {X =  0,  Y = 0},
        [2] = {X = -68, Y = 0},
        [3] = {X =  68, Y = 0},
    }

    local petNormalPos =
    {
        [1] = {X =  0,  Y = -65},
        [2] = {X = -68, Y = -65},
        [3] = {X =  68, Y = -65},
    }

    local heroBattlePosNear =
    {
        [1] = {X =  0,   Y = 70},
        [2] = {X = -100, Y = 70},
        [3] = {X =  100, Y = 70},
    }

    local heroBattlePosFar =
    {
        [1] = {X =  0,   Y = 0},
        [2] = {X = -100, Y = 0},
        [3] = {X =  100, Y = 0},
    }

    local petBattlePos =
    {
        [1] = {X = -50, Y = -10},
        [2] = {X = -50, Y = -10},
        [3] = {X =  50, Y = -10},
    }

    for i = 1, 3 do
        TroopFormationSole.heros[i] =
        {
            X = heroNormalPos[i].X / 100.0 * RadiusScale,
            Y = heroNormalPos[i].Y / 100.0 * RadiusScale
        }

        TroopFormationSole.herosBattle.near[i] =
        {
            X = heroBattlePosNear[i].X / 100.0 * RadiusScale,
            Y = heroBattlePosNear[i].Y / 100.0 * RadiusScale
        }

        TroopFormationSole.herosBattle.far[i] =
        {
            X = heroBattlePosFar[i].X / 100.0 * RadiusScale,
            Y = heroBattlePosFar[i].Y / 100.0 * RadiusScale
        }

        TroopFormationSole.pets[i] =
        {
            X = petNormalPos[i].X / 100.0 * RadiusScale,
            Y = petNormalPos[i].Y / 100.0 * RadiusScale
        }

        TroopFormationSole.petsBattle[i] =
        {
            X = petBattlePos[i].X / 100.0 * RadiusScale,
            Y = petBattlePos[i].Y / 100.0 * RadiusScale
        }
    end
end

InitFormation()

local function CalculateHeroBattleOffset(i, heroType, heroBattlePosesNear, heroBattlePosesFar, visibleType)
    local heroBattleOffset = nil

    if visibleType < VisibleType.OnlyMainHero then
        heroBattleOffset = heroType[i] == 1 and heroBattlePosesNear[i] or heroBattlePosesFar[i]
    else
        heroBattleOffset = {X = 0, Y = 0}
    end

    return heroBattleOffset
end

---@class HeroPetFormation
local HeroPetFormation = {}

---@param troopData CS.DragonReborn.SLG.Troop.TroopData
---@param heros table<number, wds.TroopHero> | MapField
---@param troopRadius number
---@param slgScale number
---@param syncUnitStateOff boolean
---@param visibleType number @VisibleType
function HeroPetFormation.Create(troopData, heros, troopRadius, slgScale, syncUnitStateOff, visibleType)
    troopData.heroName = {}
    troopData.heroScale = {}
    troopData.heroType = {}
    troopData.heroState = {}
    troopData.heroOffset = {}
    troopData.heroBattleOffset = {}
    troopData.heroNormalAtkId = {}

    troopData.petName = {}
    troopData.petScale = {}
    troopData.petState = {}
    troopData.petOffset = {}
    troopData.petBattleOffset = {}
    troopData.petNormalAtkId = {}

    visibleType = visibleType or VisibleType.All

    local maxIndex = FormationUtility.GetMaxIndex(heros)
    local heroCount = maxIndex + 1

    --正常站位，第一个英雄在中心，其他英雄在中心的左右
    --所以三种不同的VisibleType表现是一样的
    local heroPoses = FormationUtility.GetScaledPoses(heroCount, troopRadius, TroopFormationSole.heros)
    local petPoses = FormationUtility.GetScaledPoses(heroCount, troopRadius, TroopFormationSole.pets)
    local heroBattlePosNear = FormationUtility.GetScaledPoses(heroCount, troopRadius, TroopFormationSole.herosBattle.near)
    local heroBattlePosFar = FormationUtility.GetScaledPoses(heroCount, troopRadius, TroopFormationSole.herosBattle.far)
    local petBattlePoses = FormationUtility.GetScaledPoses(heroCount, troopRadius, TroopFormationSole.petsBattle)

    for index = 0, maxIndex do
        local i = index + 1

        local heroPos = heroPoses[i]
        local petPos = petPoses[i]

        troopData.heroName[i] = ''
        troopData.heroScale[i] = slgScale
        troopData.heroType[i] = 1 -- 1：近战；2：远程；3：宠物；4：战争堡垒；5：BOSS
        troopData.heroState[i] = 0
        troopData.heroOffset[i] = {x = heroPos.X, y = heroPos.Y}
        troopData.heroNormalAtkId[i] = 0

        troopData.petName[i] = ''
        troopData.petScale[i] = slgScale
        troopData.petState[i] = 0
        troopData.petOffset[i] = {x = petPos.X, y = petPos.Y}
        troopData.petNormalAtkId[i] = 0

        local hero = heros[index]
        if hero and hero.HeroID > 0 then
            local heroConfig = ConfigRefer.Heroes:Find(hero.HeroID)
            if heroConfig then
                local heroName, heroScale = FormationUtility.GetHeroModelInfo(heroConfig)
                troopData.heroName[i] = heroName
                troopData.heroScale[i] = heroScale * slgScale
                troopData.heroType[i] = heroConfig:TheFront() and 1 or 2
                troopData.heroState[i] = string.IsNullOrEmpty(heroName) and 0 or (hero.Hp > 0 and 1 or 0) -- 0：死亡；1：存活
                troopData.heroNormalAtkId[i] = SlgUtils.GetHeroNormalAttackId(hero)
            end

            if visibleType == VisibleType.All and hero.Pets then
                for _, pet in pairs(hero.Pets) do
                    local petConfig = ConfigRefer.Pet:Find(pet.PetID)
                    if petConfig then
                        local petName, petScale = FormationUtility.GetPetModelInfo(petConfig)
                        troopData.petName[i] = petName
                        troopData.petScale[i] = petScale * slgScale
                        troopData.petState[i] = string.IsNullOrEmpty(petName) and 0 or (pet.Hp > 0 and 1 or 0)
                        troopData.petNormalAtkId[i] = SlgUtils.GetPetNormalAttackId(pet)
                    end
                    break
                end
            end
        end

        local heroBattleOffset = CalculateHeroBattleOffset(i, troopData.heroType, heroBattlePosNear, heroBattlePosFar, visibleType)
        local petBattlePos = petBattlePoses[i]
        
        troopData.heroBattleOffset[i] = {x = heroBattleOffset.X, y = heroBattleOffset.Y}
        troopData.petBattleOffset[i] = {x = heroBattleOffset.X + petBattlePos.X, y = heroBattleOffset.Y + petBattlePos.Y}
    end

    troopData.syncUnitStateOff = syncUnitStateOff
end

return HeroPetFormation