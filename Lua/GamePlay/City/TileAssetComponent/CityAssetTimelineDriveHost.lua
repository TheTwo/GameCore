local Delegate = require("Delegate")

---@class CityAssetTimelineDriveHost
local CityAssetTimelineDriveHost = sealedClass("CityAssetTimelineDriveHost")

---@private
---@type CityAssetTimelineDriveHost
CityAssetTimelineDriveHost.Instance = nil

function CityAssetTimelineDriveHost:ctor()
    ---@type table<CityAssetTimelineDrive, CityAssetTimelineDrive>
    self._user = {}
    self._hasTick = false
    ---@type CityAssetTimelineDrive[]
    self._queue = {}
    self._userCount = 0
end

function CityAssetTimelineDriveHost.GetInstance()
    if not CityAssetTimelineDriveHost.Instance then
        CityAssetTimelineDriveHost.Instance = CityAssetTimelineDriveHost.new()
    end
    return CityAssetTimelineDriveHost.Instance
end

---@param user CityAssetTimelineDrive
function CityAssetTimelineDriveHost:AddTickStart(user)
    if self._user[user] then return end
    self._user[user] = user
    self._userCount = self._userCount + 1
    self._queue[#self._queue + 1] = user
    if not self._hasTick then
        self._hasTick = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    end
end

---@param user CityAssetTimelineDrive
function CityAssetTimelineDriveHost:RemoveTickStart(user)
    if not self._user[user] then return end
    self._user[user] = nil
    self._userCount = self._userCount - 1
    for i = #self._queue, 1, -1 do
        if self._queue[i] == user then
            table.remove(self._queue, i)
            break
        end
    end
    if self._userCount <= 0 and self._hasTick then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        self._hasTick = false
    end
end

function CityAssetTimelineDriveHost:Tick(dt)
    if #self._queue <= 0 then return end
    local user = table.remove(self._queue, 1)
    user:InQueuePlayStart()
end

return CityAssetTimelineDriveHost