---@class BuffFormulaMarker
---@field new fun(worldPosition, camera):BuffFormulaMarker
local BuffFormulaMarker = class("BuffFormulaMarker")

---@param worldPosition CS.UnityEngine.Vector3
---@param camera BasicCamera
function BuffFormulaMarker:ctor(worldPosition, camera)
    self.worldPosition = worldPosition
    self.camera = camera
    self.valid = true
end

function BuffFormulaMarker:Dispose()
    self.valid = false
end

function BuffFormulaMarker:IsTroop()
    return false
end

function BuffFormulaMarker:GetHeroInfoData()
    return nil
end

function BuffFormulaMarker:GetImage()
    return "sp_icon_slg_home_1"
end

function BuffFormulaMarker:GetViewportPositionImp()
    return self.camera.mainCamera:WorldToViewportPoint(self.worldPosition)
end

function BuffFormulaMarker:NeedShowImp()
    local x, y = self._viewportPosition.x, self._viewportPosition.y
    return x < 0 or x > 1 or y < 0 or y > 1
end

function BuffFormulaMarker:DoUpdate()
    self._viewportPosition = self:GetViewportPositionImp()
    self._needShow = self:NeedShowImp()
end

function BuffFormulaMarker:GetViewportPosition()
    return self._viewportPosition
end

function BuffFormulaMarker:NeedShow()
    return self.valid and self._needShow
end

function BuffFormulaMarker:GetCamera()
    return self.camera
end

function BuffFormulaMarker:OnClick()
    self.camera:LookAt(self.worldPosition, 0.5)
end

function BuffFormulaMarker:GetDistance()
    local lookAt = self.camera:GetLookAtPlanePosition()
    local lookAtX, lookAtZ = lookAt.x, lookAt.z
    local x, z = self.worldPosition.x, self.worldPosition.z
    return math.sqrt((lookAtX - x) ^ 2 + (lookAtZ - z) ^ 2)
end

return BuffFormulaMarker