local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local DBEntityType = require("DBEntityType")

---@class CityExplorerTeamData
---@field new fun(city:MyCity,mgr:CityExplorerManager):CityExplorerTeamData
local CityExplorerTeamData = sealedClass('CityExplorerTeamData')

---@param city MyCity
---@param mgr CityExplorerManager
---@param team CityExplorerTeam
function CityExplorerTeamData:ctor(city, mgr, team, scenePlayerId)
    ---@type MyCity
    self._city = city
    ---@type CityExplorerManager
    self._mgr = mgr
    ---@type wds.Hero
    self._entity = nil
    ---@type CityExplorerTeam
    self._team = team
    self._presetIndex = team._teamPresetIdx
    self._scenePlayerId = scenePlayerId

    ---@private
    ---@type wds.Vector2F
    self._lastCoord = nil
    ---@type number @city Npc Id
    self._targetId = 0
    self._isTargetGround = false
    self._lastMarkInMoving = false
    self._forceNotifyPosFlag = true
    self._markInteractEndToRemove = false
    ---@type CityExplorerTeamDefine.InteractEndAction
    self._markInteractEndAction = nil
end

function CityExplorerTeamData:IsTargetGround()
    return self._isTargetGround
end

function CityExplorerTeamData:HasTarget()
    return (self._targetId ~= 0 or self._isTargetGround)
end

function CityExplorerTeamData:GetTargetIdAndReset()
    local ret = self._targetId
    self._targetId = 0
    return ret
end

function CityExplorerTeamData:GetTargetId()
    return self._targetId
end

function CityExplorerTeamData:ResetTarget()
    self._targetId = 0
    self._isTargetGround = false
end

function CityExplorerTeamData:GetStatusIconAndBackground()
    return CityExplorerTeamDefine.StatusIcon.Camp
end

function CityExplorerTeamData:IsInMoving()
    local hero = self:GetEntity()
    if hero then
        return hero.MapStates.Moving
    end
    return false
end

function CityExplorerTeamData:Battling()
    local hero = self:GetEntity()
    if hero then
        return hero.MapStates.StateWrapper.Battle
    end
    return false
end

function CityExplorerTeamData:Interacting()
    local hero = self:GetEntity()
    if hero then
        return hero.MapStates.IsInteract
    end
    return false
end

function CityExplorerTeamData:MarkLastMovingFlag(moving)
    self._lastMarkInMoving = moving
end

function CityExplorerTeamData:MarkForceNotifyPosFlag()
    self._forceNotifyPosFlag = true
end

function CityExplorerTeamData:GetAndResetForceNotifyPosFlag()
    if self._forceNotifyPosFlag then
        self._forceNotifyPosFlag = false
        return true
    end
    return false
end

function CityExplorerTeamData:GetFocusOnHero()
    return self._team._currentFocusOnHero
end

---@return wds.Hero
function CityExplorerTeamData:GetEntity()
    if not self._team._currentFocusOnHero then return end
    return self._team._currentFocusOnHero:GetEntity()
end

---@return wds.ScenePlayerPresetBasisInfo|nil
function CityExplorerTeamData:GetScenePlayerPreset()
    ---@type wds.ScenePlayer
    local entity = g_Game.DatabaseManager:GetEntity(self._scenePlayerId, DBEntityType.ScenePlayer)
    if not entity or not entity.ScenePlayerPreset or not entity.ScenePlayerPreset.PresetList then return nil end
    for _, value in pairs(entity.ScenePlayerPreset.PresetList) do
        if value.PresetIndex == self._presetIndex then
            return value
        end
    end
    return nil
end

---@param action CityExplorerTeamDefine.InteractEndAction
function CityExplorerTeamData:SetInteractEndAction(action)
    self._markInteractEndAction = action
end

---@return string,string,string @icon,back,i18n
function CityExplorerTeamData:MyTroopStateIconAndDesc()
    local preset = self:GetScenePlayerPreset()
    if not preset then
        return "sp_city_icon_refugee", "sp_troop_img_state_base_2", "troop_status_7"
    end
    if preset.InBattle then
        return "sp_troop_icon_status_battle", "sp_troop_img_state_base_4", "formation-zhandou"
    end
    if self._team:InBackState() then
        return "sp_common_btn_back_03","sp_troop_img_state_base_3", "formation-huicheng"
    end
    if self:IsInMoving() or self._team:InMovingState() then
        return "sp_troop_img_state_walk", "sp_troop_img_state_base_1", "formation-xingjun"
    end
    return "sp_city_icon_refugee", "sp_troop_img_state_base_2", "troop_status_7"
end

return CityExplorerTeamData

