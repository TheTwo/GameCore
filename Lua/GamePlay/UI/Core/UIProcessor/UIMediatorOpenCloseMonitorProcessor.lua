---@class UIMediatorOpenCloseMonitorProcessor
---@field new fun():UIMediatorOpenCloseMonitorProcessor
local UIMediatorOpenCloseMonitorProcessor = class("UIMediatorOpenCloseMonitorProcessor")
local EventConst = require("EventConst")

function UIMediatorOpenCloseMonitorProcessor:PostProcessOnOpened(uiMediator)
    local uiMediatorName = uiMediator.Property.UIName
    g_Game.EventManager:TriggerEvent(EventConst.UI_MEDIATOR_OPENED, uiMediatorName)
end

function UIMediatorOpenCloseMonitorProcessor:PostProcessOnClose(uiMediator)
    local uiMediatorName = uiMediator.Property.UIName
    g_Game.EventManager:TriggerEvent(EventConst.UI_MEDIATOR_CLOSED, uiMediatorName)
end

return UIMediatorOpenCloseMonitorProcessor