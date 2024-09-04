---@class CityBuilding
---@field new fun(mgr:CityBuildingManager, id:number, info:wds.CastleBuildingInfo):CityBuilding
---@field repairBlocks table<number, CityBuildingRepairBlock>
---@field rooms table<number, CityRoom>
---@field doors table<number, CityDoor>
local CityBuilding = sealedClass("CityBuilding")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local CityNode = require("CityNode")
local CityGridCellDef = require("CityGridCellDef")
local CityBuildingRepairBlock = require("CityBuildingRepairBlock")
local EventConst = require("EventConst")
local RectDyadicMap = require("RectDyadicMap")
local CityRoom = require("CityRoom")
local CityWall = require("CityWall")
local CityWallSide = require("CityWallSide")
local CityDoor = require("CityDoor")
local I18N = require("I18N")
local CityWallOrDoorNavmeshDatum = require("CityWallOrDoorNavmeshDatum")
local Delegate = require("Delegate")
local Utils = require("Utils")
local CastleBuildingStatus = wds.enum.CastleBuildingStatus

---@param mgr CityBuildingManager
---@param id number
---@param buildingInfo wds.CastleBuildingInfo
---@param roomWallInfo wds.BuildingIndoorInfo
function CityBuilding:ctor(mgr, id, buildingInfo, roomWallInfo)
    self.id = id
    self.mgr = mgr
    self.repairBlocks = {}
    self.rooms = {}
    self.doors = {}

    self.originWallRow = {}
    self.originWallColumn = {}
    self.battleState = false

    --- 使用gridConfig的大小是因为建筑存在扩容问题, 如果使用建筑当前的室内空间大小作为RectDyadicMap的RectSize, 会有扩容问题
    local gridConfig = self.mgr.city.gridConfig
    --- 顶部和底部不会存在墙体,但是计数从0开始,因此横着的墙总共sizeY+1行, 每行sizeX个, X:第几行(从0开始),Y:第几个(从0开始)
    self.wallH = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY + 1)
    --- 竖着的墙同理, 总共sizeX+1列, 每列sizeY个, X:第几列(从0开始),Y:第几个(从0开始)
    self.wallV = RectDyadicMap.new(gridConfig.cellsY, gridConfig.cellsX + 1)

    self:UpdateBuildingInfo(buildingInfo)
    self:CollectRoomInnerWall(roomWallInfo)
end

function CityBuilding:Release()
    for id, door in pairs(self.doors) do
        door:OnDestroy()
    end
    self.battleState = false
end

---@param info wds.CastleBuildingInfo
function CityBuilding:UpdateBuildingInfo(info)
    local delay = self:FeedInfo(info)
    self.x = info.Pos.X
    self.y = info.Pos.Y
    local lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCellByTypeId(info.BuildingType, info.Level)
    local sizeChange = self:UpdateSize(lvCell:SizeX(), lvCell:SizeY())
    self:CollectRepairBlocks()
    self:CommonPost()
    return delay, sizeChange
end

---@param info wds.CastleBuildingInfo
function CityBuilding:FeedInfo(info)
    local oldInfo = self.info
    local newInfo = info
    local delay = 0
    self.info = info
    if oldInfo ~= nil then
        if oldInfo.Level ~= newInfo.Level then
            ModuleRefer.CityConstructionModule:TryShowNewRedDots()
        end
        if oldInfo.Status ~= newInfo.Status and newInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Normal then
            if newInfo.Level > 1 then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_STATUS_TO_NORMAL, self)
            end
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_DIRTY_FOR_UPGRADE, self.id)
        end

        if oldInfo.Status ~= newInfo.Status and CityUtils.IsStatusWaitRibbonCutting(newInfo.Status) then
            delay = 0.8
        end
        
        if oldInfo.Polluted ~= newInfo.Polluted then
            if newInfo.Polluted then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_POLLUTED_IN, self.id)
            else
                g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_POLLUTED_OUT, self.id)
            end
        end
    end
    return delay
end

function CityBuilding:UpdateSize(newSizeX, newSizeY)
    local ret = self.sizeX ~= newSizeX or self.sizeY ~= newSizeY
    self.sizeX, self.sizeY = newSizeX, newSizeY
    return ret
end

function CityBuilding:CollectRepairBlocks()
    for k, v in pairs(self.repairBlocks) do
        if not self.info.RepairInfo[k] then
            self:RemoveRepairBlock(k)
        end
    end

    for id, v in pairs(self.info.RepairInfo) do
        if not self.repairBlocks[id] then
            self.repairBlocks[id] = CityBuildingRepairBlock.new(self, id, v)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_CREATE, self, id)
        else
            self.repairBlocks[id]:UpdateInfo(v)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_UPDATE, self, id)
        end
    end
end

---@private
function CityBuilding:RemoveRepairBlock(id)
    self.repairBlocks[id] = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_REMOVE, self, id)
end

function CityBuilding:GetRepairBlockByCfgId(id)
    return self.repairBlocks[id]
end

---@param wallRoomInfo wds.BuildingIndoorInfo
function CityBuilding:CollectRoomInnerWall(wallRoomInfo)
    if not wallRoomInfo then return end

    for id, info in pairs(wallRoomInfo.Rooms) do
        local room = CityRoom.new(id, info, self)
        self.rooms[id] = room
    end

    local wallDB = wallRoomInfo.Walls
    for x, lineInfo in pairs(wallDB) do
        for y, rowAndCol in pairs(lineInfo.Data) do
            local colCfgId = rowAndCol & 0xFFFF
            if colCfgId ~= 0 then
                self.wallV:Add(x, y, CityWall.new(x, y, false, colCfgId, self))
            end
            local rowCfgId = (rowAndCol >> 16) & 0xFFFF
            if rowCfgId ~= 0 then
                self.wallH:Add(y, x, CityWall.new(y, x, true, rowCfgId, self))
            end
        end
    end

    local doorDB = wallRoomInfo.Doors
    for k, v in pairs(doorDB) do
        local door
        if v.Vertical then
            local idx, number = v.X, v.Y
            door = CityDoor.new(idx, number, v.Len, v.ConfigId, false, self)
            for i = 0, v.Len - 1 do
                self.wallV:Add(idx, number + i, door)
            end
        else
            local idx, number = v.Y, v.X
            door = CityDoor.new(idx, number, v.Len, v.ConfigId, true, self)
            for i = 0, v.Len - 1 do
                self.wallH:Add(idx, number + i, door)
            end
        end
        self.doors[k] = door
        door:OnCreated()
    end

    for _, room in pairs(self.rooms) do
        room:CollectTileBelongsSelf()
        room:CollectRelativeWalls()
    end

    self:RoomReachable()
end

---@return wds.BuildingIndoorInfo
function CityBuilding:GetRoomInfo()
    return self.mgr:GetRoomInfo(self.id)
end

---@return boolean 是否通用处理过
function CityBuilding:CommonPost()
    local info = self:GetRoomInfo()
    if info == nil then return true end
    if info.DirtyRooms:Count() > 0 then
        self:FixDirtyRooms(info)
        return true
    end
    return false
end

function CityBuilding:PostAddDoor(doorId)
    if self:CommonPost() then return end

    local door = self.doors[doorId]
    local x, y = door:LocalX(), door:LocalY()
    for _, v in pairs(self.rooms) do
        if v:ContainsTile(x, y) then
            v:AddRelativeWall(door, CityWallSide.Both)
            break
        end
    end
    self:RoomReachable()
end

---@param door CityDoor
function CityBuilding:PostRemoveDoor(door)
    if self:CommonPost() then return end

    local x, y = door:LocalX(), door:LocalY()
    for _, v in pairs(self.rooms) do
        if v:ContainsTile(x, y) then
            v:RemoveRelativeWall(door)
            break
        end
    end
    self:RoomReachable()
end

---@param RowPos wds.Point2[]
---@param ColumnPos wds.Point2[]
function CityBuilding:PostAddWalls(RowPos, ColumnPos)
    if self:CommonPost() then return end

    for _, v in ipairs(RowPos) do
        if not v then goto continue end

        local wall = self.wallH:Get(v.Y, v.X)
        for _, room in pairs(self.rooms) do
            if room:ContainsTile(v.X, v.Y) then
                room:AddRelativeWall(wall, CityWallSide.Both)
                break
            end
        end
        ::continue::
    end

    for _, v in ipairs(ColumnPos) do
        if not v then goto continue end

        local wall = self.wallV:Get(v.X, v.Y)
        for _, room in pairs(self.rooms) do
            if room:ContainsTile(v.X, v.Y) then
                room:AddRelativeWall(wall, CityWallSide.Both)
                break
            end
        end

        ::continue::
    end
end

---@param walls CityWall[]
function CityBuilding:PostRemoveWalls(walls)
    if self:CommonPost() then return end
    
    for _, v in ipairs(walls) do
        local x, y = v:LocalX(), v:LocalY()
        for _, room in pairs(self.rooms) do
            if room:ContainsTile(x, y) then
                room:RemoveRelativeWall(v)
                break
            end
        end
    end
end

---@param wallRoomInfo wds.BuildingIndoorInfo
function CityBuilding:FixDirtyRooms(wallRoomInfo)
    for _, roomId in ipairs(wallRoomInfo.DirtyRooms) do
        if self.rooms[roomId] and not wallRoomInfo.Rooms[roomId] then
            self.rooms[roomId] = nil
        elseif not self.rooms[roomId] and wallRoomInfo.Rooms[roomId] then
            local roomInfo = wallRoomInfo.Rooms[roomId]
            self.rooms[roomId] = CityRoom.new(roomId, roomInfo, self)
        end

        if self.rooms[roomId] then
            self.rooms[roomId]:CollectTileBelongsSelf()
            self.rooms[roomId]:CollectRelativeWalls()
        end
    end
    self:RoomReachable()
end

function CityBuilding:GetWorldVWallOrDoor(worldIdx, worldNumber)
    local localIdx = worldIdx - self.x
    local localNumber = worldNumber - self.y
    return self:GetInnerVWallOrDoor(localIdx, localNumber)
end

function CityBuilding:GetWorldHWallOrDoor(worldIdx, worldNumber)
    local localIdx = worldIdx - self.y
    local localNumber = worldNumber - self.x
    return self:GetInnerHWallOrDoor(localIdx, localNumber)
end

---@return CityWall|CityDoor
function CityBuilding:GetInnerVWallOrDoor(idx, number)
    return self.wallV:Get(idx, number)
end

function CityBuilding:HasInnerVWallOrDoor(idx, number)
    return self:GetInnerVWallOrDoor(idx, number) ~= nil
end

function CityBuilding:HasInnerVWall(idx, number)
    local inst = self:GetInnerVWallOrDoor(idx, number)
    return inst and inst:IsWall()
end

---@return CityWall|CityDoor
function CityBuilding:GetInnerHWallOrDoor(idx, number)
    return self.wallH:Get(idx, number)
end

function CityBuilding:HasInnerHWallOrDoor(idx, number)
    return self:GetInnerHWallOrDoor(idx, number) ~= nil
end

function CityBuilding:HasInnerHWall(idx, number)
    local inst = self:GetInnerHWallOrDoor(idx, number)
    return inst and inst:IsWall()
end

function CityBuilding:PlaceWallLocalAtInConfig(x, y)
    local lvCell = self:GetLevelCellConfig()
    if lvCell == nil then return false end

    local startX, startY = lvCell:InnerPos():X(), lvCell:InnerPos():Y()
    local sizeX, sizeY = lvCell:InnerSizeX(), lvCell:InnerSizeY()
    return startX < x and x < startX + sizeX and startY < y and y < startY + sizeY
end

function CityBuilding:AddNewDoor(id, idx, number, isHorizontal, cfgId)
    local cfg = ConfigRefer.BuildingRoomDoor:Find(cfgId)
    if cfg == nil then return end

    local map = isHorizontal and self.wallH or self.wallV
    local door = CityDoor.new(idx, number, cfg:Length(), cfgId, isHorizontal, self)
    for i = 0, cfg:Length() - 1 do
        if not map:TryAdd(idx, number + i, door) then
            g_Logger.Error("建筑内门，前后端数据不一致")
        end
    end
    self.doors[id] = door
    door:OnCreated()
end

function CityBuilding:RemoveDoor(id)
    local door = self.doors[id]
    if not door then return end

    local map = door.isHorizontal and self.wallH or self.wallV
    for i = 0, door.length - 1 do
        if not map:Delete(door.idx, door.number + i) then
            g_Logger.Error("建筑内门，前后端数据不一致")
        end
    end
    self.doors[id] = nil
    door:OnDestroy()
    return door
end

function CityBuilding:AddNewWall(idx, number, isHorizontal, cfgId)
    local map = isHorizontal and self.wallH or self.wallV
    local wall = CityWall.new(idx, number, isHorizontal, cfgId, self)
    if not map:TryAdd(idx, number, wall) then
        g_Logger.Error("建筑内墙，前后端数据不一致")
    end
end

function CityBuilding:RemoveWall(idx, number, isHorizontal)
    local map = isHorizontal and self.wallH or self.wallV
    local dump = map:Delete(idx, number)
    if not dump then
        g_Logger.Error("建筑内墙，前后端数据不一致")
    end
    return dump
end

function CityBuilding:RoomReachable()
    if table.nums(self.rooms) == 0 then
        return
    end

    for k, v in pairs(self.rooms) do
        v:ClearConnectionAndReachable()
    end

    local coords = self:GetInnerSpaceDoorCoords()
    if #coords == 0 then
        return
    end

    local entryRooms = self:GetEntryRoomsByCoords(coords)
    if #entryRooms == 0 then
        g_Logger.Error(("建筑Id:[%d], Type:[%d], Level:[%d]配置的室内入口无法连通到任何一个房间"):format(self.id, self.info.BuildingType, self.info.Level))
        return
    end

    for k, v in pairs(self.doors) do
        if v.isHorizontal then
            local x, y = v.number, v.idx
            self:ConnectRoom(x, y, x, y-1)
        else
            local x, y = v.idx, v.number
            self:ConnectRoom(x, y, x-1, y)
        end
    end

    for i, v in ipairs(entryRooms) do
        self:MarkReachable(v)
    end
end

---@param room CityRoom
function CityBuilding:MarkReachable(room)
    if room.reachable then return end

    room.reachable = true
    for _, v in pairs(room.connections) do
        self:MarkReachable(v)
    end
end

function CityBuilding:GetRoomByCoord(x, y)
    for k, v in pairs(self.rooms) do
        if v.areas:Contains(x, y) then
            return v
        end
    end
end

---@param coords {x:number,y:number}[]
function CityBuilding:GetEntryRoomsByCoords(coords)
    local ret = {}
    for i, v in ipairs(coords) do
        local room = self:GetRoomByCoord(v.x, v.y)
        if room then
            table.insert(ret, room)
        end
    end
    return ret
end

function CityBuilding:ConnectRoom(x1, y1, x2, y2)
    local room1 = self:GetRoomByCoord(x1, y1)
    local room2 = self:GetRoomByCoord(x2, y2)
    room1:ConnectRoom(room2)
    room2:ConnectRoom(room1)
end

---@return boolean @1级未剪彩建筑不会有室内空间
function CityBuilding:IsLevel1_And_NotNormal()
    local level = self.info.Level
    return level == 1 and not CityUtils.IsStatusReady(self.info.Status)
end

function CityBuilding:GetLevelCellConfig(ignoreStatus)
    local level = self.info.Level
    if not ignoreStatus and not CityUtils.IsStatusReady(self.info.Status) then
        level = level - 1
    end
    local typeCfg = ConfigRefer.BuildingTypes:Find(self.info.BuildingType)
    return ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCell(typeCfg, level)
end

---@return {x:number,y:number}[]
function CityBuilding:GetInnerSpaceDoorCoords()
    local ret = {}
    local lvCfg = self:GetLevelCellConfig()
    local length = lvCfg:InnerEntryLength()
    if length == 0 then return ret end

    local roomInfo = self:GetRoomInfo()
    local x = roomInfo.X + lvCfg:InnerEntryPos():X()
    local y = roomInfo.Y + lvCfg:InnerEntryPos():Y()
    local isVertical = lvCfg:InnerEntryVertical()

    for i = 0, length - 1 do
        if isVertical then
            table.insert(ret, {x = x, y = y+i})
        else
            table.insert(ret, {x = x+i, y = y})
        end
    end
    return ret
end

function CityBuilding:GetName()
    local typCfg = ConfigRefer.BuildingTypes:Find(self.info.BuildingType)
    return I18N.Get(typCfg:Name())
end

function CityBuilding:GetCurrentLevel()
    return self.info.Level
end

function CityBuilding:IsUpgradingProcessing()
    return self.info.Status == wds.enum.CastleBuildingStatus.CastleBuildingStatus_Upgrading
end

function CityBuilding:IsUpgradeSuspend()
    return self.info.Status == wds.enum.CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
end

function CityBuilding:GetUpgradeRemainSeconds()
    if self:IsUpgradeSuspend() then
        local typeCfg = ConfigRefer.BuildingTypes:Find(self.info.BuildingType)
        local duration = ModuleRefer.CityConstructionModule:GetBuildingCostTime(typeCfg, self:GetCurrentLevel() + 1)
        return duration - self.info.Progress
    else
        return 0
    end
end

function CityBuilding:Contains(x, y)
    return self.x <= x and x < self.x + self.sizeX and self.y <= y and y < self.y + self.sizeY
end

function CityBuilding:ToCityNode()
    local levelCell = self:GetLevelCellConfig(true)
    if levelCell == nil then
        g_Logger.Error(("旧数据残留, 找不到类型为%d的建筑配置"):format(self.info.BuildingType))
        return nil
    end
    local sizeX, sizeY = levelCell:SizeX(), levelCell:SizeY()
    local isUpgrade = CityUtils.IsStatusUpgrade(self.info.Status)
    if isUpgrade then
        local nextLevel = ConfigRefer.BuildingLevel:Find(levelCell:NextLevel())
        sizeX, sizeY = nextLevel:SizeX(), nextLevel:SizeY()
    end
    return CityNode.Temp(self.info.Pos.X, self.info.Pos.Y, sizeX, sizeY, self.id, levelCell:Id(), CityGridCellDef.ConfigType.BUILDING)
end

---@return CityWallOrDoorNavmeshDatum[]
function CityBuilding:GenerateRoomNavmeshData()
    if not self.navmeshData then
        self.navmeshData = {}
    else
        table.clear(self.navmeshData)
    end

    if self:IsLevel1_And_NotNormal() then
        return self.navmeshData
    end

    local lvCell = self:GetLevelCellConfig()
    if lvCell == nil then
        g_Logger.Error("找不到配置")
        return self.navmeshData
    end

    local roomInfo = self:GetRoomInfo()
    if roomInfo == nil then
        return self.navmeshData
    end

    local InnerSizeX, InnerSizeY = roomInfo.Width, roomInfo.Height
    if InnerSizeX == 0 or InnerSizeY == 0 then
        return self.navmeshData
    end

    local InnerEntryPos = lvCell:InnerEntryPos()
    local InnerEntryPosX, InnerEntryPosY = InnerEntryPos:X(), InnerEntryPos:Y()
    local InnerEntryLength, InnerEntryVertical = lvCell:InnerEntryLength(), lvCell:InnerEntryVertical()

    local StartX, StartY = self.x + roomInfo.X, self.y + roomInfo.Y
    local EndX, EndY = StartX + InnerSizeX, StartY + InnerSizeY
    local entryDoor = CityWallOrDoorNavmeshDatum.new(StartX + InnerEntryPosX, StartY + InnerEntryPosY, InnerEntryLength, InnerEntryVertical, true, "入口门")
    if InnerEntryLength > 0 then
        table.insert(self.navmeshData, entryDoor)
    end

    if not InnerEntryVertical and InnerEntryLength > 0 then
        if entryDoor.y == StartY then
            local leftLength = entryDoor.x - StartX
            if leftLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, leftLength, false, false, "外墙下"))
            end
            local rightLength = StartX + InnerSizeX - entryDoor.x - entryDoor.length
            if rightLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(entryDoor.x + entryDoor.length, StartY, rightLength, false, false, "外墙下"))
            end
        else
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, InnerSizeX, false, false, "外墙下"))
        end

        if entryDoor.y == EndY then
            local leftLength = entryDoor.x - StartX
            if leftLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, EndY, leftLength, false, false, "外墙上"))
            end
            local rightLength = StartX + InnerSizeX - entryDoor.x - entryDoor.length
            if rightLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(entryDoor.x + entryDoor.length, EndY, rightLength, false, false, "外墙上"))
            end
        else
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, EndY, InnerSizeX, false, false, "外墙上"))
        end
    else
        table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, InnerSizeX, false, false, "外墙下"))
        table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, EndY, InnerSizeX, false, false, "外墙上"))
    end

    if InnerEntryVertical and InnerEntryLength > 0 then
        if entryDoor.x == StartX then
            local bottomLength = entryDoor.y - StartY
            if bottomLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, bottomLength, true, false, "外墙左"))
            end
            local topLength = StartY + InnerSizeY - entryDoor.y - entryDoor.length
            if topLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, entryDoor.y + entryDoor.length, topLength, true, false, "外墙左"))
            end
        else
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, InnerSizeY, true, false, "外墙左"))
        end

        if entryDoor.x == EndX then
            local bottomLength = entryDoor.y - StartY
            if bottomLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(EndX, StartY, bottomLength, true, false, "外墙右"))
            end
            local topLength = StartY + InnerSizeY - entryDoor.y - entryDoor.length
            if topLength > 0 then
                table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(EndX, entryDoor.y + entryDoor.length, topLength, true, false, "外墙右"))
            end
        else
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(EndX, StartY, InnerSizeY, true, false, "外墙右"))
        end
    else
        table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(StartX, StartY, InnerSizeY, true, false, "外墙左"))
        table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(EndX, StartY, InnerSizeY, true, false, "外墙右"))
    end

    for idx = 1, InnerSizeY - 1 do
        local begin = nil
        local length = 0
        for number = 0, InnerSizeX - 1 do
            if self:HasInnerHWall(idx, number) then
                if not begin then
                    begin = number
                end
                length = length + 1
            else
                if begin then
                    table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(self.x + begin, self.y + idx, length, false, false, "内墙"))
                    begin = nil
                    length = 0
                end
            end
        end

        if begin then
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(self.x + begin, self.y + idx, length, false, false, "内墙"))
        end
    end

    for idx = 1, InnerSizeX - 1 do
        local begin = nil
        local length = 0
        for number = 0, InnerSizeY - 1 do
            if self:HasInnerVWall(idx, number) then
                if not begin then
                    begin = number
                end
                length = length + 1
            else
                if begin then
                    table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(self.x + idx, self.y + begin, length, true, false, "内墙"))
                    begin = nil
                    length = 0
                end
            end
        end

        if begin then
            table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(self.x + idx, self.y + begin, length, true, false, "内墙"))
        end
    end

    for k, door in pairs(self.doors) do
        table.insert(self.navmeshData, CityWallOrDoorNavmeshDatum.new(door:LocalX() + self.x, door:LocalY() + self.y, door.length, not door.isHorizontal, true, "内门"))
    end
    return self.navmeshData
end

function CityBuilding:CenterPos()
    return self.mgr.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
end

function CityBuilding:PrintWallVH()
    for x, y, value in self.wallH:pairs() do
        print(value:LocalX(), value:LocalY(), value.isHorizontal)
    end

    for x, y, value in self.wallV:pairs() do
        print(value:LocalX(), value:LocalY(), value.isHorizontal)
    end
end

function CityBuilding:IsPolluted()
    return self.info.Polluted
end

---///////////////////////////// SLG About /////////////////////////////---

---@param inBattle boolean
function CityBuilding:SetBattleState(inBattle)
    self.battleState = inBattle
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_UPDATE, wds.CityBattleObjType.CityBattleObjTypeBuilding, self.id)
end

---@param inAttacking boolean
---@param targetTrans CS.UnityEngine.Transform
function CityBuilding:SetAttackingState(inAttacking, targetTrans)
    if inAttacking and not self.battleState then
        self:SetBattleState(true)
    end
    self.inAttacking = inAttacking
    self.targetTrans = targetTrans
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, wds.CityBattleObjType.CityBattleObjTypeBuilding, self.id)
end

function CityBuilding:UpdateHP(hp)
    if self.handle then
        self.handle:UpdateCur(hp)
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_HP_UPDATE, wds.CityBattleObjType.CityBattleObjTypeBuilding, self.id)
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityBuilding:PlaySkill(targetPos, animName, animDuration)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_PLAY_SKILL, wds.CityBattleObjType.CityBattleObjTypeBuilding, self.id, targetPos, animName, animDuration)
end

---@see CityTileAssetSLGUnitLifeBarTempBase
function CityBuilding:IsInBattleState()
    return self.battleState
end

function CityBuilding:RegisterLifeBar()
    if self.handle then return end
    self.handle = self.mgr.city.slgLifeBarManager:AddUnitByBuilding(self)
end

function CityBuilding:UnregisterLifeBar()
    if not self.handle then return end
    self.mgr.city.slgLifeBarManager:RemoveUnit(self.handle)
    self.handle = nil
end

function CityBuilding:ForceShowLifeBar()
    return false
end

---///////////////////////////// SLG About /////////////////////////////---

return CityBuilding