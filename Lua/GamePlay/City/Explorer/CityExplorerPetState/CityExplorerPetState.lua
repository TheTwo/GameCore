local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")

local CityExplorerPetStateBase = require("CityExplorerPetStateBase")

---@class CityExplorerPetState:CityExplorerPetStateBase
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetState
---@field super CityExplorerPetStateBase
local CityExplorerPetState = class("CityExplorerPetState", CityExplorerPetStateBase)

---@param pet CityUnitExplorerPet
function CityExplorerPetState:ctor(pet)
    CityExplorerPetState.super.ctor(self, pet)
end

function CityExplorerPetState:Enter()
    self:DoProcessCheck()
end

function CityExplorerPetState:DoProcessCheck()
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    ---@type table<number, wds.ScenePlayer>
    local scenePlayers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    for _, value in pairs(scenePlayers) do
        if value.Owner.PlayerID == myPlayerId then
            self._pet:OnScenePlayerPresetChanged(value)
            break
        end
    end
    ---@type wds.Hero
    local hero = g_Game.DatabaseManager:GetEntity(self._pet._linkHeroId, DBEntityType.Hero)
    self._pet:OnHeroStatusChanged(hero)
end

function CityExplorerPetState:CheckTransState()
    return false
end

return CityExplorerPetState