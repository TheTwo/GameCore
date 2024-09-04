---@class CanUnlockFogMarker
---@field new fun(worldPosition, camera):CanUnlockFogMarker
local CanUnlockFogMarker = class("CanUnlockFogMarker")

---@param camera BasicCamera
function CanUnlockFogMarker:ctor(camera)
    self.camera = camera
end

function CanUnlockFogMarker:IsTroop()
    return false
end

function CanUnlockFogMarker:GetHeroInfoData()
    return nil
end

function CanUnlockFogMarker:GetImage()
    return "sp_icon_item_creepmedicine"
end

---@param worldPosition CS.UnityEngine.Vector3
function CanUnlockFogMarker:SetWorldPosition(worldPosition)
    self.worldPosition = worldPosition
end

function CanUnlockFogMarker:GetViewportPositionImp()
    return self.worldPosition and self.camera.mainCamera:WorldToViewportPoint(self.worldPosition) or nil
end

function CanUnlockFogMarker:NeedShowImp()
    if self._viewportPosition then
        local x, y = self._viewportPosition.x, self._viewportPosition.y
        return x < 0 or x > 1 or y < 0 or y > 1
    end
    return false
end

function CanUnlockFogMarker:DoUpdate()
    self._viewportPosition = self:GetViewportPositionImp()
    self._needShow = self:NeedShowImp()
end

function CanUnlockFogMarker:GetViewportPosition()
    return self._viewportPosition
end

function CanUnlockFogMarker:NeedShow()
    return self._needShow
end

function CanUnlockFogMarker:GetCamera()
    return self.camera
end

function CanUnlockFogMarker:OnClick()
    if self.worldPosition then
        self.camera:LookAt(self.worldPosition, 0.5)
    end
end

function CanUnlockFogMarker:GetDistance()
    if self.worldPosition then
        local lookAt = self.camera:GetLookAtPlanePosition()
        local lookAtX, lookAtZ = lookAt.x, lookAt.z
        local x, z = self.worldPosition.x, self.worldPosition.z
        return math.sqrt((lookAtX - x) ^ 2 + (lookAtZ - z) ^ 2)
    end
    return 0
end

return CanUnlockFogMarker