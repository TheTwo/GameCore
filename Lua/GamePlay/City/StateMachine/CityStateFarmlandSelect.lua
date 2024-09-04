local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local CityConst = require("CityConst")
local AudioConsts = require("AudioConsts")
local Utils = require("Utils")

local CityState = require("CityState")

---@class CityStateFarmlandSelect:CityState
---@field new fun(city:City|MyCity):CityStateFarmlandSelect
---@field super CityState
local CityStateFarmlandSelect = class('CityStateFarmlandSelect', CityState)

function CityStateFarmlandSelect:ctor(city)
    CityState.ctor(self, city)
    self._runtimeUI = nil
    ---@type CityFurnitureTile
    self._furnitureTile = nil
    ---@type CityFurniture
    self._furnitureCell = nil
    ---@type wds.CastleFurniture
    self._furniture = nil
    self._selectGrowingMode = false
    self._isReEnter = false
end

function CityStateFarmlandSelect:Enter()
    CityState.Enter(self)
    self._furnitureTile = self.stateMachine:ReadBlackboard("furniture", true)
    self._furnitureCell = self._furnitureTile:GetCell()
    self._furniture = self._furnitureTile:GetCastleFurniture()
    self._farmlandMgr = self.city.farmlandManager
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self._furnitureTile:SetSelected(true)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_arableland)
    self._selectGrowingMode = false
    self:CameraFocus()
    self:OpenUI()
    if not self._isReEnter and not self._selectGrowingMode then
        self:HideHUD()
    end
    self._isReEnter = false
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_UNSELECT, Delegate.GetOrCreate(self, self.OnGrowingFarmlandUnSelected))
end

function CityStateFarmlandSelect:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_UNSELECT, Delegate.GetOrCreate(self, self.OnGrowingFarmlandUnSelected))
    if self._selectGrowingMode then
        self._farmlandMgr:SetSelectedGrowingFarmland(nil)
    end
    self._furnitureTile:SetSelected(false)
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    if not self._isReEnter then
        self:CloseUI()
    end
    if not self._selectGrowingMode then
        self:RestoreHUD()
    end
    CityState.Exit(self)
end

function CityStateFarmlandSelect:ReEnter()
    self._isReEnter = true
    self:Exit()
    self:Enter()
end

function CityStateFarmlandSelect:OnClickTrigger(trigger, position)
    local ownerPosX,ownerPosY = trigger:GetOwnerPos()
    if ownerPosX and ownerPosY then
        if ownerPosX == self._furnitureCell.x and ownerPosY == self._furnitureCell.y then
            return trigger:ExecuteOnClick()
        end
    end
    return false
end

function CityStateFarmlandSelect:OnClick(gesture)
    self:ExitToIdleState()
end

function CityStateFarmlandSelect:OpenUI()
    if self._furniture.LandInfo and self._furniture.LandInfo.state == wds.CastleLandState.CastleLandGrowing then
        self._farmlandMgr:SetSelectedGrowingFarmland(self._furnitureCell:UniqueId())
        self._selectGrowingMode = true
        return
    end
    ---@type CityFarmLandTouchMediatorParameter
    local parameter = {}
    parameter.city = self.city
    parameter.farmland = self._furniture
    parameter.farmlandMgr = self.city.farmlandManager
    self._runtimeUI = g_Game.UIManager:Open(UIMediatorNames.CityFarmLandTouchMediator, parameter)
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_TOUCH_UI_CLOSED, Delegate.GetOrCreate(self, self.OnTouchUIClosed))
end

function CityStateFarmlandSelect:CloseUI()
    self._farmlandMgr:SetSelectedGrowingFarmland(nil)
    if self._runtimeUI then
        g_Game.UIManager:Close(self._runtimeUI)
    end
    self._runtimeUI = nil
end

function CityStateFarmlandSelect:CameraFocus()
    local city = self.city
    local camera = city:GetCamera()
    camera:ForceGiveUpTween()
    if Utils.IsNull(self._furnitureTile.tileView.root) then return end
    city:MoveGameObjIntoCamera(self._furnitureTile.tileView.root, 0.25, CityConst.FullScreenCameraSafeArea)
end

function CityStateFarmlandSelect:HideHUD()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
    --g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.left, false)
    --g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.right, false)
end

function CityStateFarmlandSelect:RestoreHUD()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
    --g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.left, true)
    --g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.right, true)
end

function CityStateFarmlandSelect:OnTouchUIClosed(uiRuntime)
    if self._runtimeUI and uiRuntime == self._runtimeUI then
        self._runtimeUI = nil
        self:ExitToIdleState()
    end
end

function CityStateFarmlandSelect:OnGrowingFarmlandUnSelected(castleBriefId, landId)
    if self.city.uid ~= castleBriefId or self._furnitureCell:UniqueId() ~= landId then
        return
    end
    if not self._selectGrowingMode then
        return
    end
    local nextFarmland = self._farmlandMgr:GetNearestGrowingFarmland(self._furnitureCell.x, self._furnitureCell.y)
    if nextFarmland then
        self.stateMachine:WriteBlackboard("furniture", nextFarmland)
        self:ReEnter()
    else
        self:ExitToIdleState()
    end
end

return CityStateFarmlandSelect