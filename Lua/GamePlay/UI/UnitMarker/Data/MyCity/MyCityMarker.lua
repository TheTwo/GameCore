---@class MyCityMarker
---@field new fun(worldPosition, camera):MyCityMarker
local MyCityMarker = class("MyCityMarker")
local ManualUIConst = require("ManualUIConst")

---@param worldPosition CS.UnityEngine.Vector3
---@param camera BasicCamera
function MyCityMarker:ctor(worldPosition, camera)
    self.worldPosition = worldPosition
    self.camera = camera
end

function MyCityMarker:IsTroop()
    return false
end

function MyCityMarker:GetHeroInfoData()
    return nil
end

function MyCityMarker:GetImage()
    return ManualUIConst.sp_item_slg_home
end

function MyCityMarker:GetViewportPositionImp()
    return self.camera.mainCamera:WorldToViewportPoint(self.worldPosition)
end

function MyCityMarker:NeedShowImp()
    local x, y = self._viewportPosition.x, self._viewportPosition.y
    return x < 0 or x > 1 or y < 0 or y > 1
end

function MyCityMarker:DoUpdate()
    self._viewportPosition = self:GetViewportPositionImp()
    self._needShow = self:NeedShowImp()
end

function MyCityMarker:GetViewportPosition()
    return self._viewportPosition
end

function MyCityMarker:NeedShow()
    return self._needShow
end

function MyCityMarker:GetCamera()
    return self.camera
end

function MyCityMarker:OnClick()
    self.camera:LookAt(self.worldPosition, 0.5)
end

function MyCityMarker:GetDistance()
    local lookAt = self.camera:GetLookAtPlanePosition()
    local lookAtX, lookAtZ = lookAt.x, lookAt.z
    local x, z = self.worldPosition.x, self.worldPosition.z
    return math.sqrt((lookAtX - x) ^ 2 + (lookAtZ - z) ^ 2)
end

return MyCityMarker