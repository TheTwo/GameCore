local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local ObjectType = require("ObjectType")

---@class MailUtils
local MailUtils = {}

---@param monsterId number
---@return string, string, number, KmonsterDataConfigCell
function MailUtils.GetMonsterNameIconLevel(monsterId)
    local name = ""
    local icon = ""
    local level = 0

    local monsterCfg = ConfigRefer.KmonsterData:Find(monsterId)
    if monsterCfg then
        name = I18N.Get(monsterCfg:Name())
        level = monsterCfg:Level()

        local heroInfo = monsterCfg:Hero(1)
        if heroInfo then
            local heroNpcCfg = ConfigRefer.HeroNpc:Find(heroInfo:HeroConf())
            if heroNpcCfg then
                icon = MailUtils.GetHeroHeadMiniById(heroNpcCfg:HeroConfigId())
            end
        end
    end

    return name, icon, level, monsterCfg
end

function MailUtils.GetHeroHeadMiniById(heroCfgId)
    local icon = ""
    local heroCfg = ConfigRefer.Heroes:Find(heroCfgId)
    if heroCfg then
        local clientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
        if clientRes then
            icon =  ArtResourceUtils.GetUIItem(clientRes:HeadMini())
        end
    end
    
    return icon
end

function MailUtils.GetMonsterPower(monsterId)
    local monsterCfg = ConfigRefer.KmonsterData:Find(monsterId)
    if monsterCfg then
        return monsterCfg:RecommendPower()
    end

    return 0
end

---@param buildingId number
---@return string, string, number
function MailUtils.GetMapBuildingNameIconLevel(buildingId)
    local name = ""
    local icon = ""
    local level = 0
    local buildingCfg = ConfigRefer.FixedMapBuilding:Find(buildingId)
    if buildingCfg then
        level = buildingCfg:Level()
        name = I18N.Get(buildingCfg:Name())
        icon = buildingCfg:Image()
    end
    
    return name, icon, level
end

---@param mineId number
---@return string, string
function MailUtils.GetSlgInteractorNameIcon(mineId)
    local name = ""
    local icon = ""
    local mineConfig = ConfigRefer.Mine:Find(mineId)
    if mineConfig then
        name = I18N.Get(mineConfig:Name())
        icon = mineConfig:Icon()
    end
    return name, icon
end

---@param allianceName string
---@param playerName string
---@return string
function MailUtils.MakePlayerName(allianceName, playerName)
    local prefix = ""
    if (not string.IsNullOrEmpty(allianceName)) then
        prefix = "[" .. allianceName .. "]"
    end
    return prefix .. playerName
end

---@class MailUnitData
---@field unit wds.BattleReportHeroUnit|wds.BattleReportPetUnit
---@field type number @英雄：1，宠物：2

---@param player wds.BattleReportUnit
---@return MailUnitData[]
function MailUtils.GetHerosAndPets(player)
    local units = {}
    local count = 1

    for _, hero in pairs(player.Heroes) do
        if hero and hero.TId > 0 then
            units[count] = {unit = hero, type = 1}
            count = count + 1
            
            for _, pet in pairs(hero.Pets) do
                if pet.TId > 0 then
                    units[count] = {unit = pet, type = 2}
                    count = count + 1
                end
            end
        end
    end    
    
    return units
end

---@param player wds.BattleReportUnit
---@return number, number, number
function MailUtils.CalculateTotalStatistics(player)
	local totalDamageDealt = 0
	local totalDamageTaken = 0
	local totalHealing = 0

    for _, hero in pairs(player.Heroes) do
        if hero and hero.TId > 0 then
            totalDamageDealt = totalDamageDealt + hero.OutputDamage			
            totalDamageTaken = totalDamageTaken + hero.TakeDamage
            totalHealing = totalHealing + hero.OutputHeal
    
            for _, pet in pairs(hero.Pets) do
                if pet and pet.TId > 0 then
                    totalDamageDealt = totalDamageDealt + pet.OutputDamage
                    totalDamageTaken = totalDamageTaken + pet.TakeDamage
                    totalHealing = totalHealing + pet.OutputHeal    
                end
            end
        end
    end

    return totalDamageDealt, totalDamageTaken, totalHealing
end

---@param reportUnits wds.BattleReportUnitBasic[]
function MailUtils.GetRallyTroops(reportUnits)
    local troops = {}
    local count = reportUnits and #reportUnits or 0
    for i = 1, count do
        local troop = reportUnits[i]
        if troop.ObjectType == ObjectType.SlgTroop then
            table.insert(troops, troop)
        end
    end
    return troops
end

return MailUtils