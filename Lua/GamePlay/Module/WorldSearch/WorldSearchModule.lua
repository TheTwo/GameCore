local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local SearchEntityType = require('SearchEntityType')
local MapBuildingType = require("MapBuildingType")
local OutputResourceType = require("OutputResourceType")

---@class WorldSearchModule
---@field maxResourceFieldLevel table<number, number>
local WorldSearchModule = class('WorldSearchModule',BaseModule)

function WorldSearchModule:OnRegister()
    self.maxResourceFieldLevel = {}
    for _, config in ConfigRefer.FixedMapBuilding:ipairs() do
        local outputType = config:OutputType()
        local level = config:Level()
        local currentLevel = self.maxResourceFieldLevel[outputType]
        if not currentLevel or level > currentLevel then
            self.maxResourceFieldLevel[outputType] = level
        end 
    end
end

function WorldSearchModule:OnRemove()

end

function WorldSearchModule:GetSearchTypeConfig(type)
    for _, config in ConfigRefer.SearchType:ipairs() do
        if config:Type() == type then
            return config
        end
    end
end

function WorldSearchModule:GetMaxMobLevel()
    return ConfigRefer.SearchEntity.length
end

function WorldSearchModule:GetCanAttackNormalMobLevel()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local attackLv = player.PlayerWrapper2.SearchEntity.CanAtkNormalMobMaxLevel
    return attackLv > 0 and attackLv or 1
end

function WorldSearchModule:GetCanAttackEliteMobLevel()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local attackLv = player.PlayerWrapper2.SearchEntity.CanAtkEliteMobMaxLevel
    return attackLv > 0 and attackLv or 1
end

function WorldSearchModule:GetMaxResourceFieldLevel(outputType)
    local defaultMaxLevel = ConfigRefer.ConstBigWorld:SearchResourceFieldMaxLevel() or 1
    local maxLevel = self.maxResourceFieldLevel[outputType]
    if maxLevel then
        return math.min(defaultMaxLevel, maxLevel)
    end
    return defaultMaxLevel
end

---@param resourceFieldConfigList number[]
function WorldSearchModule:GetResourceFieldOpenLandID(resourceFieldConfigList, outputType, level)
    for _, configID in ipairs(resourceFieldConfigList) do
        local config = ConfigRefer.FixedMapBuilding:Find(configID)
        if config:OutputType() == outputType and config:Level() == level then
            return config:LandId()
        end
    end
    return 0
end

function WorldSearchModule:IsFirstKillMonster(level)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local mask = player.PlayerWrapper2.SearchEntity.NormalMobFirstKillRewardMask
    return mask & (1 << (level - 1)) == 0
end

---@param level number
---@return ItemGroupInfo[]
function WorldSearchModule:GetMonsterFirstKillDropItems(level)
    local searchEntityConfig = ConfigRefer.SearchEntity:Find(level)
    if searchEntityConfig then
        local dropShowID = searchEntityConfig:FirstKillDropShow()
        local itemInfos = ModuleRefer.InventoryModule:GetDropItems(dropShowID)
        return itemInfos
    end
end

---@param monsterConfig KmonsterDataConfigCell
---@return ItemGroupInfo[]
function WorldSearchModule:GetMonsterDropItems(monsterConfig)
    local items = ModuleRefer.InventoryModule:GetDropItems(monsterConfig:DropShow())
    return items
end

---@return table<number>
function WorldSearchModule:GetSearchMonsterConfigs()
    local monsterConfigs = {}
    for _, config in ConfigRefer.KmonsterData:ipairs() do
        if config:SearchEntityType() == SearchEntityType.NormalMob then
            table.insert(monsterConfigs, config:Id())
        end
    end
    return monsterConfigs
end

---@return table<number>
function WorldSearchModule:GetSearchPetMonsterConfigs()
    local petConfigs = {}
    for _, config in ConfigRefer.KmonsterData:ipairs() do
        if config:SearchEntityType() == SearchEntityType.EliteMob then
            table.insert(petConfigs, config:Id())
        end 
    end
    return petConfigs
end

---@return FixedMapBuildingConfigCell[]
function WorldSearchModule:GetSearchResourceFieldsConfigs()
    local resourceFieldConfigList = ModuleRefer.KingdomConstructionModule:GetFixedBuildingConfigsByType(MapBuildingType.Resource)
    
    ---@type FixedMapBuildingConfigCell[]
    local configList = {}
    for _, configID in ipairs(resourceFieldConfigList) do
        local resourceFieldConfig = ConfigRefer.FixedMapBuilding:Find(configID)
        local outputType = resourceFieldConfig:OutputType()
        local found
        for _, config in ipairs(configList) do
            if config:OutputType() == outputType then
                found = true
                break
            end
        end

        if not found then
            table.insert(configList, resourceFieldConfig)
        end
    end
    table.sort(configList, function(a, b)
        return a:OutputType() < b:OutputType()
    end)
    return configList
end

---@param petMonsterConfig KmonsterDataConfigCell
function WorldSearchModule:IsPetMonsterLockedByLandform(petMonsterConfig)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return true
    end
    local landform = player.PlayerWrapper3.Landform
    if not landform or not landform.UnlockedLandform then
        return true
    end

    local landID = petMonsterConfig:LandId()
    if not landform.UnlockedLandform[landID] then
        return true
    end
    return false
end

---@param petMonsterConfig KmonsterDataConfigCell
function WorldSearchModule:IsPetMonsterLockedByVillage(petMonsterConfig)
    local petConfig = ConfigRefer.Pet:Find(petMonsterConfig:SearchPetId())
    if not petConfig then
        return true
    end

    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return true
    end

    local villageConfigID = petConfig:VillageBuildingId() 
    if villageConfigID <= 0 then
        return false
    end

    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local buildingBriefs = allianceData.MapBuildingBriefs.MapBuildingBriefs
    ---@param brief wds.MapBuildingBrief
    for _, brief in pairs(buildingBriefs) do
        if brief.ConfigId == villageConfigID then
            return false
        end
    end

    return true
end

---@return PetConfigCell[]
function WorldSearchModule:GetPetEggDrop(itemGroupID)
    ---@type PetConfigCell[]
    local petConfigs = {}

    local itemGroup = ConfigRefer.ItemGroup:Find(itemGroupID)
    if not itemGroup then
        return petConfigs
    end
    
    local petMap = {}
    local itemInfoLength = itemGroup:ItemGroupInfoListLength()
    for k = 1, itemInfoLength do
        local itemInfo = itemGroup:ItemGroupInfoList(k)
        local eggItem = ConfigRefer.Item:Find(itemInfo:Items())
        if not eggItem then
            goto continue
        end
        local rewardPool = ConfigRefer.PetEggRewardPool:Find(tonumber(eggItem:UseParam(1)))
        if not rewardPool then
            goto continue
        end
        local poolLength = rewardPool:RandomCfgLength()
        for i = 1, poolLength do
            local randomConfigID = rewardPool:RandomCfg(i):RandomPool()
            local randomConfig = ConfigRefer.PetEggRewardRandomPool:Find(randomConfigID)
            local randomLength = randomConfig:RandomWeightLength()
            for j = 1, randomLength do
                local weightConfig = randomConfig:RandomWeight(j)
                petMap[weightConfig:RefPet()] = true
            end
        end
        ::continue::
    end

    for id, _ in pairs(petMap) do
        local petConfig = ConfigRefer.Pet:Find(id)
        table.insert(petConfigs, petConfig)
    end
    table.sort(petConfigs, function(a, b) 
        return a:Id() < b:Id()
    end)
    return petConfigs
end

function WorldSearchModule:GetCanAttackPetLevel()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local attackLv = player.PlayerWrapper2.SearchEntity.CanAtkEliteMobMaxLevel
    return attackLv > 0 and attackLv or 1
end

function WorldSearchModule:RecordSearchCategory(selectType)
    g_Game.PlayerPrefsEx:SetIntByUid("WorldSearchCategory", selectType)
end

function WorldSearchModule:GetSearchCategory()
    return g_Game.PlayerPrefsEx:GetIntByUid("WorldSearchCategory", SearchEntityType.NormalMob)
end

function WorldSearchModule:RecordSearchLevel(selectType, lv)
    g_Game.PlayerPrefsEx:SetIntByUid("WorldSearchLvByType" .. selectType, lv)
end

function WorldSearchModule:GetSearchLevel(selectType)
    return g_Game.PlayerPrefsEx:GetIntByUid("WorldSearchLvByType" .. selectType, 1)
end

function WorldSearchModule:CheckIsInSearchList(searchLv, isElite, mobId)
    local searchEntityCfg = ConfigRefer.SearchEntity:Find(searchLv)
    if searchEntityCfg == nil then
        return false
    end
    if isElite then
        for i = 1, searchEntityCfg:EliteMobLength() do
            if searchEntityCfg:EliteMob(i) == mobId then
                return true
            end
        end
    else
        for i = 1, searchEntityCfg:NormalMobLength() do
            if searchEntityCfg:NormalMob(i) == mobId then
                return true
            end
        end
    end
    return false
end

return WorldSearchModule
