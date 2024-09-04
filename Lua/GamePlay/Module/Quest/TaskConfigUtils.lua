local TaskCondType = require('TaskCondType')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
---@class CacheTaskCondition
---@field typ number 枚举来自TaskCondType
---@field op number 枚举来自CondExprOp
---@field count number
---@field params string[]

---@class TaskConfigUtils
local TaskConfigUtils = class('TaskConfigUtils')

---Get task condtion key for wds.TaskUnit.Counters
---@param branch number @index of Branchs, start from ZERO
---@param index number @index of Conditions, start from ZERO
function TaskConfigUtils.TaskCondKey(branch,index)
    return (2+branch)<<8 | index
end

-----------------------------------------------------------------
---Condition Value Processer

function TaskConfigUtils.GetNumberForm(param,pos)
    local params = string.split(param,';')
    if #params >= pos then
        local number = tonumber(params[pos])
        return number,params
    else
        return 0,params
    end
end

---按条件类型，解析条件参数
---@param type number @TaskCondType
---@param param string
---@return number,string[] @跟踪数值，参数数组
function TaskConfigUtils.CondProcesser(type,param)
    -- if type == TaskCondType.BuildMaxLevelByType then
    --     condNumber,condParam = TaskConfigUtils.CondProcesser_BuildMaxLevelByType(param)
    -- else

    -- local condNumber = 0
    -- local condParam
    -- if type == TaskCondType.ZoneStatus
    --     or type == TaskCondType.SovereignReputation
    --     or type == TaskCondType.SovereignOrgReputation
    -- then
    --     condNumber,condParam = TaskConfigUtils.GetNumberForm(param,2)
    -- elseif type == TaskCondType.CreepAllCleanedByZone
    --     or type == TaskCondType.FinishResearchTech
    --     or type == TaskCondType.FinishNpcService
    --     or type == TaskCondType.FinishChapter
    --     or type == TaskCondType.ReceiveCitizen
    -- then
    --     condNumber,condParam = TaskConfigUtils.GetNumberForm(param,999)
    --     condNumber = 1
    -- else
    --     condNumber,condParam = TaskConfigUtils.GetNumberForm(param,1)
    -- end
    local params = string.split(param,';')
    local condNumber = tonumber(params[1])
    local condParam = params
    local condDesc = params
    if type == TaskCondType.BuildNumByType then
        condDesc = {params[1], I18N.Get(ConfigRefer.BuildingTypes:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.BuildNumByLevel then
        condDesc = {params[1], I18N.Get(ConfigRefer.BuildingLevel:Find(tonumber(params[2])):Level())}
    elseif type == TaskCondType.PlaceFurnitureOfType then
        condDesc = {params[1], I18N.Get(ConfigRefer.CityFurnitureTypes:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.GatherResource then
        condDesc = {params[1], I18N.Get(ConfigRefer.CityElementData:Find(tonumber(params[2])):Type())}
    elseif type == TaskCondType.TaskFinished then
        condNumber = #params
        condDesc = {I18N.Get(ConfigRefer.Task:Find(tonumber(params[1])):Property():Name())}
    elseif type == TaskCondType.DecItemCountByID then
        condDesc = {params[1], I18N.Get(ConfigRefer.Item:Find(tonumber(params[2])):NameKey())}
    elseif type == TaskCondType.IncItemCountByID then
        condDesc = {params[1], I18N.Get(ConfigRefer.Item:Find(tonumber(params[2])):NameKey())}
    elseif type == TaskCondType.FinishLevelCount then
        condDesc = {params[1], I18N.Get(ConfigRefer.MapInstance:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.FinishStoryCount then
        condNumber = 1
    elseif type == TaskCondType.GatherResourceByElementID then
        condDesc = {params[1], I18N.Get(ConfigRefer.CityElementResource:Find(tonumber(params[2])):Id())}
    elseif type == TaskCondType.ZoneStatus then
        condNumber = 1 --tonumber(params[2])
        condDesc = {I18N.Get(ConfigRefer.CityZone:Find(tonumber(params[1])):Id(), params[2])}
    elseif type == TaskCondType.BuildEquip then
        condDesc = {params[1], I18N.Get(ConfigRefer.HeroEquipBuild:Find(tonumber(params[2])):Id())}
    elseif type == TaskCondType.InteractionUseItem then
        condDesc = {params[1], I18N.Get(ConfigRefer.Item:Find(tonumber(params[2])):NameKey())}
    elseif type == TaskCondType.SovereignReputation then
        condNumber = tonumber(params[2])
    elseif type == TaskCondType.SovereignOrgReputation then
        condNumber = tonumber(params[2])
    elseif type == TaskCondType.CreepAllCleanedByZone then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.CityZoneGroup:Find(tonumber(params[1])):Id())}
    elseif type == TaskCondType.FinishResearchTech then
        condNumber = 1
        local techType = ConfigRefer.CityTechLevels:Find(tonumber(params[1])):Type()
        condDesc = {I18N.Get(ConfigRefer.CityTechTypes:Find(techType):Name())}
    elseif type == TaskCondType.FinishNpcService then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.NpcService:Find(tonumber(params[1])):Content())}
    elseif type == TaskCondType.FinishChapter then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.Chapter:Find(tonumber(params[1])):Desc())}
    elseif type == TaskCondType.HeroLevel then
        condNumber = tonumber(params[2])
        condDesc = {I18N.Get(ConfigRefer.Heroes:Find(tonumber(params[1])):Name()), params[2]}
    elseif type == TaskCondType.HavePetsById then
        condNumber = tonumber(params[1])
        condDesc = {params[1], I18N.Get(ConfigRefer.Pet:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.ElementDelPolluted then
        condNumber = 1
    elseif type == TaskCondType.FinishWorldExpeditionTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.ExploreMist then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.LightenLightHouseTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.OccupyResource then
        condNumber = tonumber(params[1])
        condDesc = {params[1], I18N.Get(ConfigRefer.FixedMapBuilding:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.RebuildResource then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.BuildingDelPolluted then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.BuildingTypes:Find(tonumber(params[1])):Name())}
    elseif type == TaskCondType.AreaBecomeSafe then
        condNumber = 1
    elseif type == TaskCondType.HeroNumByLevel then
        condNumber = tonumber(params[1])
        condDesc = {params[1], params[2]}
    elseif type == TaskCondType.SprayingCreep then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.InteractTimes then
        condNumber = tonumber(params[1])
        condDesc = {params[1], I18N.Get(ConfigRefer.Mine:Find(tonumber(params[2])):Name())}
    elseif type == TaskCondType.ClearSlgCreepCount then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.SowSeed then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.SowSeedById then
        condNumber = tonumber(params[1])
        local itemId = ConfigRefer.Crop:Find(tonumber(params[2])):ItemId()
        condDesc = {params[1], I18N.Get(ConfigRefer.Item:Find(itemId):NameKey())}
    elseif type == TaskCondType.HarvestCrops then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.HarvestCropsById then
        condNumber = tonumber(params[1])
        local itemId = ConfigRefer.Crop:Find(tonumber(params[2])):ItemId()
        condDesc = {params[1], I18N.Get(ConfigRefer.Item:Find(itemId):NameKey())}
    elseif type == TaskCondType.Shopping then
        condNumber = tonumber(params[2])
        condDesc = {I18N.Get(ConfigRefer.Shop:Find(tonumber(params[1])):Name()), params[2]}
    elseif type == TaskCondType.DrawTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.HeroInPreset then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.Heroes:Find(tonumber(params[1])):Name())}
    elseif type == TaskCondType.PetInPreset then
        condNumber = 1
        local petId = ConfigRefer.PetType:Find(tonumber(params[1])):SamplePetCfg()
        condDesc = {I18N.Get(ConfigRefer.Pet:Find(petId):Name())}
    elseif type == TaskCondType.DrawTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.FinishRadarTask then
        condNumber = 1
    elseif type == TaskCondType.UnlockMistZone then
        condNumber = 1
    elseif type == TaskCondType.CanFinishRadarTask then
        condNumber = 1
    elseif type == TaskCondType.RadarSystemLevel then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.DailyTaskProgress then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.PresetPower then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.JoinVillageBattle then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.TrusteeshipAssembleTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.TrusteeshipAssembleTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.TrusteeshipAssembleTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.HeroBreakthrough then
        condNumber = tonumber(params[2])
    elseif type == TaskCondType.AllianceDonateTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.StrengthenEquipLevel then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.PetCountByRank then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.PetCountByLevel then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.BuildEquipTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.PlayerTotalPower then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.CatchWildPetCount then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.FurnitureLevel then
        condDesc = {I18N.Get(ConfigRefer.CityFurnitureTypes:Find(tonumber(params[1])):Name()) , params[2]}
        condNumber = tonumber(params[2])
    elseif type == TaskCondType.JoinAllianceBattleTimes then
        condNumber = tonumber(params[1])
    elseif type == TaskCondType.HavePetsByType then
        condNumber = tonumber(params[1])
        local petId = ConfigRefer.PetType:Find(tonumber(params[2])):SamplePetCfg()
        condDesc = {params[1], I18N.Get(ConfigRefer.Pet:Find(petId):Name())}
    elseif type == TaskCondType.FinishClimbTowerSection then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.ClimbTowerSection:Find(tonumber(params[1])):Name())}
    elseif type == TaskCondType.FinishHuntingSection then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.HuntingSection:Find(tonumber(params[1])):Name())}
    elseif type == TaskCondType.ReplicaPvpTitle then
        condNumber = 0
        condDesc = {I18N.Get(ConfigRefer.PvpTitleStage:Find(tonumber(params[1])):Name())}
    elseif type == TaskCondType.WorldStageScoreRank or type == TaskCondType.GVEDamageRank or type == TaskCondType.AllianceBigExpeditionRank then
        condNumber = 0
    elseif type == TaskCondType.ClearHomeMobs then
        condNumber = #params
        local para = params[1]
        local elemCfg = ConfigRefer.CityElementData:Find(tonumber(para))
        local spawnCfg = ConfigRefer.CityElementSpawner:Find(elemCfg:ElementId())
        condDesc = {I18N.Get(spawnCfg:NameForTask())}
    elseif type == TaskCondType.GetHomeTreasure then
        condNumber = #params
        local para = params[1]
        local elemCfg = ConfigRefer.CityElementData:Find(tonumber(para))
        local npcCfg = ConfigRefer.CityElementNpc:Find(elemCfg:ElementId())
        condDesc = {I18N.Get(npcCfg:Name())}
    elseif type == TaskCondType.FurnitureHavePetWork then
        condNumber = 1
    elseif type == TaskCondType.RecoverZone then
        condNumber = 1
    elseif type == TaskCondType.KillMonsterByTypeLevelCount then
        condNumber = tonumber(params[1])
        condDesc = {params[2]}
    elseif type == TaskCondType.MoveCityToLandform then
        condNumber = 1
        condDesc = {I18N.Get(ConfigRefer.Land:Find(tonumber(params[1])):Name())}
    end
    return condNumber, condParam, condDesc
end
--endregion
-----------------------------------------------------------------


return TaskConfigUtils