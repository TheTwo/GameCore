local GMHeader = require("GMHeader")


---@class GMHeaderServiceManager:GMHeader
local GMHeaderServiceManager = class('GMHeaderServiceManager', GMHeader)

function GMHeaderServiceManager:ctor()
    GMHeader.ctor(self)

    self._pingms = 0
end

function GMHeaderServiceManager:DoText()
    if (not g_Game.ServiceManager) or (not g_Game.ServiceManager.statusSummary) then
        return string.Empty
    end
    local status = g_Game.ServiceManager.statusSummary
    return string.format("[%s]%s:%d, ping:%d ms", status:GetStatus(),status.Addr,status.Port, self._pingms)
end

function GMHeaderServiceManager:Tick()
    if g_Game.ServiceManager then
        self._pingms = g_Game.ServiceManager:GetPingMilliseconds()
    end
end

return GMHeaderServiceManager