local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require("I18N")
local NotificationType = require("NotificationType")
local ConfigTimeUtility = require("ConfigTimeUtility")
local FurnitureCategory = require("FurnitureCategory")
local FunctionClass = require("FunctionClass")

---@class CityConstructionModule:BaseModule
---@field lastCategory number|nil
---@field isNewMap table<number, BuildingTypesConfigCell>
local CityConstructionModule = class('CityConstructionModule', BaseModule)
local CityConstructState = require("CityConstructState")
local CastleUpdateBuildingRedDotParameter = require("CastleUpdateBuildingRedDotParameter")

function CityConstructionModule:OnRegister()
    self.lastCategory = nil
    self.notifyRootName = "CityConstruction_Root"
    self.notifyBuildingTagName = "CityConstruction_Tag_Buliding"
    self.notifyFurnitureName = "CityConstruction_Tag_Furniture"
    self.notifyTowerName = "CityConstruction_Tag_Tower"
    self.notifyDecorationName = "CityConstruction_Tag_Decoration"
    self.notifyRoomName = "CityConstruction_Tag_Room"
end

function CityConstructionModule:OnRemove()
    self.lastCategory = nil
    self.isNewMap = nil
end

---@param typ number BuildingType枚举
---@param level number|nil 默认值为1
---@return BuildingLevelConfigCell|nil
function CityConstructionModule:GetBuildingLevelConfigCellByTypeId(typ, level)
    local typeCell = ConfigRefer.BuildingTypes:Find(typ)
    if typeCell == nil then
        g_Logger.Error(("没有%d 对应的BuildingType配置"):format(typ))
        return nil
    end

    return self:GetBuildingLevelConfigCell(typeCell, level)
end

---@param cell BuildingTypesConfigCell
---@param level number|nil 默认值为1
---@return BuildingLevelConfigCell|nil
function CityConstructionModule:GetBuildingLevelConfigCell(cell, level)
    level = level or 1
    if cell:LevelCfgIdListLength() < level then
        g_Logger.Error(("[表:building_type, id:%d]最高等级为%d, 找不到当前查询等级%d的对应表格"):format(cell:Id(), cell:LevelCfgIdListLength(), level))
        return nil
    end

    local lvConfigCell = ConfigRefer.BuildingLevel:Find(cell:LevelCfgIdList(level))
    if lvConfigCell == nil then
        g_Logger.Error(("%s Lv.%d 的Id在building_level表中不存在"):format(cell:Name(), level))
        return nil
    end

    return lvConfigCell
end

---@param typCell BuildingTypesConfigCell
---@param level number|nil 默认为1
function CityConstructionModule:IsTypeShowConditionMeet(typCell, level)
    level = level or 1
    local lvCell = self:GetBuildingLevelConfigCell(typCell, level)
    if lvCell == nil then
        return false
    end

    return self:IsShowConditionMeet(lvCell)
end

---@param lvCell BuildingLevelConfigCell
---@return boolean 是否配方显示条件满足
function CityConstructionModule:IsShowConditionMeet(lvCell)
    for i = 1, lvCell:ShowPreconditionListLength() do
        local info = lvCell:ShowPreconditionList(i)
        if not self:HasTargetLevelBuilding(info:BuildingType(), info:Level(), info:Count()) then
            return false
        end
    end
    return true
end

---@param typCell BuildingTypesConfigCell
---@param level number|nil 默认为1
function CityConstructionModule:IsTypePreconditionMeet(typCell, level)
    level = level or 1
    local lvCell = self:GetBuildingLevelConfigCell(typCell, level)
    if lvCell == nil then
        return false
    end

    return self:IsPreconditionMeet(lvCell)
end

---@param lvCell BuildingLevelConfigCell
---@return boolean 是否前置条件满足
function CityConstructionModule:IsPreconditionMeet(lvCell)
    for i = 1, lvCell:LvUpPreconditionLength() do
        local taskId = lvCell:LvUpPrecondition(i)
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        local isFinish = taskState == wds.TaskState.TaskStateFinished
        if not isFinish then
           return false
        end
    end
    return true
end

---@param lvCell BuildingLevelConfigCell
---@return boolean 是否有足够的材料
function CityConstructionModule:IsCostMeet(lvCell)
    local costId = lvCell:CostItemGroupCfgId()
    if costId ~= 0 then
        local costGroup = ConfigRefer.ItemGroup:Find(costId)
        if costGroup ~= nil then
            for i = 1, costGroup:ItemGroupInfoListLength() do
                local itemCell = costGroup:ItemGroupInfoList(i)
                if not ModuleRefer.InventoryModule:IsEnoughByConfigId(itemCell:Items(), itemCell:Nums()) then
                    return false
                end
            end
        end
    end

    return true
end

---@return {id:number, num:number}[]
function CityConstructionModule:GetLackResourceMap(lvCell)
    local ret = {}
    local costId = lvCell:CostItemGroupCfgId()
    if costId ~= 0 then
        local costGroup = ConfigRefer.ItemGroup:Find(costId)
        if costGroup ~= nil then
            for i = 1, costGroup:ItemGroupInfoListLength() do
                local itemCell = costGroup:ItemGroupInfoList(i)
                local itemId = itemCell:Items()
                local need = itemCell:Nums()
                if not ModuleRefer.InventoryModule:IsEnoughByConfigId(itemId, need) then
                    table.insert(ret, {id = itemId, num = need - ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)})
                end
            end
        end
    end
    return ret
end

---@param lvCell BuildingLevelConfigCell
---@return boolean 是否场景摆放的建筑数未达到建造上限
function CityConstructionModule:NotFullPlaced(lvCell)
    local typ = lvCell:Type()
    local count = self:GetPlacedBuildingCountByType(typ)
    local typeCell = ConfigRefer.BuildingTypes:Find(typ)
    return count < typeCell:MaxNum()
end

---@param typCell BuildingTypesConfigCell
function CityConstructionModule:NotFullPlacedByType(typCell)
    local count = self:GetPlacedBuildingCountByType(typCell:Id())
    return count < typCell:MaxNum()
end

---@param lvCell BuildingLevelConfigCell
---@return boolean 是否未达到建造上限
function CityConstructionModule:NotFull(lvCell)
    local typ = lvCell:Type()
    local count = #self:GetAllBuildingInfosByType(typ)
    local typeCell = ConfigRefer.BuildingTypes:Find(typ)
    return count < typeCell:MaxNum()
end

---@param cell BuildingTypesConfigCell
---@param level number|nil 默认值为1
---@param isUpgrade boolean|nil 如果是升级，则会跳过数量检查阶段
function CityConstructionModule:GetBuildingTypeState(cell, level, isUpgrade)
    local lvCell = self:GetBuildingLevelConfigCell(cell, level)
    if lvCell == nil then
        return CityConstructState.UnknownBuilding
    end

    return self:GetBuildingLevelState(lvCell, isUpgrade);
end

---@param lvCell BuildingLevelConfigCell
---@param isUpgrade boolean
function CityConstructionModule:GetBuildingLevelState(lvCell, isUpgrade)
    --- 检查出现条件
    if not self:IsShowConditionMeet(lvCell) then
        return CityConstructState.UnknownBuilding
    end

    --- 检查前置条件
    if not self:IsPreconditionMeet(lvCell) then
        return CityConstructState.ConditionNotMeet
    end

    if not isUpgrade then
        --- 检查已建造数量
        if not self:NotFullPlaced(lvCell) then
            return CityConstructState.IsFull
        end
    end

    --- 检查资源需求
    if not self:IsCostMeet(lvCell) then
        return CityConstructState.LackOfResource
    end

    return CityConstructState.CanBuild
end

---@param cell BuildingTypesConfigCell
---@param level number|nil 默认值为1
---@return string 配方显示条件
function CityConstructionModule:GetShowConditionDesc(cell, level)
    local lvConfigCell = self:GetBuildingLevelConfigCell(cell, level)
    if lvConfigCell == nil then
        return string.Empty
    end

    --- 检查前置条件
    local conditions = {}
    for i = 1, lvConfigCell:ShowPreconditionListLength() do
        local info = lvConfigCell:ShowPreconditionList(i)
        if info ~= nil then
            table.insert(conditions, I18N.GetWithParams("build_pre_level", I18N.Get(ConfigRefer.BuildingTypes:Find(info:BuildingType()):Name()), ("Lv.%d"):format(info:Level())))
        end
    end

    return table.concat(conditions, "\n")
end

---@param cell BuildingTypesConfigCell
---@param level number|nil 默认值为1
---@return string 建筑解锁条件
function CityConstructionModule:GetUnlockConditionDesc(cell, level)
    local lvConfigCell = self:GetBuildingLevelConfigCell(cell, level)
    if lvConfigCell == nil then
        return string.Empty
    end

    --- 检查前置条件
    local conditions = {}
    for i = 1, lvConfigCell:LvUpPreconditionLength() do
        local taskId = lvConfigCell:LvUpPrecondition(i)
        local taskName = ModuleRefer.QuestModule:GetTaskNameByID(taskId)
        local conditionDesc = I18N.Get(taskName)
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        local isFinish = taskState == wds.TaskState.TaskStateFinished
        if not isFinish then
            table.insert(conditions, conditionDesc)
        end
    end

    return table.concat(conditions, "\n")
end

---@return wds.CastleBuildingInfo[]
function CityConstructionModule:GetPlacedBuildingCountByType(typ)
    local myCity = ModuleRefer.CityModule:GetMyCity()
    local ret = 0
    local castle = myCity:GetCastle()
    for _, info in pairs(castle.BuildingInfos) do
        if info.BuildingType == typ then
            ret = ret + 1
        end
    end
    return ret
end

---@return wds.CastleBuildingInfo[]
function CityConstructionModule:GetAllBuildingInfosByType(typ)
    local myCity = ModuleRefer.CityModule:GetMyCity()
    local ret = {}
    local castle = myCity:GetCastle()
    for _, info in pairs(castle.BuildingInfos) do
        if info.BuildingType == typ then
            table.insert(ret, info)
        end
    end

    for _, info in pairs(castle.StoredBuildings) do
        if info.BuildingType == typ then
            table.insert(ret, info)
        end
    end

    return ret
end

function CityConstructionModule:HasTargetLevelBuilding(typ, level, count)
    local buildings = self:GetAllBuildingInfosByType(typ)
    if buildings == nil then
        return false
    end

    count = count or 1
    for _, building in ipairs(buildings) do
        if building.Level >= level then
            count = count - 1
            if count == 0 then
                return true
            end
        end
    end
    return false
end

---@return number
function CityConstructionModule:GetFurnitureCountByType(typ)
    local myCity = ModuleRefer.CityModule:GetMyCity()
    local ret = 0
    local furnitures = myCity:GetCastle().CastleFurniture
    for instId, info in pairs(furnitures) do
        local lvCell = ConfigRefer.CityFurnitureLevel:Find(info.ConfigId)
        if lvCell and lvCell:Type() == typ then
            ret = ret + 1
        end
    end
    return ret
end

function CityConstructionModule:GetPlaceBuildingTypeNumLimit(typeId)
    local myCity = ModuleRefer.CityModule:GetMyCity()
    return myCity.buildingManager:GetPlaceTypeNumLimit(typeId)
end

---@param typeId number
function CityConstructionModule:GetPlaceFurnitureTypeNumLimit(typeId)
    local myCity = ModuleRefer.CityModule:GetMyCity()
    return myCity.furnitureManager:GetFurniturePlacedLimitCountByTypeCfgId(typeId)
end

---@param cell BuildingTypesConfigCell
---标记UI层红点可见
function CityConstructionModule:MarkBuildingIsNew(cell)
    local id = cell:Id()
    local node = ModuleRefer.NotificationModule:GetDynamicNode("CityConstruction_BuildingType_"..id, NotificationType.CITY_CONSTRUCTION_BUILDING)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 1)
end

---@param cell BuildingTypesConfigCell
---标记数据层红点消失, 但不立刻更新UI
function CityConstructionModule:ClearBuildingIsNew(cell)
    local id = cell:Id()
    if self.haveReadDots[id] then
        return false
    end

    self.haveReadDots[id] = id
    self.dotsDirty[#self.dotsDirty + 1] = id;
    return true
end

---同步数据层红点变化到UI层, 并通知服务器缓存列表
function CityConstructionModule:RefreshBuildingDotsDirty()
    if #self.dotsDirty == 0 then
        return
    end

    for _, v in pairs(self.dotsDirty) do
        local node = ModuleRefer.NotificationModule:GetDynamicNode("CityConstruction_BuildingType_"..v, NotificationType.CITY_CONSTRUCTION_BUILDING)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 0)
    end
    table.clear(self.dotsDirty)

    local param = CastleUpdateBuildingRedDotParameter.new()
    param.args.Data:AddRange(table.values(self.haveReadDots))
    param:Send()
end

function CityConstructionModule:ClearFurnitureRedDots(category)
    for _, cell in ConfigRefer.CityFurnitureTypes:pairs() do
        if cell:Category() ~= category then goto continue end
        local id = cell:Id()
        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("CityConstruction_FurnitureType_"..id, NotificationType.CITY_CONSTRUCTION_FURNITURE)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 0)
        ::continue::
    end
end

---@param cell BuildingTypesConfigCell
function CityConstructionModule:HasRedDot(cell)
    if cell == nil then
        return false
    end

    local uniqueName = "CityConstruction_BuildingType_"..cell:Id()
    local node = ModuleRefer.NotificationModule:GetDynamicNode(uniqueName, NotificationType.CITY_CONSTRUCTION_BUILDING)
    if node == nil then
        return false
    end
    
    return node.NotificationCount > 0
end

---监听建筑数据变化回调, 标记UI层红点可见
function CityConstructionModule:TryShowNewRedDots()
    local dirty = false
    for _, cell in ConfigRefer.BuildingTypes:pairs() do
        local id = cell:Id()
        if self.haveReadDots[id] then
            goto continue
        end
        if self:NotFullPlacedByType(cell) and self:IsTypeShowConditionMeet(cell) and self:IsTypePreconditionMeet(cell) then
            self:MarkBuildingIsNew(cell)
        elseif self:HasRedDot(cell) then
            dirty = dirty or self:ClearBuildingIsNew(cell)
        end
        ::continue::
    end

    if dirty then
        self:RefreshBuildingDotsDirty()
    end
end

---@param cell BuildingTypesConfigCell
---@param level number|nil 默认值为1
function CityConstructionModule:GetBuildingCostTime(cell, level)
    local lvConfigCell = self:GetBuildingLevelConfigCell(cell, level)
    if lvConfigCell == nil then
        return 0
    end
    return ConfigTimeUtility.NsToSeconds(lvConfigCell:BuildDuration())
end

--------------------------------------sorted list start--------------------------------------------
---@return BuildingTypesConfigCell[], table<BuildingTypesConfigCell, number>
function CityConstructionModule:GetSortedBuildingTypeList()
    local ret, stateMap = {}, {}
    for _, cell in ConfigRefer.BuildingTypes:pairs() do
        if cell:HideInUI() then goto continue end

        local state = ModuleRefer.CityConstructionModule:GetBuildingTypeState(cell)
        stateMap[cell] = state
        table.insert(ret, cell)
        ::continue::
    end

    table.sort(ret, function(x, y)
        if stateMap[x] == stateMap[y] then
            return x:DisplaySort() > y:DisplaySort()
        else
            return stateMap[x] < stateMap[y]
        end
    end)
    return ret, stateMap
end

---@param typeMask number @1-OutDoor;2-InDoor;3-Both
---@return CityFurnitureTypesConfigCell[], table<CityFurnitureTypesConfigCell, table<number, number>>
function CityConstructionModule:GetSortedFurnituresByCategory(category)
    local ret, retMap = {}, {}
    for _, cell in ConfigRefer.CityFurnitureTypes:pairs() do
        if cell:LevelCfgIdListLength() == 0 then
            goto continue
        end

        if cell:HideInConstructionMenu() then
            goto continue
        end

        if cell:Category() ~= category then
            goto continue
        end

        local amountMap = self:GetFurnitureAmountMap(cell)
        table.insert(ret, cell)
        retMap[cell] = amountMap
        ::continue::
    end
    return ret, retMap
end

---@param typId number
---@return table<number, number>
function CityConstructionModule:GetFurnitureAmountMapByTypeId(typId)
    local typeCell = ConfigRefer.CityFurnitureTypes:Find(typId)
    return self:GetFurnitureAmountMap(typeCell)
end

---@param cell CityFurnitureTypesConfigCell
---@return table<number, number>
function CityConstructionModule:GetFurnitureAmountMap(cell)
    local amountMap = {}
    for i = 1, cell:LevelCfgIdListLength() do
        local lvId = cell:LevelCfgIdList(i)
        local lvCell = ConfigRefer.CityFurnitureLevel:Find(lvId)
        local itemId = lvCell:RelItem()
        if itemId == 0 then
            amountMap[i] = 10086
        else
            local amount = ModuleRefer.InventoryModule:GetAmountByConfigId(lvCell:RelItem())
            if amount > 0 then
                amountMap[i] = amount
            end
        end
    end
    return amountMap
end

---@param curLvCell BuildingLevelConfigCell
function CityConstructionModule:GetPreLevelCell(curLvCell)
    local preLv = curLvCell:Level() - 1
    if preLv <= 0 then return nil end
    
    local typCell = ConfigRefer.BuildingTypes:Find(curLvCell:Type())
    return ConfigRefer.BuildingLevel:Find(typCell:LevelCfgIdList(preLv))
end

--------------------------------------furniture start--------------------------------------------
function CityConstructionModule:GetAllFurnitureConfig()
    local config = ConfigRefer.CityFurnitureTypes
    local ret = {}
    for _, v in config:pairs() do
        if v:Type() and v:DisplaySort() > 0 then
            table.insert(ret, v)
        end
    end
    return ret
end

---@return CityFurnitureLevelConfigCell
function CityConstructionModule:GetFurnitureLevelCell(typId, level)
    level = level or 1
    local typCell = ConfigRefer.CityFurnitureTypes:Find(typId)
    if typCell:LevelCfgIdListLength() < level then
        return nil
    end

    local levelConfigCell = ConfigRefer.CityFurnitureLevel:Find(typCell:LevelCfgIdList(level))
    if levelConfigCell == nil then
        return nil
    end
    return levelConfigCell
end

function CityConstructionModule:GetFurnitureTypeById(levelId)
    local type = ConfigRefer.CityFurnitureLevel:Find(levelId):Type()
    return ConfigRefer.CityFurnitureTypes:Find(type):Type()
end

function CityConstructionModule:GetFurnitureCategory(levelId)
    local type = ConfigRefer.CityFurnitureLevel:Find(levelId):Type()
    return ConfigRefer.CityFurnitureTypes:Find(type):Category()
end

--------------------------------------furniture end--------------------------------------------

function CityConstructionModule:IsFurnitureRelativeItem(itemId)
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if not itemCfg then return false end

    return itemCfg:FunctionClass() == FunctionClass.AddFurnitureCount and itemCfg:UseParamLength() >= 1
end

---@return number @家具LvCfg-Id
function CityConstructionModule:GetFurnitureRelative(itemId)
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if not itemCfg then return 0 end

    if itemCfg:FunctionClass() == FunctionClass.AddFurnitureCount and itemCfg:UseParamLength() >= 1 then
        return tonumber(itemCfg:UseParam(1))
    end
    return 0
end

--------------------------------------item cache end--------------------------------------

return CityConstructionModule