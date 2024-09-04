---@class CityCameraSizeRule
---@field new fun():CityCameraSizeRule
local CityCameraSizeRule = class("CityCameraSizeRule")
local Delegate = require("Delegate")
local EventConst = require("EventConst")

---@param camera BasicCamera
function CityCameraSizeRule:Initialize(camera)
    self.basicCamera = camera
    self.basicCamera:AddPreSizeChangeListener(Delegate.GetOrCreate(self, self.OnPreSizeChanged))
    self.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))

    self.defaultAltitude = 135
    self.defaultFov = 30
    self.indoorCameraSize = camera.settings:GetValue("indoorCameraSize")
    self.indoorAltitude = camera.settings:GetValue("indoorAltitude")
    self.indoorFov = camera.settings:GetValue("indoorFov")

    self.closeUpCameraSize = camera.settings:GetValue("closeUpCameraSize")
    self.closeUpAltitude = camera.settings:GetValue("closeUpAltitude")
    self.closeUpFov = camera.settings:GetValue("closeUpFov")

    self.indoorToCloseUpCurve = camera.settings:GetCurve("indoorToCloseUpCurve")
    self.block = false
    g_Game.EventManager:AddListener(EventConst.BASIC_CAMERA_SETTING_REFRESH, Delegate.GetOrCreate(self, self.OnSettingRefresh))
end

function CityCameraSizeRule:Release()
    g_Game.EventManager:RemoveListener(EventConst.BASIC_CAMERA_SETTING_REFRESH, Delegate.GetOrCreate(self, self.OnSettingRefresh))
    self.basicCamera:RemovePreSizeChangeListener(Delegate.GetOrCreate(self, self.OnPreSizeChanged))
    self.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
    self.basicCamera.cameraDataPerspective.spherical.altitude = self.defaultAltitude
    self.basicCamera:SetFov(self.defaultFov)
    self.basicCamera = nil
end

function CityCameraSizeRule:SetBlock(flag)
    self.block = flag
end

function CityCameraSizeRule:OnPreSizeChanged(oldSize, newSize)
    if self.block then return end

    local cameraData = self.basicCamera.cameraDataPerspective
    cameraData.spherical.altitude = self:GetLookAltitude(newSize)

    self.basicCamera:SetFov(self:GetFov(newSize))
end

function CityCameraSizeRule:OnSizeChanged(oldSize, newSize)
    if self.block then return end
end

function CityCameraSizeRule:GetLookAltitude(newSize)
    if newSize > self.indoorCameraSize then
        return self.indoorAltitude
    elseif newSize > self.closeUpCameraSize then
        local t = (newSize - self.indoorCameraSize) / (self.closeUpCameraSize - self.indoorCameraSize)
        local evaluate = self.indoorToCloseUpCurve:Evaluate(t)
        return evaluate * (self.closeUpAltitude - self.indoorAltitude) + self.indoorAltitude
    else
        return self.closeUpAltitude
    end
end

function CityCameraSizeRule:GetFov(newSize)
    if newSize > self.indoorCameraSize then
        return self.indoorFov
    elseif newSize > self.closeUpCameraSize then
        local t = (newSize - self.indoorCameraSize) / (self.closeUpCameraSize - self.indoorCameraSize)
        local evaluate = self.indoorToCloseUpCurve:Evaluate(t)
        return evaluate * (self.closeUpFov - self.indoorFov) + self.indoorFov
    else
        return self.closeUpFov
    end
end

function CityCameraSizeRule:OnSettingRefresh()
    if not self.basicCamera then return end

    self.indoorCameraSize = self.basicCamera.settings:GetValue("indoorCameraSize")
    self.indoorAltitude = self.basicCamera.settings:GetValue("indoorAltitude")
    self.indoorFov = self.basicCamera.settings:GetValue("indoorFov")

    self.closeUpCameraSize = self.basicCamera.settings:GetValue("closeUpCameraSize")
    self.closeUpAltitude = self.basicCamera.settings:GetValue("closeUpAltitude")
    self.closeUpFov = self.basicCamera.settings:GetValue("closeUpFov")

    self.indoorToCloseUpCurve = self.basicCamera.settings:GetCurve("indoorToCloseUpCurve")

    local currentSize = self.basicCamera:GetSize()
    self.basicCamera:SetSizeImp(currentSize)
end

return CityCameraSizeRule