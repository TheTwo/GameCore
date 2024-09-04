local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require('DBEntityType')
local UIMediatorNames = require('UIMediatorNames')
local GuideUtil = CS.GuideUtil
local GuideUtils = require('GuideUtils')
---@class GuideConditionProcesser
local GuideConditionProcesser = class('GuideConditionProcesser')


---@class ConditionProcesserStack
---@field data table
---@field top number
---@field guideCall GuideCallConfigCell


function GuideConditionProcesser:ctor()
    self.cmdStack = CS.System.Array.CreateInstance(typeof(CS.System.String),128)
end

---@param guideCall GuideCallConfigCell|nil
---@return ConditionProcesserStack
local function CreateStack(guideCall)
    ---@type ConditionProcesserStack
    local o = {}
    o.data = {}
    o.top = 1
    o.guideCall = guideCall
    return o
end
---@param stack ConditionProcesserStack
local function StackIsEmpty(stack)
    return stack.top == 1
end
---@param stack ConditionProcesserStack
local function StackPush(stack,item)
    stack.data[stack.top] = item
    stack.top = stack.top + 1
end
---@param stack ConditionProcesserStack
local function StackPop(stack)
    if StackIsEmpty(stack) then
        return nil
    end
    local index = stack.top - 1
    local o = stack.data[index]
    stack.data[index] = nil
    stack.top = index
    return o
end
---@param stack ConditionProcesserStack
local function StackPeek(stack)
    if StackIsEmpty(stack) then
        return nil
    end
    return stack.data[stack.top - 1]
end
---@param stack ConditionProcesserStack
local function StackCount(stack)
    return stack.top - 1
end

--region Condition Processer
---@param paramStack ConditionProcesserStack
function GuideConditionProcesser.ConditionProcesser_ConditionAnd(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of ConditionAnd is less then 2',StackCount(paramStack) )
        return false
    end
    local p1 = StackPop(paramStack)
    local p2 = StackPop(paramStack)
    return p1 and p2
end
---@param paramStack ConditionProcesserStack
function GuideConditionProcesser.ConditionProcesser_ConditionOr(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of ConditionOr is less then 2',StackCount(paramStack) )
        return false
    end
    local p1 = StackPop(paramStack)
    local p2 = StackPop(paramStack)
    return p1 or p2
end
---@param paramStack ConditionProcesserStack
function GuideConditionProcesser.ConditionProcesser_ConditionNot(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of ConditionNot is less then 1',StackCount(paramStack) )
        return false
    end
    return not StackPop(paramStack)
end


---获取英雄数量的数量大于等于X
---@param paramStack ConditionProcesserStack
function GuideConditionProcesser.ConditionProcesser_HeroNumber(paramStack)
    local param = StackPop(paramStack)
    local heroNum = tonumber(param)
    if not heroNum then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {HeroNumber,'.. param ..'}')
        return false
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local heroCount = table.nums(player.Hero.HeroInfos)
    return heroCount >= heroNum
end

---英雄的最高等级大于等于X
------@param param string @X
function GuideConditionProcesser.ConditionProcesser_HeroLevel(paramStack)
    local param = StackPop(paramStack)
    local heroLvl = tonumber(param)
    if not heroLvl then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {HeroLevel,'.. param ..'}')
        return false
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    local heroCount = table.nums(player.Hero.HeroInfos)
    if heroCount < 1 then
        return false
    end
    local maxLevel = 0
    for key, info in pairs(player.Hero.HeroInfos) do
        if maxLevel < info.Level then
            maxLevel = info.Level
        end
    end
    return maxLevel >= heroLvl
end

---英雄的最高突破等级大于等于X
------@param param string @X
function GuideConditionProcesser.ConditionProcesser_HeroBreakLevel(paramStack)
    local param = StackPop(paramStack)
    local heroBreakLvl = tonumber(param)
    if not heroBreakLvl then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {HeroLevel,'.. param ..'}')
        return false
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    local heroCount = table.nums(player.Hero.HeroInfos)
    if heroCount < 1 then
        return false
    end
    local maxBreakLevel = 0
    for key, info in pairs(player.Hero.HeroInfos) do
        if maxBreakLevel < info.BreakThroughLevel then
            maxBreakLevel = info.BreakThroughLevel
        end
    end
    return maxBreakLevel >= heroBreakLvl
end

---英雄的最高晋升等级大于等于X
------@param param string @X
function GuideConditionProcesser.ConditionProcesser_HeroStrengthLevel(paramStack)
    local param = StackPop(paramStack)
    local heroBreakLvl = tonumber(param)
    if not heroBreakLvl then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {HeroLevel,'.. param ..'}')
        return false
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    local maxStarLevel = 0
    for key, info in pairs(player.Hero.HeroInfos) do
        if maxStarLevel < info.StarLevel then
            maxStarLevel = info.StarLevel
        end
    end
    return maxStarLevel >= heroBreakLvl
end

function GuideConditionProcesser.ConditionProcesser_IsFurnitureLocked(paramStack)
    local param = StackPop(paramStack)
    local lvCfgId = tonumber(param)
    if not lvCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {id,'.. param ..'}')
        return false
    end

    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {id,'.. param ..'}')
        return false
    end

    if not myCity.furnitureManager:IsDataReady() then
        g_Logger.ErrorChannel('GuideModule','furnitureManager data not ready {id,'.. param ..'}')
        return false
    end

    for id, furniture in pairs(myCity.furnitureManager.hashMap) do
        if furniture.configId == lvCfgId and furniture:IsLocked() then
            return true
        end
    end

    return false
end

function GuideConditionProcesser.ConditionProcesser_IsRoomExisted(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of IsRoomExisted is less then 1', StackCount(paramStack))
        return false
    end

    local param1 = StackPop(paramStack)
    local roomCfgId = tonumber(param1)
    if not roomCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {IsRoomExisted,%s}',param1)
        return false
    end

    local city = GuideConditionProcesser.GetMyCity()
    local legoBuilding = city.legoManager:GetLegoBuildingByRoomCfgId(roomCfgId)
    return legoBuilding ~= nil
end

function GuideConditionProcesser.ConditionProcesser_IsFurnitureUpgradeConditionMeet(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of IsFurnitureUpgradeConditionMeet is less then 1', StackCount(paramStack))
        return false
    end

    local param1 = StackPop(paramStack)
    local furLvCfgId = tonumber(param1)
    if not furLvCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {IsFurnitureUpgradeConditionMeet,%s}',param1)
        return false
    end

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(furLvCfgId)
    if not lvCfg then
        g_Logger.ErrorChannel('GuideModule','Failed to get lvCfg by id %d', furLvCfgId)
        return false
    end

    for i = 1, lvCfg:LevelUpConditionLength() do
        local taskId = lvCfg:LevelUpCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg ~= nil then
            local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskCfg:Id())
            local finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
            if not finished then
                return false
            end
        end
    end

    return true
end

function GuideConditionProcesser.ConditionProcesser_IsFurnitureUpgradeUIConditionMeet()
    local cityLegoBuildingUIMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.CityLegoBuildingUIMediator)
    if cityLegoBuildingUIMediator then
        return cityLegoBuildingUIMediator:IsCurrentFurnitureUpgradeConditionMeet()
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsRadarLevelEqual(paramStack)
    local param = StackPop(paramStack)
    local radarLevel = tonumber(param)
    return ModuleRefer.RadarModule:GetRadarLv() == radarLevel
end

function GuideConditionProcesser.ConditionProcesser_HasPetEgg(paramStack)
    local count1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70071)
    local count2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70072)
    local count3 = ModuleRefer.InventoryModule:GetAmountByConfigId(70073)
    local countSpecial1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70068)
    local countSpecial2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70069)
    return count1 > 0 or count2 > 0 or count3 > 0 or countSpecial1 > 0 or countSpecial2 > 0
end

---某引导组已完成
------@param param string @GuideGroupConfigCell.ID
function GuideConditionProcesser.ConditionProcesser_GuideGroupCompleted(paramStack)
    local param = StackPop(paramStack)
    local groupId = tonumber(param)
    if not groupId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {GuideGroupCompleted,'.. param ..'}')
        return false
    end

    return ModuleRefer.GuideModule:IsGuideGroupFinished(groupId)
end

---@return wds.Castle,City
function GuideConditionProcesser.GetMyCastle()
    local myCity = ModuleRefer.CityModule.myCity
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','Can not find my city!')
        return nil
    end
    local castle = myCity:GetCastle()
    if not castle then
        g_Logger.ErrorChannel('GuideModule','Can not find my castle!')
        return nil
    end
    return castle,myCity
end

---@type City
function GuideConditionProcesser.GetMyCity()
    local myCity = ModuleRefer.CityModule.myCity
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','Can not find my city!')
        return nil
    end
    return myCity
end

---@param param string id,num
function GuideConditionProcesser.ConditionProcesser_BuldingLevel(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of BuldingLevel is less then 2',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local param2 = StackPop(paramStack)
    local id = tonumber(param1)
    local num = tonumber(param2)
    if not id or not num then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {BuldingLevel,%s,%s}',param1,param2)
        return false
    end

    local castle = GuideConditionProcesser.GetMyCastle()
    if castle == nil or castle.BuildingInfos == nil then
        return false
    end

    local buildingCfg = ConfigRefer.BuildingLevel:Find(id)

    local buildingType = buildingCfg:Type()
    local buildingLvl = buildingCfg:Level()

    local buildCount = 0
    for key, value in pairs(castle.BuildingInfos) do
        if value.BuildingType == buildingType
        and value.Level == buildingLvl
        then
            buildCount = buildCount + 1
        end
    end

    return buildCount >= num
end

---@param param string id,num
function GuideConditionProcesser.ConditionProcesser_FurnitureLevel(paramStack)

    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of FurnitureLevel is less then 2',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local param2 = StackPop(paramStack)
    local id = tonumber(param1)
    local num = tonumber(param2)
    if not id or not num then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureLevel,%s,%s}',param1,param2)
        return false
    end

    local castle = GuideConditionProcesser.GetMyCastle()
    if castle == nil or castle.CastleFurniture == nil then
        return false
    end

    local furnitureCount = 0
    for key, value in pairs(castle.CastleFurniture) do
        if value.ConfigId == id  then
            furnitureCount = furnitureCount + 1
        end
    end
    return furnitureCount >= num
end

function GuideConditionProcesser.ConditionProcesser_FurnitureType(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of FurnitureType is less then 1',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local furTypeCfgId = tonumber(param1)
    if not furTypeCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureType,%s}',param1)
        return false
    end

    local castle = GuideConditionProcesser.GetMyCastle()
    if castle == nil or castle.CastleFurniture == nil then
        return false
    end

    local furnitureCount = 0
    for key, castleFurniture in pairs(castle.CastleFurniture) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
        if lvCfg:Type() == furTypeCfgId then
            furnitureCount = furnitureCount + 1
        end
    end
    return furnitureCount >= 1
end

function GuideConditionProcesser.ConditionProcesser_FurnitureOwnType(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of FurnitureOwnType is less then 1',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local furTypeCfgId = tonumber(param1)
    if not furTypeCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureOwnType,%s}',param1)
        return false
    end

    local castle = GuideConditionProcesser.GetMyCastle()
    if castle == nil or castle.CastleObjectCount == nil or castle.CastleObjectCount.FurnitureCount == nil then
        return false
    end

    local furnitureCount = 0
    for key, value in pairs(castle.CastleObjectCount.FurnitureCount) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(key)
        if lvCfg:Type() == furTypeCfgId then
            furnitureCount = furnitureCount + value
        end
    end

    return furnitureCount >= 1
end

function GuideConditionProcesser.ConditionProcesser_FurnitureProcessEnableCheck(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of FurnitureProcessEnableCheck is less then 1', StackCount(paramStack))
        return false
    end

    local param1 = StackPop(paramStack)
    local recipeId = tonumber(param1)
    if not recipeId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureProcessEnableCheck,%s}',param1)
        return false
    end

    local city = GuideConditionProcesser.GetMyCity()
    if city == nil or city.cityWorkManager == nil or city.furnitureManager == nil then
        g_Logger.ErrorChannel('GuideModule','Failed to get MyCity or CityWorkManager or CityFurnitureManager')
        return false
    end

    local recipeCfg = ConfigRefer.CityProcess:Find(recipeId)
    if recipeCfg == nil then
        g_Logger.ErrorChannel('GuideModule','Failed to get recipeCfg by id %d', recipeId)
        return false
    end

    local lvCfgId = city.cityWorkManager:GetProcessRecipeOutputFurnitureLvCfgId(recipeCfg)
    if lvCfgId == 0 then
        g_Logger.ErrorChannel('GuideModule','This recipe is not for furniture. id: %d', recipeId)
        return false
    end

    local processCount, reachVersionLimit = city.furnitureManager:GetFurnitureCanProcessCount(lvCfgId)
    if processCount <= 0 then
        g_Logger.ErrorChannel('GuideModule', "This recipe can\'t do it more, now. id: %d", recipeId)
        return false
    end
    return true
end

function GuideConditionProcesser.ConditionProcesser_IsRoomUnlocked(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of IsRoomUnlocked is less then 1', StackCount(paramStack))
        return false
    end

    local param1 = StackPop(paramStack)
    local roomCfgId = tonumber(param1)
    if not roomCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {IsRoomUnlocked,%s}',param1)
        return false
    end

    local city = GuideConditionProcesser.GetMyCity()
    local legoBuilding = city.legoManager:GetLegoBuildingByRoomCfgId(roomCfgId)
    if legoBuilding == nil then
        g_Logger.ErrorChannel('GuideModule','Failed to get legoBuilding by roomCfgId %d', roomCfgId)
        return false
    end

    return legoBuilding:IsUnlocked()
end

function GuideConditionProcesser.ConditionProcesser_CheckRoomLv(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of IsRoomUnlocked is less then 1', StackCount(paramStack))
        return false
    end

    local param1 = StackPop(paramStack)
    local roomCfgId = tonumber(param1)
    local param2 = StackPop(paramStack)
    local lv = tonumber(param2)
    if not roomCfgId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {IsRoomUnlocked,%s}',param1)
        return false
    end
    if not lv then
        g_Logger.ErrorChannel('GuideModule','Command Param Lv Error {IsRoomUnlocked,%s}',param2)
        return false
    end

    local city = GuideConditionProcesser.GetMyCity()
    local legoBuilding = city.legoManager:GetLegoBuildingByRoomCfgId(roomCfgId)
    if legoBuilding == nil then
        g_Logger.ErrorChannel('GuideModule','Failed to get legoBuilding by roomCfgId %d', roomCfgId)
        return false
    end

    return legoBuilding.roomLevel >= lv
end

function GuideConditionProcesser.ConditionProcesser_CityZone(paramStack)
    if StackCount(paramStack) < 2 then
    g_Logger.ErrorChannel('GuideModule','Param Number(%d) of CityZone is less then 2',StackCount(paramStack))
        return false
    end
    ---@type string @CityZoneConfigCell:ID()
    local param1 = StackPop(paramStack)
    ---@type string @CityZoneStatus
    local param2 = StackPop(paramStack)
    local id = tonumber(param1)
    local state = tonumber(param2)
    if not id or not state then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {CityZone,%s,%s}',param1,param2)
        return false
    end
    local castle = GuideConditionProcesser.GetMyCastle()
    if castle == nil or castle.Zones == nil then
        return false
    end

    local zoneState = castle.Zones[id]

    return zoneState ~= nil and zoneState == state
end

function GuideConditionProcesser.ConditionProcesser_CityNPC(paramStack)
    local param = StackPop(paramStack)
    local id = tonumber(param)
    if not id then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {CityNPC,'.. param ..'}')
        return false
    end
    local castle,myCity = GuideConditionProcesser.GetMyCastle()
    local tiles = nil
    if myCity then
        tiles = myCity:GetCellTilesByNpcConfigId(id,false)
    end

    return tiles and #tiles > 0
end

---@param param string id,num
function GuideConditionProcesser.ConditionProcesser_Item(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of Item is less then 2',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local param2 = StackPop(paramStack)
    local id = tonumber(param1)
    local num = tonumber(param2)
    if not id or not num then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {Item,%s,%s}',param1,param2)
        return false
    end

    local count = ModuleRefer.InventoryModule:GetAmountByConfigId(id)
    return count >= num
end

---@param param string id
function GuideConditionProcesser.ConditionProcesser_Story(paramStack)
    local param = StackPop(paramStack)
    local storyTaskId = tonumber(param)
    if storyTaskId == nil or storyTaskId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {Story,'.. param ..'}')
        return false
    end
    return ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(storyTaskId)
end
function GuideConditionProcesser.ConditionProcesser_Chapter(paramStack)
    local param = StackPop(paramStack)
    local chapterId = tonumber(param)
    if chapterId == nil or chapterId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {Chapter,'.. param ..'}')
        return false
    end
    return ModuleRefer.QuestModule:ChapterFinishQuickCheck(chapterId)
end
function GuideConditionProcesser.ConditionProcesser_ChapterTaskCompleted(paramStack)
    local param = StackPop(paramStack)
    local taskId = tonumber(param)
    if taskId == nil or taskId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {Task,'.. param ..'}')
        return false
    end
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
    return taskState == wds.TaskState.TaskStateFinished
end

function GuideConditionProcesser.ConditionProcesser_FurnitureIdel(paramStack)
    local param = StackPop(paramStack)
    local furnitureId = tonumber(param)
    if furnitureId == nil or furnitureId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureIdel,'.. param ..'}')
        return false
    end
    ---@type City
    local myCity = GuideConditionProcesser.GetMyCity()
    local tiles = nil
    if myCity then
        tiles = myCity:GetFurnitureTilesByFurnitureType(furnitureId)
    end
    ---@type wds.CastleFurniture
    local isFree = false
    if tiles and #tiles > 0 and myCity.castle then
        for _, value in pairs(tiles) do
            if value:IsFree() then
                isFree = true
            end
        end
    end
    return isFree
end

function GuideConditionProcesser.ConditionProcesser_FurnitureReward(paramStack)
    local param = StackPop(paramStack)
    local furnitureId = tonumber(param)
    if furnitureId == nil or furnitureId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {FurnitureIdel,'.. param ..'}')
        return false
    end
    ---@type City
    local myCity = GuideConditionProcesser.GetMyCity()
    local tiles = nil
    if myCity then
        tiles = myCity:GetFurnitureTilesByFurnitureType(furnitureId)
    end
    ---@type wds.CastleFurniture
    local isFinished = false
    if tiles and #tiles > 0 and myCity.castle then
        for _, value in pairs(tiles) do
            if value:HasProcessFinished() then
                isFinished = true
            end
        end
    end
    return isFinished
end

function GuideConditionProcesser.ConditionProcesser_BuildingState(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of BuildingState is less then 2',StackCount(paramStack))
        return false
    end
    local param = StackPop(paramStack)
    local param1 = StackPop(paramStack)
    local buildingTypeId = tonumber(param)
    local buildState = tonumber(param1)
    if buildingTypeId == nil or buildingTypeId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {BuildingState,%s,%s}',param,param1)
        return false
    end
    ---@type City
    local myCity = GuideConditionProcesser.GetMyCity()
    local tiles = nil
    if myCity then
        tiles = myCity:GetCityCellTilesByBuildingType(buildingTypeId)
    end
    local buildingData = nil
    if tiles and #tiles > 0 and myCity.castle then
        for key, value in pairs(tiles) do
            local cell = value:GetCell()
            if cell then
                local targetId = cell.tileId
                if targetId ~= nil then
                    local data = myCity.castle.BuildingInfos[targetId]
                    if data then
                        buildingData = data
                        break
                    end
                end
            end
        end
    end

    return buildingData ~= nil and buildingData.Status == buildState
end

function GuideConditionProcesser.ConditionProcesser_ResourceNotEnough(paramStack)
    local param = StackPop(paramStack)
    local cityResId = tonumber(param)
    if cityResId == nil or cityResId < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {ResourceNotEnough,'.. param ..'}')
        return false
    end

    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {BuildingPolluted,'.. param ..'}')
        return false
    end
    local tiles = myCity:GetCellTilesByResourceConfigId(cityResId,true)
    return tiles == nil or #tiles < 1
end

function GuideConditionProcesser.ConditionProcesser_ResourceNotEnoughByType(paramStack)
    local param = StackPop(paramStack)
    local cityResType = tonumber(param)
    if cityResType == nil or cityResType < 1 then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {ResourceNotEnough,'.. param ..'}')
        return false
    end

    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {BuildingPolluted,'.. param ..'}')
        return false
    end
    local tiles = myCity:GetCellTilesByResourceType(cityResType,true)
    return tiles == nil or #tiles < 1
end


function GuideConditionProcesser.ConditionProcesser_CitizenFree(paramStack)
    local param = StackPop(paramStack)
    local count = tonumber(param)
    if count == nil then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {CitizenFree,'.. param ..'}')
        return false
    end
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {BuildingPolluted,'.. param ..'}')
        return false
    end
    local freeCount = myCity.cityCitizenManager:GetFreeCitizenCount()
    return freeCount >= count
end

function GuideConditionProcesser.ConditionProcesser_ZoneHasCreep(paramStack)
    local param = StackPop(paramStack)
    local param1 = StackPop(paramStack)
    local zoneId = tonumber(param)
    local state = tonumber(param1)
    if zoneId == nil or state == nil then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {ZoneHasCreep,'.. param ..'}')
        return false
    end
    local myCity = GuideUtils.FindMyCity()
    local creepManager = myCity.creepManager
    if creepManager then
        local gridConfig = myCity.gridConfig
        local sizeX = gridConfig.cellsX
        local mapData = myCity:GetMapData()

        for x,y, value in creepManager.area:pairs() do
            if value ~= CreepStatus.NONE and (value & state ~= 0) then
                local idx = y * sizeX + x + 1
                local tileZoneId = mapData.zoneData[idx]
                if tileZoneId == zoneId then
                    return true
                end
            end
        end
        return false
    else
        return false
    end
end

function GuideConditionProcesser.ConditionProcesser_BuildingPolluted(paramStack)
    local param = StackPop(paramStack)
    local buildingLevelId = tonumber(param)
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {BuildingPolluted,'.. param ..'}')
        return false
    end
    return myCity.buildingManager:IsBuildingPollutedByLevelCfgId(buildingLevelId)
end

function GuideConditionProcesser.ConditionProcesser_ElementPolluted(paramStack)
    local param = StackPop(paramStack)
    local cityElementNpcId = tonumber(param)
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        g_Logger.ErrorChannel('GuideModule','not find city {BuildingPolluted,'.. param ..'}')
        return false
    end
    local isPolluted = myCity.elementManager:IsNpcPollutedById(cityElementNpcId)
    return isPolluted
end

function GuideConditionProcesser.ConditionProcesser_Teching(paramStack)
    local param = StackPop(paramStack)
    local techId = tonumber(param)
    local curTechingId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    return curTechingId == techId
end

function GuideConditionProcesser.ConditionProcesser_TechingFinished(paramStack)
    local param = StackPop(paramStack)
    local techId = tonumber(param)
    return ModuleRefer.ScienceModule:CheckIsResearched(techId)
end

function GuideConditionProcesser.ConditionProcesser_TaskFinished(paramStack)
    local param = StackPop(paramStack)
    local taskId = tonumber(param)
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
    return taskState == wds.TaskState.TaskStateFinished
end

function GuideConditionProcesser.ConditionProcesser_PetNumber(paramStack)
    local param = StackPop(paramStack)
    local petNumber = tonumber(param)
    return petNumber <= ModuleRefer.PetModule:GetPetCount()
end

function GuideConditionProcesser.ConditionProcesser_PetLevel(paramStack)
    local param = StackPop(paramStack)
    local petLevel = tonumber(param)
    return petLevel <= ModuleRefer.PetModule:GetMaxPetLevel()
end

function GuideConditionProcesser.ConditionProcesser_TroopBackToCity(paramStack)
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for _, troop in ipairs(troops) do
        local troopData = troop.entityData
        if troopData.MapStates.BackToCity then
            return true
        end
    end
end

function GuideConditionProcesser.ConditionProcesser_TroopIdle(paramStack)
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for _, troop in ipairs(troops) do
        local troopData = troop.entityData
        if not (troopData.MapStates.BackToCity or troopData.MapStates.Battling or troopData.MapStates.Attacking or troopData.MapStates.Moving) then
            return true
        end
    end
end

function GuideConditionProcesser.ConditionProcesser_TroopBackToCity(paramStack)
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for _, troop in ipairs(troops) do
        local troopData = troop.entityData
        if troopData.MapStates.Moving then
            return true
        end
    end
end

function GuideConditionProcesser.ConditionProcesser_IsTroopInCamp(paramStack)
    local param = StackPop(paramStack)
    local troopIndex = tonumber(param)
    ---@type TroopInfo[]
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    if troops and troops[troopIndex] then
        return not troops[troopIndex].locked and (not troops[troopIndex].troopId or troops[troopIndex].troopId < 1)
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_KingdomSlgInteractor(paramStack)
    local param = StackPop(paramStack)
    local slgInteractorId = tonumber(param)
    local allResourceFields = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.SlgInteractor)
    for _, value in pairs(allResourceFields) do
        local cfgId = value.Interactor.ConfigID
        if cfgId == slgInteractorId and ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
               return true
        end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_KingdomSlgMonster(paramStack)
    local param = StackPop(paramStack)
    local slgMonsterId = tonumber(param)
    local mobCtrl = ModuleRefer.SlgModule.troopManager:FindMobCtrl(slgMonsterId)
    if not mobCtrl then
        return false
    end
    return true
end

function GuideConditionProcesser.ConditionProcesser_IsTraining(paramStack)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    if castleMilitia.SwitchOff then
        return false
    end
    local costItemGroup = ConfigRefer.CityConfig:CityMilitiaTrainCost()
    local itemArrays = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(costItemGroup)
    local isEnough = true
    for i = 1, #itemArrays do
        if ModuleRefer.InventoryModule:GetAmountByConfigId(itemArrays[i].configCell:Id()) < itemArrays[i].count then
            isEnough = false
        end
    end
    return isEnough
end

function GuideConditionProcesser.ConditionProcesser_IsRadarCanUp(paramStack)
    return ModuleRefer.RadarModule:CheckIsCanUpgrade()
end

function GuideConditionProcesser.ConditionProcesser_IsRadarTaskById(paramStack)
    local param = StackPop(paramStack)
    local radarTaskId = tonumber(param)
    return ModuleRefer.RadarModule:IsRadarTaskById(radarTaskId)
end

function GuideConditionProcesser.ConditionProcesser_IsOnHud(paramStack)
    local topType = g_Game.UIManager:GetTopUIMediatorType()
    if topType == g_Game.UIManager.UIMediatorType.Hud or topType == g_Game.UIManager.UIMediatorType.TopMostHud then
        return true
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsInCity(paramStack)
    local scene = g_Game.SceneManager.current
    if scene then
        local sceneName = scene:GetName()
        if sceneName == 'KingdomScene' then
            if scene:IsInMyCity() then
                return true
            end
        end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsCityHasPet(paramStack)
    local param = StackPop(paramStack)
    local _,myCity = GuideConditionProcesser.GetMyCastle()
    if myCity then
        local params = string.split(param, ';')
        for i = 1, #params do
            local petNpcId = tonumber(params[i])
            local tiles = myCity:GetCellTilesByNpcConfigId(petNpcId,true)
            if tiles and #tiles > 0 then
                return true
            end
        end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsRewardRadarTask(paramStack)
    local rewardCount = ModuleRefer.RadarModule:GetRadarTaskRewardCount()
    return rewardCount > 0
end

function GuideConditionProcesser.ConditionProcesser_IsHasCreepInCity(paramStack)
    local param = StackPop(paramStack)
    local elementId = tonumber(param)
    local myCity = ModuleRefer.CityModule.myCity
    local creepManager = myCity.creepManager
    if creepManager then
        for x,y, value in creepManager.area:pairs() do
            if not myCity:IsFogMask(x, y) then
                if GuideUtils.IsTileHasByCreepBlock(value, elementId) then
                    return true
                end
            end
        end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsHasCreepInCityById(paramStack)
    local param = StackPop(paramStack)
    local elementId = tonumber(param)
    local myCity = ModuleRefer.CityModule.myCity
    local creepManager = myCity.creepManager
    if creepManager then
       local creepInfo = creepManager:GetCreepDB(elementId)
       if creepInfo and next(creepInfo) and not creepInfo.Removed then
            return true
       end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsAutoFillHp(paramStack)
    for i = 1, 3 do
        local presets = ModuleRefer.PlayerModule:GetCastle().TroopPresets.Presets[i]
        if presets and not presets.AutoFulfillHp then
            return false
        end
    end
    return true
end

function GuideConditionProcesser.ConditionProcesser_IsCarryPet(paramStack)
    local presets = ModuleRefer.PlayerModule:GetCastle().TroopPresets.Presets[1]
    if presets then
        for i = 1, 3 do
            local heroId = ((presets.Heroes or {})[i] or {}).HeroCfgID
            if heroId then
                local petId = ModuleRefer.HeroModule:GetHeroLinkPet(heroId)
                if petId and petId > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function GuideConditionProcesser.ConditionProcesser_IsInAlliance(paramStack)
    return ModuleRefer.AllianceModule:IsInAlliance()
end

function GuideConditionProcesser.ConditionProcesser_IsAllianceRankAbove(paramStack)
    local param = StackPop(paramStack)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    local rank = tonumber(param)
    return ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank >= rank
end

function GuideConditionProcesser.ConditionProcesser_HasAllianceAuthority(paramStack)
    local param = StackPop(paramStack)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    local authority = tonumber(param)
    return ModuleRefer.AllianceModule:CheckHasAuthority(authority) == true
end


---@param param string type,num
function GuideConditionProcesser.ConditionProcesser_IsHasTypeEquipNum(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of EquipTypeNum is less then 2',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local param2 = StackPop(paramStack)
    local eqiupType = tonumber(param1)
    local num = tonumber(param2)
    if not eqiupType or not num then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {EquipTypeNum,%s,%s}',param1,param2)
        return false
    end
    local equips = ModuleRefer.HeroModule:GetAllEquipsByEquipType(eqiupType)
    local curCount = #equips
    return curCount >= num
end

---@param paramStack string @npcServiceConfigId
function GuideConditionProcesser.ConditionProcesser_IsNpcServiceFinished(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of npcServiceConfigId is less then 1',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local npcServiceConfigId = tonumber(param1)
    if not npcServiceConfigId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {npcServiceConfigId,%s}',param1)
        return false
    end
    return ModuleRefer.PlayerServiceModule:GetNpcServiceState(npcServiceConfigId) == wds.NpcServiceState.NpcServiceStateFinished
end

---@param paramStack string @npcServiceConfigId
function GuideConditionProcesser.ConditionProcesser_HasNpcService(paramStack)
    if StackCount(paramStack) < 1 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of npcServiceConfigId is less then 1',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local npcServiceConfigId = tonumber(param1)
    if not npcServiceConfigId then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {npcServiceConfigId,%s}',param1)
        return false
    end
    return ModuleRefer.PlayerServiceModule:GetNpcServiceState(npcServiceConfigId) ~= nil
end

---@param paramStack string @npcServiceConfigId,wds.NpcServiceState
function GuideConditionProcesser.ConditionProcesser_IsNpcServiceStateMatch(paramStack)
    if StackCount(paramStack) < 2 then
        g_Logger.ErrorChannel('GuideModule','Param Number(%d) of npcServiceConfigId,state is less then 2',StackCount(paramStack))
        return false
    end
    local param1 = StackPop(paramStack)
    local param2 = StackPop(paramStack)
    local npcServiceConfigId = tonumber(param1)
    local state = tonumber(param2)
    if not npcServiceConfigId or not state then
        g_Logger.ErrorChannel('GuideModule','Command Param Error {npcServiceConfigId,%s,%s}',param1,param2)
        return false
    end
    return ModuleRefer.PlayerServiceModule:GetNpcServiceState(npcServiceConfigId) == state
end

GuideConditionProcesser.Commands={
    ['ConditionAnd']        = {processer = GuideConditionProcesser.ConditionProcesser_ConditionAnd,         desc = '{ConditionAnd,X,Y}逻辑运算与'},
    ['ConditionOr']         = {processer = GuideConditionProcesser.ConditionProcesser_ConditionOr,          desc = '{ConditionOr,X,Y} 逻辑运算或'},
    ['ConditionNot']        = {processer = GuideConditionProcesser.ConditionProcesser_ConditionNot,         desc = '{ConditionNot,X} 逻辑运算与非'},
    ['HeroNumber']          = {processer = GuideConditionProcesser.ConditionProcesser_HeroNumber,           desc = '{HeroNumber,X} 拥有X个英雄'},
    ['HeroLevel']           = {processer = GuideConditionProcesser.ConditionProcesser_HeroLevel,            desc = '{HeroLevel,X} 任意英雄等级达到X级'},
    ['HeroBreakLevel']      = {processer = GuideConditionProcesser.ConditionProcesser_HeroBreakLevel,       desc = '{HeroBreakLevel,X} 任意英雄突破等级达到X级'},
    ['GuideGroupCompleted'] = {processer = GuideConditionProcesser.ConditionProcesser_GuideGroupCompleted,  desc = '{GuideGroupCompleted,ID} 某ID的引导组(GuideGroup)已经完成'},
    ['BuildingLevel']       = {processer = GuideConditionProcesser.ConditionProcesser_BuldingLevel,         desc = '{BuildingLevel,id,x} 拥有某id的建筑x个'},
    ['FurnitureLevel']      = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureLevel,       desc = '{FurnitureLevel,id,x} 摆放某id的家具x个'},
    ['CityZone']            = {processer = GuideConditionProcesser.ConditionProcesser_CityZone,             desc = '{CityZone,id,x} 某id的区域处于某个状态(未1 可2 已3 收复4)'},
    ['Item']                = {processer = GuideConditionProcesser.ConditionProcesser_Item,                 desc = '{Item,id,x} 拥有x个某id的道具'},
    ['Story']               = {processer = GuideConditionProcesser.ConditionProcesser_Story,                desc = '{Story,id} 某id的剧情已经播放'},
    ['Chapter']             = {processer = GuideConditionProcesser.ConditionProcesser_Chapter,              desc = '{Chapter,id} 某id的章节已经完成(快速判断,比当前章节ID小的都认为是已经完成)'},
    ['ChapterTaskCompleted']= {processer = GuideConditionProcesser.ConditionProcesser_ChapterTaskCompleted, desc = '{ChapterTaskCompleted,id} 某id的章节任务已经完成(快速判断,非当前章节的任务都认为是未完成)'},
    ['CityNPC']             = {processer = GuideConditionProcesser.ConditionProcesser_CityNPC,              desc = '{CityNPC,id} 某id的NPC据点是否存在'},
    ['FurnitureIdel']       = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureIdel,        desc = '{FurnitureIdel,id} 某id的家具是否空闲'},
    ['FurnitureReward']     = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureReward,      desc = '{FurnitureReward,id} 某id的家具是否处于待领取'},
    ['BuildingState']       = {processer = GuideConditionProcesser.ConditionProcesser_BuildingState,        desc = '{BuildingState,typeId,state} 某typeId的建筑是否处于某状态(Normal 0,Created 1,Constructing 2,ConstructSuspend 3,Constructed 4,UpgradeReady 5,Upgrading 6,UpgradeSuspend 7,Upgraded 8)'},
    ['ResourceNotEnough']   = {processer = GuideConditionProcesser.ConditionProcesser_ResourceNotEnough,    desc = '{ResourceNotEnough,id} 某id的资源点已经采集完'},
    ['CitizenFree']         = {processer = GuideConditionProcesser.ConditionProcesser_CitizenFree,          desc = '{CitizenFree,X} 空闲居民数量大于等于x个'},
    ['ZoneHasCreep']        = {processer = GuideConditionProcesser.ConditionProcesser_ZoneHasCreep,         desc = '{ZoneHasCreep,id,X} 某id的区域是否有状态X的菌毯'},
    ['BuildingPolluted']    = {processer = GuideConditionProcesser.ConditionProcesser_BuildingPolluted,     desc = '{BuildingPolluted,id} 某id的建筑是否被污染'},
    ['ElementPolluted']     = {processer = GuideConditionProcesser.ConditionProcesser_ElementPolluted,      desc = '{ElementPolluted,id} 某id的据点是否被污染'},
    ['Teching']             = {processer = GuideConditionProcesser.ConditionProcesser_Teching,              desc = '{Teching,id} 某id的科技是否正在研究'},
    --['MapInstance']       = {processer = GuideConditionProcesser.ConditionProcesser_MapInstance,          desc = '{MapInstance,id} 某id关卡已经完成'},
    --['GuideFail']         = {processer = GuideConditionProcesser.ConditionProcesser_GuideFail,            desc = '{GuideFail,id} 某id的引导组执行失败'},
    ['TechingFinished']     = {processer = GuideConditionProcesser.ConditionProcesser_TechingFinished,      desc = '{TechingFinished,id} 某id的科技已经完成研究'},
    ['TaskFinished']        = {processer = GuideConditionProcesser.ConditionProcesser_TaskFinished,         desc = '{TaskFinished,id} 某id的任务已经完成'},
    ['PetNumber']           = {processer = GuideConditionProcesser.ConditionProcesser_PetNumber,            desc = '{PetNumber,X} 拥有X个宠物'},
    ['PetLevel']            = {processer = GuideConditionProcesser.ConditionProcesser_PetLevel,             desc = '{PetLevel,X} 任意宠物达到X级'},
    ['TroopBackToCity']     = {processer = GuideConditionProcesser.ConditionProcesser_TroopBackToCity,      desc = '{TroopBackToCity} SLG部队处于回城状态'},
    ['TroopIdle']           = {processer = GuideConditionProcesser.ConditionProcesser_TroopIdle,            desc = '{TroopIdle} SLG部队处于驻扎状态'},
    ['TroopMoving']         = {processer = GuideConditionProcesser.ConditionProcesser_TroopMoving,          desc = '{TroopMoving} SLG部队处于行军状态'},
    ['ResourceTypeNotEnough']= {processer = GuideConditionProcesser.ConditionProcesser_ResourceNotEnoughByType,desc = '{ResourceTypeNotEnough,id} 某type的资源点已经采集完'},
    ['IsTroopInCamp']       = {processer = GuideConditionProcesser.ConditionProcesser_IsTroopInCamp,        desc = '{IsTroopInCamp,X} 第X个部队是不是在兵营中(X从1到6)'},
    ['KingdomSlgInteractor']= {processer = GuideConditionProcesser.ConditionProcesser_KingdomSlgInteractor, desc = '{KingdomSlgInteractor,X} 是否存在某id的大世界采集物'},
    ['KingdomSlgMonster']   = {processer = GuideConditionProcesser.ConditionProcesser_KingdomSlgMonster,    desc = '{KingdomSlgMonster,X} 是否存在某id的大世界怪物'},
    ['IsTraining']          = {processer = GuideConditionProcesser.ConditionProcesser_IsTraining,           desc = '{IsTraining} 擂台是否在招募'},
    ['IsRadarCanUp']        = {processer = GuideConditionProcesser.ConditionProcesser_IsRadarCanUp,         desc = '{IsRadarCanUp} 雷达是否可升级'},
    ['IsRadarTaskById']     = {processer = GuideConditionProcesser.ConditionProcesser_IsRadarTaskById,      desc = '{IsRadarTaskById, X} 是否有某个id的雷达任务'},
    ['IsOnHud']             = {processer = GuideConditionProcesser.ConditionProcesser_IsOnHud,              desc = '{IsOnHud} 是否在主界面'},
    ['IsInCity']            = {processer = GuideConditionProcesser.ConditionProcesser_IsInCity,             desc = '{IsInCity} 是否在城内'},
    ['IsCityHasPet']        = {processer = GuideConditionProcesser.ConditionProcesser_IsCityHasPet,         desc = '{IsCityHasPet} 城内是否有宠物'},
    ['IsRewardRadarTask']   = {processer = GuideConditionProcesser.ConditionProcesser_IsRewardRadarTask,    desc = '{IsRewardRadarTask} 是否有可领奖雷达任务'},
    ['IsHasCreepInCity']    = {processer = GuideConditionProcesser.ConditionProcesser_IsHasCreepInCity,     desc = '{IsHasCreepInCity, X} 城内解锁区域是否有菌毯处于X状态'},
    ['IsAutoFillHp']        = {processer = GuideConditionProcesser.ConditionProcesser_IsAutoFillHp,         desc = '{IsAutoFillHp} 是否开启自动补血'},
    ['IsCarryPet']          = {processer = GuideConditionProcesser.ConditionProcesser_IsCarryPet,           desc = '{IsCarryPet} 编队是否携带宠物'},
    ['IsInAlliance']        = {processer = GuideConditionProcesser.ConditionProcesser_IsInAlliance,         desc = '{IsInAlliance} 玩家是否在联盟中'},
    ['IsAllianceRankAbove'] = {processer = GuideConditionProcesser.ConditionProcesser_IsAllianceRankAbove,  desc = '{IsAllianceRankAbove,rank} 玩家联盟级别大等'},
    ['HasAllianceAuthority']= {processer = GuideConditionProcesser.ConditionProcesser_HasAllianceAuthority, desc = '{HasAllianceAuthority,authority} 玩家是否有联盟权限 number@AllianceAuthorityItem'},
    ['IsHasTypeEquipNum']   = {processer = GuideConditionProcesser.ConditionProcesser_IsHasTypeEquipNum,    desc = '{IsHasTypeEquipNum,type,num} 是否含有指定类型的数量的装备'},
    ['FurnitureType']       = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureType,        desc = '{FurnitureType,type} 是否摆放指定类型的家具'},
    ['FurnitureOwnType']    = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureOwnType,     desc = '{FurnitureOwnType,type} 是否持有指定类型的家具'},
    ['FurnitureProcessEnableCheck']    = {processer = GuideConditionProcesser.ConditionProcesser_FurnitureProcessEnableCheck,     desc = '{FurnitureProcessEnableCheck,recipeId} 是否此家具配方可制造'},
    ['IsRoomUnlocked']      = {processer = GuideConditionProcesser.ConditionProcesser_IsRoomUnlocked,       desc = '{IsRoomUnlocked,roomCfgId} 是否配置Id为roomCfgId房间已解锁'},
    ['IsNpcServiceFinished']= {processer = GuideConditionProcesser.ConditionProcesser_IsNpcServiceFinished, desc = '{npcServiceConfigId} npc服务是否存在且完成'},
    ['HasNpcService']       = {processer = GuideConditionProcesser.ConditionProcesser_HasNpcService,        desc = '{npcServiceConfigId} npc服务是否存在'},
    ['IsNpcServiceStateMatch']={processer = GuideConditionProcesser.ConditionProcesser_IsNpcServiceStateMatch, desc = '{npcServiceConfigId,state} npc服务状态是否为'},
    ['CheckRoomLv']       = {processer = GuideConditionProcesser.ConditionProcesser_CheckRoomLv,             desc = '{CheckRoomLv, roomCfgId, X} 是否配置Id为roomCfgId房间到达X等级'},
    ['IsHasCreepInCityById'] = {processer = GuideConditionProcesser.ConditionProcesser_IsHasCreepInCityById,  desc = '{IsHasCreepInCityById, X} 是否配置Id为X的菌毯还存在'},
    ['HeroStrengthLevel']    = {processer = GuideConditionProcesser.ConditionProcesser_HeroStrengthLevel,     desc = '{HeroStrengthLevel,X} 任意英雄晋升达到X级'},
    ['IsFurnitureLocked']    = {processer = GuideConditionProcesser.ConditionProcesser_IsFurnitureLocked,     desc = '{IsFurnitureLocked,id} 某Id家具是否处于破损状态'},
    ['IsRoomExisted']    = {processer = GuideConditionProcesser.ConditionProcesser_IsRoomExisted,     desc = '{IsRoomExisted,id} 配置为Id的房间是否存在'},
    ['IsFurnitureUpgradeConditionMeet'] = {processer = GuideConditionProcesser.ConditionProcesser_IsFurnitureUpgradeConditionMeet,  desc = '{IsFurnitureUpgradeConditionMeet,lvCfgId} 家具LvCfgId的家具升级条件是否满足'},
    ['IsFurnitureUpgradeUIConditionMeet'] = {processer = GuideConditionProcesser.ConditionProcesser_IsFurnitureUpgradeUIConditionMeet,  desc = '{IsFurnitureUpgradeUIConditionMeet} 当前打开的家具ui界面家具是否满足升级条件'},
    ['IsRadarLevelEqual'] = {processer = GuideConditionProcesser.ConditionProcesser_IsRadarLevelEqual,  desc = '{IsRadarLevelEqual, x} 雷达等级是否为x级'},
    ['HasPetEgg'] = {processer = GuideConditionProcesser.ConditionProcesser_HasPetEgg,  desc = '{IsRadarLevelEqual} 有没有蛋'},

}

--endregion

---@param cmd string @Get from GuideGroupConfigCell:TriggerCmd()
---@param guideCall GuideCallConfigCell
function GuideConditionProcesser:ExeConditionCmd(cmdStr, guideCall)
    if string.IsNullOrEmpty(cmdStr) then return true end
    local stackTop = GuideUtil.SplitCmd(cmdStr,self.cmdStack)
    if stackTop < 1 then
        return false
    end

    local paramStack = CreateStack(guideCall)
    for i = stackTop-1, 0, -1 do
        local cmd = self.cmdStack[i]
        local cmdExecuter = GuideConditionProcesser.Commands[cmd]
        if cmdExecuter == nil then
            StackPush( paramStack,cmd )
        else
            StackPush( paramStack,cmdExecuter.processer(paramStack) )
        end
    end
    if StackCount(paramStack) > 1 then
        g_Logger.ErrorChannel('GuideModule','Params of [%s] is Error',self.cmdStack[0])
        return false
    else
        return  StackPeek(paramStack)
    end
end

return GuideConditionProcesser