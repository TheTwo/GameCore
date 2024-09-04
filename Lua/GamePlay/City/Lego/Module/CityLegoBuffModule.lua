local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityLegoBuffModule:BaseModule
local CityLegoBuffModule = class('CityLegoBuffModule', BaseModule)

function CityLegoBuffModule:OnRegister()
    self.buffTagsMapCache = {}
    self.buffChildrenSetMapCache = {}
    self.emptyRoomCfgIdMap = {}
    for _, buffCfg in ConfigRefer.RoomTagBuff:pairs() do
        local id = buffCfg:Id()
        local tagMap = {}

        for i = 1, buffCfg:RoomTagListLength() do
            local tagId = buffCfg:RoomTagList(i)
            tagMap[tagId] = (tagMap[tagId] or 0) + 1
        end

        self.buffTagsMapCache[id] = tagMap

        local childrenSet = {}
        for i = 1, buffCfg:SubBuffListLength() do
            local subBuffId = buffCfg:SubBuffList(i)
            childrenSet[subBuffId] = true
        end
        self.buffChildrenSetMapCache[id] = childrenSet
    end

    self.mainFurnitureMap = {}
    for _, roomCfg in ConfigRefer.Room:pairs() do
        local mainFurnitureId = roomCfg:MainFurniture()
        if mainFurnitureId ~= 0 then
            local roomSize = roomCfg:Size()
            self.mainFurnitureMap[roomSize] = self.mainFurnitureMap[roomSize] or {}
            self.mainFurnitureMap[roomSize][mainFurnitureId] = roomCfg:Id()
        else
            self.emptyRoomCfgIdMap[roomCfg:Size()] = roomCfg:Id()
        end
    end

    ---@type table<number, table<number, boolean>>
    self.tagFromFurnitureLvMap = {}
    for _, furnitureLvCfg in ConfigRefer.CityFurnitureLevel:pairs() do
        for i = 1, furnitureLvCfg:RoomTagsLength() do
            local tag = furnitureLvCfg:RoomTags(i)
            self.tagFromFurnitureLvMap[tag] = self.tagFromFurnitureLvMap[tag] or {}
            self.tagFromFurnitureLvMap[tag][furnitureLvCfg:Id()] = true
        end
    end
end

function CityLegoBuffModule:IsMainFurnitureOfSize(furTypeCfgId, roomSize)
    self.mainFurnitureMap[roomSize] = self.mainFurnitureMap[roomSize] or {}
    return self.mainFurnitureMap[roomSize][furTypeCfgId] ~= nil
end

function CityLegoBuffModule:GetMainFurnitureToRoomCfgId(furTypeCfgId, roomSize)
    self.mainFurnitureMap[roomSize] = self.mainFurnitureMap[roomSize] or {}
    local roomCfgId = self.mainFurnitureMap[roomSize][furTypeCfgId]
    if roomCfgId == nil then
        return 0
    end
    return roomCfgId
end

function CityLegoBuffModule:GetEmptyRoomCfgIdBySize(size)
    return self.emptyRoomCfgIdMap[size] or 0
end

function CityLegoBuffModule:OnRemove()
    self.buffTagsMapCache = nil
    self.mainFurnitureMap = nil
    self.emptyRoomCfgIdMap = nil
    self.buffChildrenSetMapCache = nil
    self.tagFromFurnitureLvMap = nil
end

function CityLegoBuffModule:GetTagCountMapFromArray(tagArray)
    local tagCountMap = {}
    for i, tagId in ipairs(tagArray) do
        tagCountMap[tagId] = (tagCountMap[tagId] or 0) + 1
    end
    return tagCountMap
end

function CityLegoBuffModule:IsBuffActive(buffId, tagArray)
    local tagCountMap = self:GetTagCountMapFromArray(tagArray)
    return self:IsBuffActiveInTagCountMap(buffId, tagCountMap)
end

function CityLegoBuffModule:IsBuffActiveInTagCountMap(buffId, tagCountMap)
    if not self.buffTagsMapCache[buffId] then return end
    for tagId, needCount in pairs(self.buffTagsMapCache[buffId]) do
        if not tagCountMap[tagId] or tagCountMap[tagId] < needCount then
            return false
        end
    end

    return true
end

---@param roomLevelCfg RoomLevelInfoConfigCell
---@param tagArray number[]
---@return RoomTagBuffConfigCell[] 有序列表
function CityLegoBuffModule:GetActiveBuffOrderList(roomLevelCfg, tagArray)
    local ret = {}
    local tagCountMap = self:GetTagCountMapFromArray(tagArray)
    for i = 1, roomLevelCfg:RoomTagBuffsLength() do
        local buffId = roomLevelCfg:RoomTagBuffs(i)
        local buffCfg = ConfigRefer.RoomTagBuff:Find(buffId)
        if self:IsBuffActiveInTagCountMap(buffId, tagCountMap) then
            table.insert(ret, buffCfg)
        end
    end

    table.sort(ret, Delegate.GetOrCreate(self, self.OrderBuffCfg))
    return ret
end

---@param a RoomTagBuffConfigCell
---@param b RoomTagBuffConfigCell
function CityLegoBuffModule:OrderBuffCfg(a, b)
    if a:Priority() ~= b:Priority() then
        return a:Priority() > b:Priority()
    end
    return a:Id() > b:Id()
end

function CityLegoBuffModule:IsSubBuffOf(subBuffId, buffId)
    return self.buffChildrenSetMapCache[buffId] and self.buffChildrenSetMapCache[buffId][subBuffId] == true
end

function CityLegoBuffModule:GetLevelCfgByAddFurniture(legoBuilding, lvCfg)
    local roomCfgId = legoBuilding.roomCfgId
    local dumpRoomCfg = ConfigRefer.Room:Find(roomCfgId)
    --- 如果房间没有主家具，且放进来的是一个主家具，且Size匹配，则房间会形成新的样式
    if legoBuilding.payload.MainFurnitureId == 0 and self:IsMainFurnitureOfSize(lvCfg:Type(), dumpRoomCfg:Size()) then
        roomCfgId = self.mainFurnitureMap[dumpRoomCfg:Size()][lvCfg:Type()]
    end
    local roomCfg = ConfigRefer.Room:Find(roomCfgId)

    --- 根据最新的得分和任务完成情况推算出目标等级
    ---@type RoomLevelInfoConfigCell
    local targetLvCfg = nil
    local finalScore = legoBuilding.payload.Score + lvCfg:AddScore()
    for i = 1, roomCfg:LevelInfosLength() do
        local lvCfgId = roomCfg:LevelInfos(i)
        if lvCfgId == 0 then goto continue end

        local lvCfg = ConfigRefer.RoomLevelInfo:Find(lvCfgId)
        if targetLvCfg == nil and lvCfg:Score() <= finalScore and self:LevelUpConditionSatisfied(lvCfg) then
            targetLvCfg = lvCfg
        elseif targetLvCfg:Level() < lvCfg:Level() and lvCfg:Score() <= finalScore then
            targetLvCfg = lvCfg
        end
        ::continue::
    end

    if targetLvCfg == nil then
        error("配置问题!")
    end

    return targetLvCfg, roomCfg
end

---@param legoBuilding CityLegoBuilding
---@param lvCfg RoomLevelInfoConfigCell
function CityLegoBuffModule:LevelUpConditionSatisfied(lvCfg)
    for i = 1, lvCfg:LevelUpTaskConditionLength() do
        local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(lvCfg:LevelUpTaskCondition(i))
        local finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
        if not finished then
            return false
        end
    end

    return true
end

---@param legoBuilding CityLegoBuilding
---@param furniture CityFurniture
function CityLegoBuffModule:GetLevelCfgByRemoveFurniture(legoBuilding, furniture)
    local roomCfgId = legoBuilding.roomCfgId
    local dumpRoomCfg = ConfigRefer.Room:Find(roomCfgId)
    --- 如果房间当前的主家具Id和移除的家具Id相同，则房间会形成新的样式
    if legoBuilding.payload.MainFurnitureId == furniture.singleId then
        roomCfgId = self:GetEmptyRoomCfgIdBySize(dumpRoomCfg:Size())
    end
    local roomCfg = ConfigRefer.Room:Find(roomCfgId)

    --- 根据最新的得分推算出目标等级
    ---@type RoomLevelInfoConfigCell
    local targetLvCfg = nil
    local finalScore = legoBuilding.payload.Score - furniture.furnitureCell:AddScore()
    for i = 1, roomCfg:LevelInfosLength() do
        local lvCfgId = roomCfg:LevelInfos(i)
        if lvCfgId == 0 then goto continue end

        local lvCfg = ConfigRefer.RoomLevelInfo:Find(lvCfgId)
        if targetLvCfg == nil and lvCfg:Score() <= finalScore then
            targetLvCfg = lvCfg
        elseif targetLvCfg:Level() < lvCfg:Level() and lvCfg:Score() <= finalScore then
            targetLvCfg = lvCfg
        end
        ::continue::
    end

    if targetLvCfg == nil then
        error("配置问题!")
    end

    return targetLvCfg, roomCfg
end

---@param legoBuilding CityLegoBuilding
---@param lvCfg CityFurnitureLevelConfigCell
---@return RoomTagBuffConfigCell[], RoomLevelInfoConfigCell
function CityLegoBuffModule:GetNewBuffCfgListByAddFurniture(legoBuilding, lvCfg)
    local targetLvCfg, roomCfg = self:GetLevelCfgByAddFurniture(legoBuilding, lvCfg)
    local city = legoBuilding.city
    local activeTags = {}
    --- 收集室内已存在的家具的bufftag
    for _, v in ipairs(legoBuilding.payload.InnerFurnitureIds) do
        local furniture = city.furnitureManager:GetFurnitureById(v)
        if furniture then
            for i = 1, furniture.furnitureCell:RoomTagsLength() do
                table.insert(activeTags, furniture.furnitureCell:RoomTags(i))
            end
        end
    end

    --- 收集预放入的新家具的bufftag
    for i = 1, lvCfg:RoomTagsLength() do
        table.insert(activeTags, lvCfg:RoomTags(i))
    end

    --- 收集目标等级的bufftag
    local newActiveBuffArray = self:GetActiveBuffOrderList(targetLvCfg, activeTags)
        
    --- 只处理自动激活的
    for i = #newActiveBuffArray, 1, -1 do
        local buffCfg = newActiveBuffArray[i]
        if not buffCfg:AutoActive() then
            table.remove(newActiveBuffArray, i)
        end
    end

    --- 缓存一个当前使用的buff列表, 在新的自动激活buff列表中用于检查替换
    local currentActiveBuffMap = {}
    local currentActiveBuffCount = legoBuilding.payload.BuffList:Count()
    local maxActiveCount = roomCfg:BuffCount()
    for _, v in ipairs(legoBuilding.payload.BuffList) do
        currentActiveBuffMap[v] = true
    end

    local newActiveCount = #newActiveBuffArray
    for i = 1, newActiveCount do
        local newActiveBuffCfg = newActiveBuffArray[i]
        local newActiveBuffCfgId = newActiveBuffCfg:Id()
        local replaced = false
        for _, existedBuffId in ipairs(legoBuilding.payload.BuffList) do
            --- 如果是一个已经存在的buff, 则不需要再添加
            if existedBuffId == newActiveBuffCfgId then
                replaced = true
                break
            end

            --- 如果当前拥有一个激活Buff的子Buff，则上位替代它
            if ModuleRefer.CityLegoBuffModule:IsSubBuffOf(existedBuffId, newActiveBuffCfgId) then
                currentActiveBuffMap[existedBuffId] = nil
                currentActiveBuffMap[newActiveBuffCfgId] = true
                replaced = true
                break
            end
        end

        --- 没有替换且还有空格则添加为新的
        if not replaced and currentActiveBuffCount < maxActiveCount then
            currentActiveBuffMap[newActiveBuffCfgId] = true
            currentActiveBuffCount = currentActiveBuffCount + 1
        end
    end

    local currentActiveBuffCfgArray = {}
    for buffId, _ in pairs(currentActiveBuffMap) do
        table.insert(currentActiveBuffCfgArray, ConfigRefer.RoomTagBuff:Find(buffId))
    end

    table.sort(currentActiveBuffCfgArray, Delegate.GetOrCreate(self, self.OrderBuffCfg))
    return currentActiveBuffCfgArray, targetLvCfg
end

---@return table<number, boolean> @key为家具Lv表Id
function CityLegoBuffModule:GetFurnitureLvCfgMapFromBuffTag(tagId)
    return self.tagFromFurnitureLvMap[tagId] or {}
end

return CityLegoBuffModule