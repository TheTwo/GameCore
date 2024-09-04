local CityState = require("CityState")
---@class CityStateChangeFloor:CityState
---@field new fun():CityStateChangeFloor
---@field data CityConstructionUICellDataFloor
local CityStateChangeFloor = class("CityStateChangeFloor", CityState)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CastleBuildingChangeFloorParameter = require("CastleBuildingChangeFloorParameter")
local CityConst = require("CityConst")

function CityStateChangeFloor:Enter()
    CityState.Enter(self)
    self.data = self.stateMachine:ReadBlackboard("data")
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_ASSET_FLASH, true)
    g_Game.EventManager:AddListener(EventConst.CITY_FLOOR_UICELL_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUICellDragRelease))
    g_Game.EventManager:AddListener(EventConst.CITY_FLOOR_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_FLOOR_SELECTION, Delegate.GetOrCreate(self, self.OnSelectionTwice))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingChangeFloorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnChangeFloorCallback))
end

function CityStateChangeFloor:Exit()
    self:HideCityCircleMenu()
    self:ResetRoomFloor()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FLOOR_UICELL_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUICellDragRelease))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FLOOR_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FLOOR_SELECTION, Delegate.GetOrCreate(self, self.OnSelectionTwice))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.OnUIClosed))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingChangeFloorParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnChangeFloorCallback))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_ASSET_FLASH, false)
    CityState.Exit(self)
end

function CityStateChangeFloor:ReEnter()
    self:Exit()
    self:Enter()
end

function CityStateChangeFloor:ResetRoomFloor()
    if self.room then
        self.room:SetPreviewFloorId(nil)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_FLOOR_UPDATE, self.room.building.id)
    end
end

function CityStateChangeFloor:OnUICellDragRelease(screenPos)
    local pos = self.city:GetCamera():GetHitPoint(screenPos)
    local x, y = self.city:GetCoordFromPosition(pos)
    self.room = self.city:GetRoomAt(x, y)
    if self.room ~= nil then
        self:PreviewChangeFloor()
    else
        self:ExitToIdleState()
    end
end

---@param gesture CS.DragonReborn.TapGesture
function CityStateChangeFloor:OnClick(gesture)
    local pos = self.city:GetCamera():GetHitPoint(gesture.position)
    local x, y = self.city:GetCoordFromPosition(pos)
    self.room = self.city:GetRoomAt(x, y)
    if self.room ~= nil then
        self:PreviewChangeFloor()
    else
        self:ExitToIdleState()
    end
end

---@param room CityRoom
function CityStateChangeFloor:PreviewChangeFloor()
    self.room:SetPreviewFloorId(self.data.cfg:Id())
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_ASSET_FLASH, false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_FLOOR_UPDATE, self.room.building.id)
    self:ShowCityCircleMenu()
end

function CityStateChangeFloor:GetCircleMenuUIParameter()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        true,
        Delegate.GetOrCreate(self, self.OnConfirmToBuild)
    )

    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.CancelPutting)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self.room:WorldCenter(), nil, {confirm, cancel})
end

function CityStateChangeFloor:OnConfirmToBuild()
    if self.room.roomInfo.Floor == self.data.cfg:Id() then
        return self:CancelPutting()
    end

    local param = CastleBuildingChangeFloorParameter.new()
    param.args.BuildingId = self.room.building.id
    param.args.RoomId = self.room.id
    param.args.FloorId = self.data.cfg:Id()
    param:Send()
end

function CityStateChangeFloor:CancelPutting()
    self:ExitToIdleState()
end

function CityStateChangeFloor:OnUIClosed()
    self:ExitToIdleState()
end

function CityStateChangeFloor:OnChangeFloorCallback(isSuccess, reply, rpc)
    if isSuccess then
        self:ExitToIdleState()
    end
end

function CityStateChangeFloor:OnSelectionTwice(data)
    if self.city:IsMyCity() and self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("data", data)
        self:ReEnter()
    end
end

return CityStateChangeFloor