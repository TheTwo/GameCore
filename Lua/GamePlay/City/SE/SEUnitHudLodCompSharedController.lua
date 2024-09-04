
---@class SEUnitHudLodCompSharedController
local SEUnitHudLodCompSharedController = sealedClass("SEUnitHudLodCompSharedController")

---@type table<SEUnitHudLodComp, SEUnitHudLodComp>
SEUnitHudLodCompSharedController.Comps = {}
SEUnitHudLodCompSharedController.sizeLast = nil
SEUnitHudLodCompSharedController.sizeNow = nil
SEUnitHudLodCompSharedController.sizeHide = nil

---@param lodComp SEUnitHudLodComp
function SEUnitHudLodCompSharedController.RegisterHud(lodComp, skipAddChange)
    SEUnitHudLodCompSharedController.Comps[lodComp] = lodComp
    if skipAddChange then return end
    local ctrl = SEUnitHudLodCompSharedController
    lodComp:OnCameraSizeControlVisibleChange(not ctrl.sizeHide)
end

---@param lodComp SEUnitHudLodComp
function SEUnitHudLodCompSharedController.UnregiesterHud(lodComp)
    SEUnitHudLodCompSharedController.Comps[lodComp] = nil
end

function SEUnitHudLodCompSharedController.OnCameraSizeChanged(lastSize, nowSize, sizeHide)
    local ctrl = SEUnitHudLodCompSharedController
    ctrl.sizeLast = lastSize
    ctrl.sizeNow = nowSize
    if ctrl.sizeHide == sizeHide then return end
    ctrl.sizeHide = sizeHide
    for _, comp in pairs(SEUnitHudLodCompSharedController.Comps) do
        comp:OnCameraSizeControlVisibleChange(not sizeHide)
    end
end

return SEUnitHudLodCompSharedController