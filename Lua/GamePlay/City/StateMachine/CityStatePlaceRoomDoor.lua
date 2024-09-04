---@alias DoorCoord {x:number, y:number}
local CityState = require("CityState")
---@class CityStatePlaceRoomDoor:CityState
---@field new fun():CityStatePlaceRoomDoor
---@field adsorbWalls table<DoorCoord, CityWall[]> 每一个吸附点坐标对应一组关联的CityWall, 可以获取到其Asset并隐藏
---@field lbCoords DoorCoord[] 初始化获取门吸附点的左下角坐标
---@field curCoord DoorCoord 当前位置, 直接引用table方便索引对应的墙体
---@field data CityConstructionUICellDataCustomRoom
local CityStatePlaceRoomDoor = class("CityStatePlaceRoomDoor", CityState)
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Delegate = require("Delegate")
local Utils = require("Utils")
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local I18N = require("I18N")
local CastleBuildingAddDoorParameter = require("CastleBuildingAddDoorParameter")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local CityConst = require("CityConst")

local RotH = CS.UnityEngine.Quaternion.identity
local RotV = CS.UnityEngine.Quaternion.Euler(0, 90, 0)

function CityStatePlaceRoomDoor:Enter()
    CityState.Enter(self)
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingAddDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddDoorCallback))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))

    self.minX = self.stateMachine:ReadBlackboard("minX")
    self.maxX = self.stateMachine:ReadBlackboard("maxX")
    self.minY = self.stateMachine:ReadBlackboard("minY")
    self.maxY = self.stateMachine:ReadBlackboard("maxY")
    self.data = self.stateMachine:ReadBlackboard("data")
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    self.doorCfg = ConfigRefer.BuildingRoomDoor:Find(self.data.cfg:Door())
    self.lengthLimit = math.max(1, self.doorCfg:Length())
    self:CollectRelativeWalls()
    if not self:PresetCurCoord() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Temp().toast_no_door_for_room)
        return self:TurnToNextStage()
    end

    self:LoadDoorModel()
end

function CityStatePlaceRoomDoor:Exit()
    self:ReleaseModel()
    self:HideCityCircleMenu()
    if not self.addDoorSuccess then
        self:ShowCoordRelativeWalls(self.curCoord, true)
    end
    self.addDoorSuccess = nil
    self.adsorbWalls = nil
    self.lbCoords = nil
    self.curCoord = nil
    self.cellTile = nil
    self.data = nil
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingAddDoorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAddDoorCallback))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    CityState.Exit(self)
end

function CityStatePlaceRoomDoor:CollectRelativeWalls()
    local lengthTop, lengthBottom = 0, 0
    self.adsorbWalls = {}
    self.lbCoords = {}
    for x = self.minX, self.maxX do
        local wall = self.city:GetWallAtBottom(x, self.minY)
        lengthBottom = wall and (lengthBottom + 1) or 0
        if lengthBottom >= self.lengthLimit then
            local coord = {x = x - (self.lengthLimit - 1), y = self.minY - 1}
            table.insert(self.lbCoords, coord)
            local walls = {isHorizontal = true}
            self.adsorbWalls[coord] = walls
            table.insert(walls, wall)
            for i = 1, self.lengthLimit - 1 do
                table.insert(walls, self.city:GetWallAtBottom(x-i, self.minY))
            end
        end

        wall = self.city:GetWallAtTop(x, self.maxY)
        lengthTop = wall and (lengthTop + 1) or 0
        if lengthTop >= self.lengthLimit then
            local coord = {x = x - (self.lengthLimit - 1), y = self.maxY}
            table.insert(self.lbCoords, coord)
            local walls = {isHorizontal = true}
            self.adsorbWalls[coord] = walls
            table.insert(walls, wall)
            for i = 1, self.lengthLimit - 1 do
                table.insert(walls, self.city:GetWallAtTop(x-i, self.maxY))
            end
        end
    end

    local lengthLeft, lengthRight = 0, 0
    for y = self.minY, self.maxY do
        local wall = self.city:GetWallAtLeft(self.minX, y)
        lengthLeft = wall and (lengthLeft + 1) or 0
        if lengthLeft >= self.lengthLimit then
            local coord = {x = self.minX - 1, y = y - (self.lengthLimit - 1)}
            table.insert(self.lbCoords, coord)
            local walls = {isHorizontal = false}
            self.adsorbWalls[coord] = walls
            table.insert(walls, wall)
            for i = 1, self.lengthLimit - 1 do
                table.insert(walls, self.city:GetWallAtLeft(self.minX, y-i))
            end
        end

        wall = self.city:GetWallAtRight(self.maxX, y)
        lengthRight = wall and (lengthRight + 1) or 0
        if lengthRight >= self.lengthLimit then
            local coord = {x = self.maxX, y = y - (self.lengthLimit - 1)}
            table.insert(self.lbCoords, coord)
            local walls = {isHorizontal = false}
            self.adsorbWalls[coord] = walls
            table.insert(walls, wall)
            for i = 1, self.lengthLimit - 1 do
                table.insert(walls, self.city:GetWallAtRight(self.maxX, y-i))
            end
        end
    end
end

function CityStatePlaceRoomDoor:PresetCurCoord()
    if #self.lbCoords == 0 then
        return false
    end

    local pos = self.city:GetCamera():GetLookAtPosition()
    local x, y = self.city:GetCoordFromPosition(pos)
    local coord = self:SortLbCoords(x, y)
    self.curCoord = coord
    return true
end

function CityStatePlaceRoomDoor:SortLbCoords(x, y)
    table.sort(self.lbCoords, function(l, r)
        local ldist = math.abs(x - l.x) + math.abs(y - l.y)
        local rdist = math.abs(x - r.x) + math.abs(y - r.y)
        return ldist < rdist
    end)
    return self.lbCoords[1]
end

function CityStatePlaceRoomDoor:LoadDoorModel()
    local prefabName = ArtResourceUtils.GetItem(self.doorCfg:Model())
    self.prefabName = prefabName
    self.handle = self.city.createHelper:Create(prefabName, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnDoorModelCreate), nil, 0, false)
end

function CityStatePlaceRoomDoor:ReleaseModel()
    if self.handle then
        self.city.createHelper:Delete(self.handle)
        self.handle = nil
    end
end

---@param go CS.UnityEngine.GameObject
function CityStatePlaceRoomDoor:OnDoorModelCreate(go, userdata)
    if Utils.IsNull(go) then
        g_Logger.ErrorChannel("City", ("Load %s failed"):format(self.prefabName))
        return
    end

    go:SetLayerRecursively("Selected")
    self.trans = go.transform
    self:PostCurCoordChanged()
    if not self.screenPos then
        self:ShowCityCircleMenu()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
    end
end

function CityStatePlaceRoomDoor:PostCurCoordChanged()
    local isHorizontal = self.adsorbWalls[self.curCoord].isHorizontal
    local pos = isHorizontal
        and self.city:GetWorldPositionFromCoord(self.curCoord.x + self.lengthLimit / 2, self.curCoord.y + 1)
        or self.city:GetWorldPositionFromCoord(self.curCoord.x + 1, self.curCoord.y + self.lengthLimit / 2)

    local rot = isHorizontal and RotH or RotV
    self.trans:SetPositionAndRotation(pos, rot)
    self:ShowCoordRelativeWalls(self.curCoord, false)    
end

function CityStatePlaceRoomDoor:ShowCoordRelativeWalls(coord, isShow)
    local walls = self.adsorbWalls[coord]
    for i, v in ipairs(walls) do
        if v.Asset and v.Asset.handle and v.Asset.handle.Loaded then
            v.Asset.controller:SetActive(v:GetPrefabName(), v:LocalX(), v:LocalY(), v.isHorizontal, isShow)
        end
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomDoor:OnDragStart(gesture)
    self.screenPos = gesture.position
    local point = self.city:GetCamera():GetHitPoint(self.screenPos)
    local x, y = self.city:GetCoordFromPosition(point)
    self.dragDoor = self:IsPointAtDoor(x, y)
    if self.dragDoor then
        self.lastX, self.lastY = x, y
        self:BlockCamera()
    else
        self:RecoverCamera()
    end
    self:HideCityCircleMenu()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomDoor:OnDragUpdate(gesture)
    self.screenPos = gesture.position
    if self.dragDoor then
        self:OnDragDoorAdsorbToWall(self.screenPos)
    end
    self:HideCityCircleMenu()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomDoor:OnDragEnd(gesture)
    self.screenPos = nil
    if self.dragDoor then
        self:RecoverCamera()
        self.dragDoor = false
    end
    self:ShowCityCircleMenu()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
end

function CityStatePlaceRoomDoor:IsPointAtDoor(x, y)
    local isHorizontal = self.adsorbWalls[self.curCoord].isHorizontal
    local maxX = self.curCoord.x + (isHorizontal and (self.lengthLimit - 1) or 1)
    local maxY = self.curCoord.y + (isHorizontal and 1 or (self.lengthLimit - 1))
    return self.curCoord.x <= x and x <= maxX and self.curCoord.y <= y and y <= maxY
end

function CityStatePlaceRoomDoor:OnDragDoorAdsorbToWall(screenPos)
    local point = self.city:GetCamera():GetHitPoint(screenPos)
    local x, y = self.city:GetCoordFromPosition(point)

    if x == self.lastX and y == self.lastY then return end
    local offsetX, offsetY = x - self.lastX, y - self.lastY
    local newX, newY = self.curCoord.x + offsetX, self.curCoord.y + offsetY
    local newCoord = self:SortLbCoords(newX, newY)
    if self.curCoord == newCoord then return end

    self:ShowCoordRelativeWalls(self.curCoord, true)
    self.curCoord = newCoord
    self:PostCurCoordChanged()
    self.lastX, self.lastY = x, y
end

function CityStatePlaceRoomDoor:GetCircleMenuUIParameter()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        self:MaterialEnough(),
        Delegate.GetOrCreate(self, self.OnConfirmToBuild),
        nil,
        self:GetMatExtraData()
    )

    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.CancelPutting)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldRightPos(), I18N.Get(self.doorCfg:Name()), {confirm, cancel})
end

function CityStatePlaceRoomDoor:OnConfirmToBuild()
    local param = CastleBuildingAddDoorParameter.new()
    param.args.DoorCfgId = self.doorCfg:Id()
    param.args.BuildingId = self:GetBuildingId()
    local building = self.city.buildingManager:GetBuilding(param.args.BuildingId)
    local x, y, isHorizontal = self:GetDoorParam()
    param.args.Pos.X = x - building.x
    param.args.Pos.Y = y - building.y
    param.args.Column = not isHorizontal
    param:Send()
end

function CityStatePlaceRoomDoor:CancelPutting()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_EXIT_ROOM_SUBPAGE)
end

function CityStatePlaceRoomDoor:WorldRightPos()
    local isHorizontal = self.adsorbWalls[self.curCoord].isHorizontal
    local maxX = self.curCoord.x + (isHorizontal and (self.lengthLimit - 1) or 1)
    local maxY = self.curCoord.y + (isHorizontal and 1 or (self.lengthLimit - 1))
    return self.city:GetWorldPositionFromCoord(maxX, (maxY + self.curCoord.y) / 2)
end

function CityStatePlaceRoomDoor:GetBuildingId()
    local isHorizontal = self.adsorbWalls[self.curCoord].isHorizontal
    local maxX = self.curCoord.x + (isHorizontal and (self.lengthLimit - 1) or 1)
    local maxY = self.curCoord.y + (isHorizontal and 1 or (self.lengthLimit - 1))
    local cell = self.city.grid:GetCell(maxX, maxY)
    return cell.tileId
end

function CityStatePlaceRoomDoor:GetDoorParam()
    local isHorizontal = self.adsorbWalls[self.curCoord].isHorizontal
    local x = self.curCoord.x + (isHorizontal and 0 or 1)
    local y = self.curCoord.y + (isHorizontal and 1 or 0)
    return x, y, isHorizontal
end

---@param reply wrpc.CastleBuildingAddDoorReply
---@param rpc rpc.CastleBuildingAddDoor
function CityStatePlaceRoomDoor:OnAddDoorCallback(isSuccess, reply, rpc)
    if not isSuccess then return end

    self.addDoorSuccess = true
    if self.data.cfg:RecommendFurnituresLength() == 0 then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_EXIT_ROOM_SUBPAGE)
    else
        self:TurnToNextStage()
    end
end

function CityStatePlaceRoomDoor:OnUIClosed()
    self:ExitToIdleState()
end

function CityStatePlaceRoomDoor:TurnToNextStage()
    self.stateMachine:WriteBlackboard("minX", self.minX, true)
    self.stateMachine:WriteBlackboard("minY", self.minY, true)
    self.stateMachine:WriteBlackboard("maxX", self.maxX, true)
    self.stateMachine:WriteBlackboard("maxY", self.maxY, true)
    self.stateMachine:WriteBlackboard("data", self.data, true)
    self.stateMachine:WriteBlackboard("cellTile", self.cellTile, true)
    self.stateMachine:WriteBlackboard("idx", 1)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_ROOM_MOVE_STEP)
    self.stateMachine:ChangeState(CityConst.STATE_PLACE_ROOM_FURNITURE)
end

function CityStatePlaceRoomDoor:MaterialEnough()
    local itemGroup = ConfigRefer.ItemGroup:Find(self.doorCfg:Cost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        local need = info:Nums()
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(info:Items())
        if own < need then
            return false
        end
    end
    return true
end

---@return ImageTextPair[]
function CityStatePlaceRoomDoor:GetMatExtraData()
    local ret = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self.doorCfg:Cost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        local need = info:Nums()
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(info:Items())
        local itemCfg = ConfigRefer.Item:Find(info:Items())
        local data = {
            image = itemCfg:Icon(),
            text = own < need and ("<color=#FF0000>%d</color>"):format(need) or tostring(need)
        }
        table.insert(ret, data)
    end
    return ret
end

return CityStatePlaceRoomDoor