local Utils = require("Utils")

local SEUnitHudLodCompSharedController = require("SEUnitHudLodCompSharedController")

---@class SEUnitHudLodComp
---@field controlRoot CS.UnityEngine.GameObject
local SEUnitHudLodComp = sealedClass("SEUnitHudLodComp")

function SEUnitHudLodComp:OnEnable()
    SEUnitHudLodCompSharedController.RegisterHud(self)
end

function SEUnitHudLodComp:OnDisable()
    if Utils.IsNotNull(self.controlRoot) then
        self.controlRoot:SetVisible(true)
    end
    SEUnitHudLodCompSharedController.UnregiesterHud(self)
end

function SEUnitHudLodComp:OnCameraSizeControlVisibleChange(visible)
    if Utils.IsNull(self.controlRoot) then return end
    self.controlRoot:SetVisible(visible)
end

return SEUnitHudLodComp