local BaseUIMediator = require ('BaseUIMediator')
---@class CityCommonRightPopupUIMediator:BaseUIMediator
local CityCommonRightPopupUIMediator = class('CityCommonRightPopupUIMediator', BaseUIMediator)
local Utils = require("Utils")

---@return CS.UnityEngine.RectTransform
function CityCommonRightPopupUIMediator:GetFocusAnchor()
    ---override this
    return nil
end

---@return CS.UnityEngine.Vector3
function CityCommonRightPopupUIMediator:GetWorldTargetPos()
    return self.param:GetWorldTargetPos()
end

---@return BasicCamera
function CityCommonRightPopupUIMediator:GetBasicCamera()
    return self.param:GetBasicCamera()
end

---@return number
function CityCommonRightPopupUIMediator:GetZoomSize()
    return self.param:GetZoomSize()
end

---@param param CityCommonRightPopupUIParameter
function CityCommonRightPopupUIMediator:OnOpened(param)
    self.param = param
    local basicCamera = self:GetBasicCamera()
    if not basicCamera then return end

    -- local focusAnchor = self:GetFocusAnchor()
    -- if Utils.IsNull(focusAnchor) then return end

    local worldTargetPos = self:GetWorldTargetPos()
    if not worldTargetPos then return end

    basicCamera:LookAt(worldTargetPos, 0.5)
end

function CityCommonRightPopupUIMediator:OnClose(param)
    -- if not self.backHandle then return end

    -- self.backHandle:back()
    -- self.backHandle = nil
end

return CityCommonRightPopupUIMediator