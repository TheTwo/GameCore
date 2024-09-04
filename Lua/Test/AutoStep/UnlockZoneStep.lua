local EmptyStep = require("EmptyStep")
---@class UnlockZoneStep:EmptyStep
---@field new fun():UnlockZoneStep
local UnlockZoneStep = class("UnlockZoneStep", EmptyStep)

function UnlockZoneStep:ctor(zoneId)
    self.zoneId = zoneId
end

function UnlockZoneStep:TryExecuted()
    if self.zoneId then
        local param = require("CastleUnlockZoneParameter").new()
        param.args.ZoneId = self.zoneId
        param:Send()
        self.zoneId = nil
        return true
    end
    return false
end

return UnlockZoneStep