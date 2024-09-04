---@class ExpireBuffFormulaMarker
---@field new fun(worldPosition, camera):ExpireBuffFormulaMarker
local ExpireBuffFormulaMarker = class("ExpireBuffFormulaMarker")

---@param worldPosition CS.UnityEngine.Vector3
---@param camera BasicCamera
function ExpireBuffFormulaMarker:ctor(worldPosition, camera)
    self.worldPosition = worldPosition
    self.camera = camera
    self.valid = true
end

function ExpireBuffFormulaMarker:Dispose()
    self.valid = false
end

function ExpireBuffFormulaMarker:IsTroop()
    return false
end

function ExpireBuffFormulaMarker:GetHeroInfoData()
    return nil
end

function ExpireBuffFormulaMarker:GetImage()
    return "sp_icon_slg_home_1"
end

function ExpireBuffFormulaMarker:GetViewportPositionImp()
    return self.camera.mainCamera:WorldToViewportPoint(self.worldPosition)
end

function ExpireBuffFormulaMarker:NeedShowImp()
    local x, y = self._viewportPosition.x, self._viewportPosition.y
    return x < 0 or x > 1 or y < 0 or y > 1
end

function ExpireBuffFormulaMarker:DoUpdate()
    self._viewportPosition = self:GetViewportPositionImp()
    self._needShow = self:NeedShowImp()
end

function ExpireBuffFormulaMarker:GetViewportPosition()
    return self._viewportPosition
end

function ExpireBuffFormulaMarker:NeedShow()
    return self.valid and self._needShow
end

function ExpireBuffFormulaMarker:GetCamera()
    return self.camera
end

function ExpireBuffFormulaMarker:OnClick()
    self.camera:LookAt(self.worldPosition, 0.5)
end

function ExpireBuffFormulaMarker:GetDistance()
    local lookAt = self.camera:GetLookAtPlanePosition()
    local lookAtX, lookAtZ = lookAt.x, lookAt.z
    local x, z = self.worldPosition.x, self.worldPosition.z
    return math.sqrt((lookAtX - x) ^ 2 + (lookAtZ - z) ^ 2)
end

return ExpireBuffFormulaMarker