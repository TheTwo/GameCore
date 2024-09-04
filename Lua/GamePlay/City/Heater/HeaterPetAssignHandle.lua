local CityPetAssignHandle = require("CityPetAssignHandle")
---@class HeaterPetAssignHandle:CityPetAssignHandle
---@field new fun():HeaterPetAssignHandle
local HeaterPetAssignHandle = class("HeaterPetAssignHandle", CityPetAssignHandle)

---@param src HeaterPetDeployUIDataSrc
function HeaterPetAssignHandle:ctor(src)
    self.src = src
end

return HeaterPetAssignHandle