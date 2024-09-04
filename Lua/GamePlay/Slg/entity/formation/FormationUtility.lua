local ConfigRefer = require("ConfigRefer")

---@class FormationUtility
local FormationUtility = {}

---@param count number @unit count
---@param poses number[][] @number[3][2]
---@return table
function FormationUtility.GetScaledPoses(count,radius,poses)
    local posesLength = #poses
    local troopPoses = {}
    local length = math.min(count,posesLength)
    for i=1,length do
        local value = poses[i]
        troopPoses[i] = {X = value.X * radius, Y = value.Y * radius}
    end
    return troopPoses
end

---@param heros table<number, wds.TroopHero> | MapField
function FormationUtility.GetMaxIndex(heros)
    local index = -math.huge
    for i, _ in pairs(heros) do
        index = math.max(i, index)
    end
    return index
end

function FormationUtility.GetHeroModelInfo(heroConfig)
    if heroConfig then
        ---@type HeroClientResConfigCell
        local heroClientConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())

        local heroArtRes = nil
        if heroClientConfig then
            heroArtRes = ConfigRefer.ArtResource:Find(heroClientConfig:SlgModel())
        end

        local heroModel = nil
        local heroScale = 1

        if heroArtRes then
            heroModel = heroArtRes:Path()
            heroScale = heroArtRes:ModelScale()
        end

        if string.IsNullOrEmpty(heroModel) then
            heroModel = ""
        elseif not string.EndWith(heroModel,'_gpu') then
            heroModel = heroModel .. '_gpu'
        end

        return heroModel, heroScale
    end
end

function FormationUtility.GetPetModelInfo(petConfig)
    if petConfig then
        ---@type ArtResourceConfigCell
        local petArtRes = ConfigRefer.ArtResource:Find(petConfig:SlgModel())
        local petModel = nil
        local petScale = 1

        if petArtRes then
            petModel = petArtRes:Path()
            petScale = petArtRes:ModelScale()
        end

        if string.IsNullOrEmpty(petModel) then
            petModel = ""
        elseif not string.EndWith(petModel,'_gpu') then
            petModel = petModel .. '_gpu'
        end

        return petModel, petScale
    end
end

return FormationUtility