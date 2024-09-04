local CityManagerBase = require("CityManagerBase")
---@class CityBuildingManager:CityManagerBase
---@field new fun():CityBuildingManager
---@field buildingMap table<number, CityBuilding>
local CityBuildingManager = class("CityBuildingManager", CityManagerBase)
local CityGridCellDef = require("CityGridCellDef")
local CastleBuildingRepairBaseParameter = require("CastleBuildingRepairBaseParameter")
local ConfigRefer = require("ConfigRefer")
local CastleBuildingRepairWallParameter = require("CastleBuildingRepairWallParameter")
local Delegate = require("Delegate")
local ProtocolId = require("ProtocolId")
local CastleBuildingAddDoorParameter = require("CastleBuildingAddDoorParameter")
local CastleBuildingAddWallsParameter = require("CastleBuildingAddWallsParameter")
local CastleBuildingDelDoorParameter = require("CastleBuildingDelDoorParameter")
local CastleBuildingDelWallsParameter = require("CastleBuildingDelWallsParameter")
local CastleBuildingChangeFloorParameter = require("CastleBuildingChangeFloorParameter")
local EventConst = require("EventConst")
local PushConsts = require("PushConsts")
local I18N = require("I18N")
local BuildingType = require("BuildingType")
local CityBuilding = require("CityBuilding")

function CityBuildingManager:DoDataLoad()
    self.buildingMap = {}
    local castle = self.city:GetCastle()
    for id, buildingInfo in pairs(castle.BuildingInfos) do
        --- 仅在初始化时使用DB数据重建, 由于变化数据监听解析Watcher的支持较为拉跨, 所以更新墙体和门的变化统一采用信任协议+监听Push的方式处理, 由协议和Push的回包携带明确的变化粒度
        local indoorInfo = castle.BuildingIndoorInfos[id]
        self:PlaceBuilding(CityBuilding.new(self, id, buildingInfo, indoorInfo))
    end
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingAddDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddDoorReply))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingAddWallsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddWallsReply))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingDelDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnDelDoorReply))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingDelWallsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnDelWallsReply))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushAddDoor, Delegate.GetOrCreate(self, self.OnPushAddDoor))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushAddWalls, Delegate.GetOrCreate(self, self.OnPushAddWalls))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushDelDoor, Delegate.GetOrCreate(self, self.OnPushDelDoor))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushDelWalls, Delegate.GetOrCreate(self, self.OnPushDelWalls))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingChangeFloorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnChangeFloorReply))
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_DIRTY_FOR_UPGRADE, Delegate.GetOrCreate(self, self.OnRoomMayDirty))
    g_Game.EventManager:AddListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChange))
    return self:DataLoadFinish()
end

function CityBuildingManager:DoDataUnload()
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingAddDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddDoorReply))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingAddWallsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddWallsReply))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingDelDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnDelDoorReply))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingDelWallsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnDelWallsReply))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushAddDoor, Delegate.GetOrCreate(self, self.OnPushAddDoor))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushAddWalls, Delegate.GetOrCreate(self, self.OnPushAddWalls))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushDelDoor, Delegate.GetOrCreate(self, self.OnPushDelDoor))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushDelWalls, Delegate.GetOrCreate(self, self.OnPushDelWalls))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingChangeFloorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnChangeFloorReply))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_DIRTY_FOR_UPGRADE, Delegate.GetOrCreate(self, self.OnRoomMayDirty))
    g_Game.EventManager:RemoveListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChange))
    self.buildingMap = nil
end

function CityBuildingManager:Initialized()
    return self.buildingMap ~= nil
end

---@param building CityBuilding
function CityBuildingManager:PlaceBuilding(building)    
    local node = building:ToCityNode()
    if node ~= nil then
        self.buildingMap[building.id] = building
        self.city.grid:AddCell(node)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, building.id)
    end
end

function CityBuildingManager:GetBuilding(id)
    return self.buildingMap[id]
end

function CityBuildingManager:IsPolluted(id)
    local building = self:GetBuilding(id)
    return building ~= nil and building:IsPolluted()
end

function CityBuildingManager:RemoveBuilding(id)
    local building = self:GetBuilding(id)
    local x, y = building.x, building.y
    self.city.grid:RemoveCell(x, y)
    self.buildingMap[id] = nil
    building:Release()
end

---@return wds.BuildingIndoorInfo
function CityBuildingManager:GetRoomInfo(id)
    local castle = self.city:GetCastle()
    return castle.BuildingIndoorInfos[id]
end

function CityBuildingManager:MoveBuilding(id, oldX, oldY, newX, newY)
    local buildingInfo = self:GetBuilding(id)
    buildingInfo.x, buildingInfo.y = newX, newY
    self.city.grid:MovingCell(oldX, oldY, newX, newY)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, id)
end

function CityBuildingManager:UpdateBuilding(id)
    local building = self:GetBuilding(id)
    local delay, sizeChange = building:UpdateBuildingInfo(self.city:GetCastle().BuildingInfos[id])
    local node = building:ToCityNode()
    self.city.grid:UpdateCell(node, delay)
    if sizeChange then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, id)
    end
end

---@param id number
function CityBuildingManager:IsRepairBlock(id, x, y)
    return self:GetRepairBlock(id, x, y) ~= nil
end

function CityBuildingManager:GetRepairBlock(id, x, y)
    local building = self:GetBuilding(id)
    if building == nil then
        return nil
    end

    for _, v in pairs(building.repairBlocks) do
        if v:Contains(x, y) then
            return v
        end
    end
    return nil
end

function CityBuildingManager:RequestAddMatToRepairBase(id, blockId, itemId)
    local param = CastleBuildingRepairBaseParameter.new()
    param.args.BuildingId = id
    param.args.BlockId = blockId
    param.args.CostIdx = self:GetCostIdxOfRepairBase(blockId, itemId)
    param:Send()
end

function CityBuildingManager:GetCostIdxOfRepairBase(blockId, itemId)
    local blockCfg = ConfigRefer.BuildingBlock:Find(blockId)
    local itemGroup = ConfigRefer.ItemGroup:Find(blockCfg:BaseRepairCost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        if info:Items() == itemId then
            return i - 1
        end
    end
    return -1
end

---NOTE:wallId传入时保留Lua逻辑从1开始, 发送时校正
function CityBuildingManager:RequestAddMatToRepairWall(id, blockId, wallId, itemId)
    local param = CastleBuildingRepairWallParameter.new()
    param.args.BuildingId = id
    param.args.BlockId = blockId
    param.args.WallId = wallId - 1
    param.args.CostIdx = self:GetCostIdxOfRepairWall(blockId, wallId, itemId)
    param:Send()
end

function CityBuildingManager:GetCostIdxOfRepairWall(blockId, wallId, itemId)
    local blockCfg = ConfigRefer.BuildingBlock:Find(blockId)
    if wallId <= 0 or blockCfg:RepairWallsLength() < wallId then
        return -1
    end

    local wallCfg = blockCfg:RepairWalls(wallId)
    local itemGroup = ConfigRefer.ItemGroup:Find(wallCfg:Cost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        if info:Items() == itemId then
            return i - 1
        end
    end
    return -1
end

---@return boolean
function CityBuildingManager:HasHWallOrDoor(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        if v:GetWorldHWallOrDoor(worldIdx, worldNumber) then
            return true
        end
    end
    return false
end

---@return boolean
function CityBuildingManager:HasVWallOrDoor(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        if v:GetWorldVWallOrDoor(worldIdx, worldNumber) then
            return true
        end
    end
    return false
end

---@return CityWall|nil
function CityBuildingManager:GetHWall(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        local inst = v:GetWorldHWallOrDoor(worldIdx, worldNumber)
        if inst then
            return inst:IsWall() and inst or nil
        end
    end
    return false
end

---@return CityDoor|nil
function CityBuildingManager:GetHDoor(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        local inst = v:GetWorldHWallOrDoor(worldIdx, worldNumber)
        if inst then
            return not inst:IsWall() and inst or nil
        end
    end
    return false
end

---@return CityWall|nil
function CityBuildingManager:GetVWall(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        local inst = v:GetWorldVWallOrDoor(worldIdx, worldNumber)
        if inst then
            return inst:IsWall() and inst or nil
        end
    end
    return false
end

---@return CityDoor|nil
function CityBuildingManager:GetVDoor(worldIdx, worldNumber)
    for k, v in pairs(self.buildingMap) do
        local inst = v:GetWorldVWallOrDoor(worldIdx, worldNumber)
        if inst then
            return not inst:IsWall() and inst or nil
        end
    end
    return false
end

function CityBuildingManager:GetRoomAt(x, y)
    for id, building in pairs(self.buildingMap) do
        if not building:Contains(x, y) then goto continue end
        
        local localX, localY = x - building.x, y - building.y
        for k, room in pairs(building.rooms) do
            if room:ContainsTile(localX, localY) then 
                return room
            end
        end
        ::continue::
    end
    return nil
end

---@param reply wrpc.CastleBuildingAddDoorReply
---@param rpc rpc.CastleBuildingAddDoor
function CityBuildingManager:OnAddDoorReply(isSuccess, reply, rpc)
    if not isSuccess then return end

    local request = rpc.request
    local building = self:GetBuilding(request.BuildingId)
    if not building then return end

    local idx = request.Column and request.Pos.X or request.Pos.Y
    local number = request.Column and request.Pos.Y or request.Pos.X
    building:AddNewDoor(reply.DoorId, idx, number, not request.Column, request.DoorCfgId)
    building:PostAddDoor(reply.DoorId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, request.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, request.BuildingId)
end

---@param reply wrpc.CastleBuildingAddWallsReply
---@param rpc rpc.CastleBuildingAddWalls
function CityBuildingManager:OnAddWallsReply(isSuccess, reply, rpc)
    if not isSuccess then return end

    local request = rpc.request
    local building = self:GetBuilding(request.BuildingId)
    if not building then return end

    for _, v in ipairs(request.RowPos) do
        building:AddNewWall(v.Y, v.X, true, request.WallCfgId)
    end
    for _, v in ipairs(request.ColumnPos) do
        building:AddNewWall(v.X, v.Y, false, request.WallCfgId)
    end
    building:PostAddWalls(request.RowPos, request.ColumnPos)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, request.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, request.BuildingId)
end

---@param reply wrpc.CastleBuildingDelDoorReply
---@param rpc rpc.CastleBuildingDelDoor
function CityBuildingManager:OnDelDoorReply(isSuccess, reply, rpc)
    if not isSuccess then return end
    
    local request = rpc.request
    local building = self:GetBuilding(request.BuildingId)
    if not building then return end

    local door = building:RemoveDoor(request.DoorId)
    building:PostRemoveDoor(door)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, request.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, request.BuildingId)
end

---@param reply wrpc.CastleBuildingDelWallsReply
---@param rpc rpc.CastleBuildingDelWalls
function CityBuildingManager:OnDelWallsReply(isSuccess, reply, rpc)
    if not isSuccess then return end

    local request = rpc.request
    local building = self:GetBuilding(request.BuildingId)
    if not building then return end

    local walls = {}
    for _, v in ipairs(request.RowPos) do
        table.insert(walls, building:RemoveWall(v.Y, v.X, true))
    end
    for _, v in ipairs(request.ColumnPos) do
        table.insert(walls, building:RemoveWall(v.X, v.Y, false))
    end
    building:PostRemoveWalls(walls)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, request.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, request.BuildingId)
end

---@param pushData wrpc.PushAddDoorRequest
function CityBuildingManager:OnPushAddDoor(isSuccess, pushData)
    local building = self:GetBuilding(pushData.BuildingId)
    if not building then return end

    local idx = pushData.Column and pushData.Pos.X or pushData.Pos.Y
    local number = pushData.Column and pushData.Pos.Y or pushData.Pos.X
    building:AddNewDoor(pushData.DoorId, idx, number, not pushData.Column, pushData.DoorCfgId)
    building:PostAddDoor(pushData.DoorId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, pushData.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, pushData.BuildingId)
end

---@param pushData wrpc.PushAddWallsRequest
function CityBuildingManager:OnPushAddWalls(isSuccess, pushData)
    local building = self:GetBuilding(pushData.BuildingId)
    if not building then return end

    for _, v in ipairs(pushData.RowPos) do
        building:AddNewWall(v.Y, v.X, true, pushData.WallCfgId)
    end
    for _, v in ipairs(pushData.ColumnPos) do
        building:AddNewWall(v.X, v.Y, false, pushData.WallCfgId)
    end
    building:PostAddWalls(pushData.RowPos, pushData.ColumnPos)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, pushData.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, pushData.BuildingId)
end

---@param pushData wrpc.PushDelDoorRequest
function CityBuildingManager:OnPushDelDoor(isSuccess, pushData)
    local building = self:GetBuilding(pushData.BuildingId)
    if not building then return end

    local door = building:RemoveDoor(pushData.DoorId)
    building:PostRemoveDoor(door)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, pushData.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, pushData.BuildingId)
end

---@param pushData wrpc.PushDelWallsRequest
function CityBuildingManager:OnPushDelWalls(isSuccess, pushData)
    local building = self:GetBuilding(pushData.BuildingId)
    if not building then return end

    local walls = {}
    for _, v in ipairs(pushData.RowPos) do
        table.insert(walls, building:RemoveWall(v.Y, v.X, true))
    end
    for _, v in ipairs(pushData.ColumnPos) do
        table.insert(walls, building:RemoveWall(v.X, v.Y, false))
    end
    building:PostRemoveWalls(walls)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, pushData.BuildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, pushData.BuildingId)
end

function CityBuildingManager:RequestAddWall(buildingId, x, y, cfgId, isHorizontal)
    local param = CastleBuildingAddWallsParameter.new()
    param.args.BuildingId = buildingId
    param.args.WallCfgId = cfgId
    if isHorizontal then
        param.args.RowPos:Add(wds.Point2.New(x, y))
    else
        param.args.ColumnPos:Add(wds.Point2.New(x, y))
    end
    param:SendWithFullScreenLock()
end

function CityBuildingManager:RequestAddDoor(buildingId, x, y, cfgId, isHorizontal)
    local param = CastleBuildingAddDoorParameter.new()
    param.args.BuildingId = buildingId
    param.args.DoorCfgId = cfgId
    param.args.Pos.X = x
    param.args.Pos.Y = y
    param.args.Column = not isHorizontal
    param:SendWithFullScreenLock()
end

---@return bytearray
function CityBuildingManager:GenerateMaskTable(width, height)
    local ret = bytearray.new(width * height)
    for _, buliding in pairs(self.buildingMap) do
        local roomInfo = buliding:GetRoomInfo()
        if roomInfo == nil then
            goto continue
        end
        local x, y = buliding.x, buliding.y
        x = x + roomInfo.X
        y = y + roomInfo.Y
        for i = x, x + roomInfo.Width - 1 do
            for j = y, y + roomInfo.Height - 1 do
                local idx = j * width + i + 1
                ret[idx] = 255
            end
        end
        ::continue::
    end
    return ret
end

function CityBuildingManager:OnRoomMayDirty(buildingId)
    local building = self:GetBuilding(buildingId)
    if building == nil then return end

    local roomInfo = self:GetRoomInfo(building.id)
    if roomInfo == nil then return end

    for id, room in pairs(building.rooms) do
        room.roomInfo = roomInfo.Rooms[id]
        room:CollectTileBelongsSelf()
        room:CollectRelativeWalls()
    end
    building:RoomReachable()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_FLOOR_UPDATE, buildingId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_WALL_AND_DOOR_DIRTY, buildingId)
end

---@param reply wrpc.CastleBuildingChangeFloorReply
---@param rpc rpc.CastleBuildingChangeFloor
function CityBuildingManager:OnChangeFloorReply(isSuccess, reply, rpc)
    if not isSuccess then return end

    local building = self:GetBuilding(rpc.request.BuildingId)
    if building == nil then return end

    local room = building.rooms[rpc.request.RoomId]
    room.roomInfo = self:GetRoomInfo(building.id).Rooms[rpc.request.RoomId]
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_FLOOR_UPDATE, rpc.request.BuildingId)
end

function CityBuildingManager:GetPlaceTypeNumLimit(typeId)
    local attr = self.city:GetCastle().GlobalAttr
    return attr.BuildingCountLimit[typeId] or 0
end

---@return table<number, CityWallOrDoorNavmeshDatum[]>
function CityBuildingManager:GenerateBuildingsNavmeshData()
    if not self.navmeshData then
        self.navmeshData = {}
    else
        table.clear(self.navmeshData)
    end

    for k, building in pairs(self.buildingMap) do
        self.navmeshData[k] = building:GenerateRoomNavmeshData()
    end
    return self.navmeshData
end

function CityBuildingManager:ReSyncBuildingsNavmeshData(buildingId)
    if table.isNilOrZeroNums(self.navmeshData) then
        return self:GenerateBuildingsNavmeshData()
    end
    local matchBuilding = false
    for k, building in pairs(self.buildingMap) do
        if k == buildingId then
            matchBuilding = true
            self.navmeshData[k] = building:GenerateRoomNavmeshData()
            break
        end
    end
    if not matchBuilding then
        self.navmeshData[buildingId] = nil
    end
    return self.navmeshData
end

function CityBuildingManager:PrintWallVH()
    for k, building in pairs(self.buildingMap) do
        building:PrintWallVH()
    end
end

function CityBuildingManager:OnSetLocalNotification(sdkSetNotCall)
    if sdkSetNotCall == nil then return end
    if not self.buildingMap then return end

    local buildingUpgradePushCfg = ConfigRefer.Push:Find(PushConsts.building_upgrade)
    for buildingId, building in pairs(self.buildingMap) do
        if not building:IsUpgradingProcessing() then goto continue end

        local notifyId = tonumber(buildingUpgradePushCfg:Id()..tostring(buildingId))
        local title = I18N.Get(buildingUpgradePushCfg:Title())
        local subtitle = I18N.Get(buildingUpgradePushCfg:SubTitle())
        local content = I18N.GetWithParamList(buildingUpgradePushCfg:Content(), building:GetName(), building:GetCurrentLevel() + 1)
        local delay = building:GetUpgradeRemainSeconds()
        sdkSetNotCall(notifyId, title, subtitle, content, delay, nil)
        ::continue::
    end
end

function CityBuildingManager:GetBuildingByLevelCfgId(cfgId)
    if not self.buildingMap then return nil end

    local lvCell = ConfigRefer.BuildingLevel:Find(cfgId)
    if not lvCell then return nil end

    for id, building in pairs(self.buildingMap) do
        if building.info.BuildingType == lvCell:Type() and building.info.Level == lvCell:Level() then
            return building
        end
    end

    return false
end

---@param typeId number BuildingTypes表的Id
---@return CityBuilding
function CityBuildingManager:GetBuildingByType(typeId)
    if not self.buildingMap then return nil end
    
    for id, building in pairs(self.buildingMap) do
        if building.info.BuildingType == typeId then
            return building
        end
    end

    return nil
end

function CityBuildingManager:IsBuildingPollutedByLevelCfgId(cfgId)
    local building = self:GetBuildingByLevelCfgId(cfgId)
    if not building then return false end

    return building:IsPolluted()
end

---@return CityBuilding
function CityBuildingManager:GetStronghold()
    if not self.strongholdTypeId then
        self.strongholdTypeId = -1
        for key, value in ConfigRefer.BuildingTypes:pairs() do
            if value:Type() == BuildingType.Stronghold then
                self.strongholdTypeId = value:Id()
                break
            end
        end
    end

    for id, building in pairs(self.buildingMap) do
        if building.info.BuildingType == self.strongholdTypeId then
            return building
        end
    end
end

function CityBuildingManager:OnEditModeChange(flag)
    CS.CityRoomWallAndDoorController.HideInEdit = flag
end

function CityBuildingManager:NeedLoadData()
    return false
end

return CityBuildingManager