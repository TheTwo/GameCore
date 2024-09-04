local CityTileAssetLegoUnit = require("CityTileAssetLegoUnit")
---@class CityTileAssetLegoBuildingWall:CityTileAssetLegoUnit
---@field new fun():CityTileAssetLegoBuildingWall
---@field super CityTileAssetLegoUnit
local CityTileAssetLegoBuildingWall = class("CityTileAssetLegoBuildingWall", CityTileAssetLegoUnit)
local Utils = require("Utils")
local CityUnitMoveGridEventProvider = require("CityUnitMoveGridEventProvider")

---@param legoBuilding CityLegoBuilding
---@param legoWall CityLegoWall
function CityTileAssetLegoBuildingWall:ctor(legoBuilding, legoWall, indoor)
    CityTileAssetLegoUnit.ctor(self, legoBuilding, legoWall:GetCfgId(), legoWall:GetStyle(indoor), indoor)
    self.legoBuilding = legoBuilding
    self.legoWall = legoWall
    self.unitMoveEventListener = nil
    ---@type CS.UnityEngine.Animator
    self.doorAnimator = nil
    self._doorOpenStatus = false
end

function CityTileAssetLegoBuildingWall:GetWorldPosition()
    return self.legoWall:GetWorldPosition()
end

function CityTileAssetLegoBuildingWall:GetWorldRotation()
    return self.legoWall:GetWorldRotation()
end

function CityTileAssetLegoBuildingWall:NotifyDoorOpenStatus(isOpen)
    self._doorOpenStatus = isOpen
    if Utils.IsNull(self.doorAnimator) then
        return
    end
    if self.doorAnimator:HasParameter("open") then
        self.doorAnimator:SetBool("open", self._doorOpenStatus)
    end
end

function CityTileAssetLegoBuildingWall:OnAssetLoaded(go, userdata, handle)
    CityTileAssetLegoUnit.OnAssetLoaded(self, go, userdata, handle)

    local comp = self.go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
    if Utils.IsNotNull(comp) then
        local leftPillar = self.legoWall:HasClockwiseCorner()
        local rightPillar = self.legoWall:HasAnticlockwiseCorner()
        comp:ApplyWallPillarHide(true, leftPillar)
        comp:ApplyWallPillarHide(false, rightPillar)

        if self.legoWall:IsFront() then
            comp:ApplyWallHide(self:GetCity().wallHide)
        end
        if self.legoWall:IsDoor() then
            self.doorAnimator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
            if Utils.IsNotNull(self.doorAnimator) then
                if self.doorAnimator:HasParameter("open") then
                    self.doorAnimator:SetBool("open", self._doorOpenStatus)
                end
            end
        end
    end
end

function CityTileAssetLegoBuildingWall:OnTileViewInit()
    CityTileAssetLegoBuildingWall.super.OnTileViewInit(self)
    if self.legoWall:IsDoor() then
        ---@type CityUnitMoveGridEventProvider.Listener
        local listenerTrack = {}
        listenerTrack.count = 0
        listenerTrack.onEnter = function(_, _, l)
            listenerTrack.count = l.count
            self:NotifyDoorOpenStatus(l.count > 0)
        end
        listenerTrack.onExit = function(_, _, l)
            listenerTrack.count = l.count
            self:NotifyDoorOpenStatus(l.count > 0)
        end
        local x,y,sizeX,sizeY = self.legoWall:GetRange()
        self.unitMoveEventListener = self.legoBuilding.city.unitMoveGridEventProvider:AddListener(x,y,sizeX,sizeY, listenerTrack.onEnter, listenerTrack.onExit, CityUnitMoveGridEventProvider.UnitTypeMask.MyCityUnit)
        self.unitMoveEventListener.listener = listenerTrack
    end
end

function CityTileAssetLegoBuildingWall:OnTileViewRelease()
    if self.unitMoveEventListener then
        self.legoBuilding.city.unitMoveGridEventProvider:RemoveListener(self.unitMoveEventListener)
    end
    self.unitMoveEventListener = nil
    self._doorOpenStatus = false
    CityTileAssetLegoBuildingWall.super.OnTileViewRelease(self)
end

function CityTileAssetLegoBuildingWall:GetDecorations(indoor)
    return self.legoWall:GetDecorations(indoor)
end

function CityTileAssetLegoBuildingWall:GetInstanceId()
    return self.legoWall.payload:Id()
end

function CityTileAssetLegoBuildingWall:OnWallHideChanged(wallHide)
    if not self.legoWall:IsFront() then return end

    if Utils.IsNotNull(self.go) then
        local comp = self.go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
        if Utils.IsNotNull(comp) then
            comp:ApplyWallHide(wallHide)
        end
    end
end

function CityTileAssetLegoBuildingWall:GetType()
    return self.legoWall:IsDoor() and "门" or "墙壁"
end

return CityTileAssetLegoBuildingWall