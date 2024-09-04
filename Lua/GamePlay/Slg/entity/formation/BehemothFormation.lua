local ConfigRefer = require("ConfigRefer")

---@class BehemothFormation

local BehemothFormation = {}

---@param troopData CS.DragonReborn.SLG.Troop.TroopData
---@param monsterCfg KmonsterDataConfigCell
---@param slgScale number
function BehemothFormation.Create(troopData, monsterCfg, slgScale)
    local heroName = {}
    local heroScale = {}
    local heroType = {}
    local petName = {}
    local petScale = {}
    local heroState = {}
    local petState = {}

    local heroConfig = nil
    if monsterCfg and monsterCfg:HeroLength() > 0 then
        local mainInfo = monsterCfg:Hero(1)
        local heroNpcConfig = mainInfo and ConfigRefer.HeroNpc:Find(mainInfo:HeroConf()) or nil
        if heroNpcConfig then
            heroConfig = ConfigRefer.Heroes:Find(heroNpcConfig:HeroConfigId())
        end
    end
    heroScale[1] = slgScale
    heroType[1] = 1 -- 1：近战；2：远程；3：宠物；4：战争堡垒；5：BOSS
    if heroConfig then
        local heroModel = nil
        ---@type HeroClientResConfigCell
        local heroClientConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
        local heroArtRes = nil

        if heroClientConfig then
            heroArtRes = ConfigRefer.ArtResource:Find(heroClientConfig:SlgModel())
        end
        if heroArtRes then
            heroModel = heroArtRes:Path()
        end
        if string.IsNullOrEmpty(heroModel) then
            g_Logger.ErrorChannel('Troop',"Can not Find heroModel heroID:%d, heroClientID:%d",info.ID, heroConfig:ClientResCfg() )
        elseif not string.EndWith(heroModel,'_gpu') then
            heroModel = heroModel .. '_gpu'
        end
        if not string.IsNullOrEmpty(heroModel) then
            heroName[1] = heroModel
            heroScale[1] = heroArtRes:ModelScale() * heroScale[1]
            heroType[1] = heroConfig:AttackDistance() + heroType[1]
        end
        heroState[1] = 1 -- info.Battle.Hp > 0 and 1 or 0
    end
    if heroName[1] == nil then
        heroName[1] = ''
        heroState[1] = 0
    end

    local heroOffset = {[1] = {x=0,y=0}}
    local petOffset = {}

    local heroBattleOffset ={[1] = {x=0,y=0}}
    local petBattleOffset = {}
    troopData.heroName = heroName
    troopData.heroScale = heroScale
    troopData.heroType = heroType
    troopData.heroOffset = heroOffset
    troopData.heroBattleOffset = heroBattleOffset
    troopData.heroState = heroState
    troopData.petName = petName
    troopData.petScale = petScale
    troopData.petOffset = petOffset
    troopData.petBattleOffset = petBattleOffset
    troopData.petState = petState
end

return BehemothFormation