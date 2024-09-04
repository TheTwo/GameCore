local EventConst = require("EventConst")
local Utils = require("Utils")

---@class UIShowHideSoundProcessor
---@field new fun():UIShowHideSoundProcessor
local UIShowHideSoundProcessor = sealedClass('UIShowHideSoundProcessor')

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PreProcessOnCreate(uiMediator)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PreProcessOnShow(uiMediator)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PreProcessOnHide(uiMediator)
    if Utils.IsNull(uiMediator) then
        return
    end
    if not uiMediator.GetClassName then
        return
    end
    local className = uiMediator:GetClassName()
    if string.IsNullOrEmpty(className) then
        return
    end
    local property = uiMediator.Property
    if not property then
        return
    end
    local uiType = property.Type
    if not uiType then
        return
    end
    g_Game.SoundManager:OnUIMediatorPlayHideSound(className, uiType)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
---@param parameters CS.System.Object
function UIShowHideSoundProcessor:PreProcessOnClose(uiMediator, parameters)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PostProcessOnCreate(uiMediator)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PostProcessOnShow(uiMediator)
    if Utils.IsNull(uiMediator) then
        return
    end
    if not uiMediator.GetClassName then
        return
    end
    local className = uiMediator:GetClassName()
    if string.IsNullOrEmpty(className) then
        return
    end
    local property = uiMediator.Property
    if not property then
        return
    end
    local uiType = property.Type
    if not uiType then
        return
    end
    g_Game.SoundManager:OnUIMediatorPlayShowSound(className, uiType)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
function UIShowHideSoundProcessor:PostProcessOnHide(uiMediator)
end

---@param uiMediator CS.DragonReborn.UI.UIMediator
---@param parameters CS.System.Object
function UIShowHideSoundProcessor:PostProcessOnClose(uiMediator, parameters)
end

function UIShowHideSoundProcessor:OnProcessorRemove()
end

return UIShowHideSoundProcessor