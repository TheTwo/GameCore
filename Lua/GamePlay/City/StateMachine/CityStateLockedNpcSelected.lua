local Delegate = require("Delegate")
local EventConst = require("EventConst")
local QueuedTask = require("QueuedTask")
local Utils = require("Utils")
local CityConst = require("CityConst")

local CityStateDefault = require("CityStateDefault")

---@class CityStateLockedNpcSelected:CityStateDefault
---@field new fun():CityStateLockedNpcSelected
---@field super CityStateDefault
local CityStateLockedNpcSelected = class('CityStateLockedNpcSelected', CityStateDefault)

function CityStateLockedNpcSelected:ctor(city)
    CityStateDefault.ctor(self, city)
    ---@type CityCellTile
    self.cellTile = nil
end

function CityStateLockedNpcSelected:Enter()
    g_Game.UIManager:AddOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyOtherUIClicked))
    self.cellTile = self.stateMachine:ReadBlackboard("LockedNpcSelected", true)
    if not self.cellTile then
        self:ExitToIdleState()
        return
    end
    self.queuedTask = QueuedTask.new()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECTED, self.city, self.cellTile:GetCell():ConfigId())
    self.queuedTask:WaitEvent(EventConst.CITY_LOCKED_NONE_SHOWN_NPC_ENTRY_BUBBLE_LOADED, nil, Delegate.GetOrCreate(self, self.CheckToFocus)):DoAction(Delegate.GetOrCreate(self, self.DOFocusCurrentTile)):Start()
end

function CityStateLockedNpcSelected:Exit()
    if  self.queuedTask then
        self.queuedTask:Release()
    end
    self.queuedTask = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECTED, self.city, nil)
    g_Game.UIManager:RemoveOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyOtherUIClicked))
end

function CityStateLockedNpcSelected:OnAnyOtherUIClicked()
    self:ExitToIdleState()
end

function CityStateLockedNpcSelected:OnClick(gesture)
    self:ExitToIdleState()
end

function CityStateLockedNpcSelected:OnClickTrigger(trigger, position)
    if not trigger:IsUIBubble() then
        self:ExitToIdleState()
        return true
    end
    local ownerX,ownerY = trigger:GetOwnerPos()
    if ownerX ~= self.cellTile.x or ownerY ~= self.cellTile.y then
        self:ExitToIdleState()
        return true
    end
    local ret = CityStateDefault.OnClickTrigger(self, trigger, position)
    self:ExitToIdleState()
    return ret
end

function CityStateLockedNpcSelected:OnDragStart(gesture)
    self:ExitToIdleState()
end

---@param tile CityCellTile
function CityStateLockedNpcSelected:CheckToFocus(tile)
    return self.cellTile ~= nil and self.cellTile == tile
end

---@param tile CityCellTile
function CityStateLockedNpcSelected:DOFocus(tile)
    local go = tile.tileView.root
    if Utils.IsNull(go) then return end

    self.city:MoveGameObjIntoCamera(go, 0.25, CityConst.FullScreenCameraSafeArea)
end

function CityStateLockedNpcSelected:DOFocusCurrentTile()
    self:DOFocus(self.cellTile)
end

return CityStateLockedNpcSelected