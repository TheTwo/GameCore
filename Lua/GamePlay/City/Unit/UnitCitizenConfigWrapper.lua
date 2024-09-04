local UnitActorConfigWrapper = require("UnitActorConfigWrapper")
---@class UnitCitizenConfigWrapper:UnitActorConfigWrapper
---@field new fun(prefab:string, walkSpeed:number, runSpeed:number):UnitCitizenConfigWrapper
local UnitCitizenConfigWrapper = class("UnitCitizenConfigWrapper", UnitActorConfigWrapper)

---@param prefab string
---@param walkSpeed number
---@param runSpeed number
---@param scale number
function UnitCitizenConfigWrapper:ctor(prefab, walkSpeed, runSpeed, scale)
    UnitActorConfigWrapper.ctor(self, walkSpeed, runSpeed)
    self._prefab = prefab
    if scale > 0 then
        self._scale = scale
    else
        self._scale = 1
    end
end

function UnitCitizenConfigWrapper:Prefab()
    return self._prefab
end

function UnitCitizenConfigWrapper:InteractTargetTime()
    return 1.2
end

function UnitCitizenConfigWrapper:ModelScale()
    return self._scale
end

function UnitCitizenConfigWrapper.WrapSpeedValue(speed)
    return speed / 40.0
end

return UnitCitizenConfigWrapper