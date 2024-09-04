
local CityExplorerPetStateBase = require("CityExplorerPetStateBase")

---@class CityExplorerPetSubStateNone:CityExplorerPetStateBase
---@field new fun(pet:CityUnitExplorerPet, host:CityExplorerPetStateCollect):CityExplorerPetSubStateNone
---@field super CityExplorerPetStateBase
local CityExplorerPetSubStateNone = class("CityExplorerPetSubStateNone", CityExplorerPetStateBase)

return CityExplorerPetSubStateNone