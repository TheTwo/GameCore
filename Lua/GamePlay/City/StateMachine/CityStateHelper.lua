local CreepStatus = require("CreepStatus")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")
local CityConst = require("CityConst")

---@class CityStateHelper
local CityStateHelper = {}

---@param state CityState
---@param tile CityTileBase|CityStaticObjectTile
---@return number, number
function CityStateHelper.GetClosestPollutedCoord(state, tile)
    if tile then
        local x, y = tile.x - 1, tile.y - 1
        local sizeX, sizeY = tile:SizeX() + 2, tile:SizeY() + 2
        for i = x, x + sizeX - 1 do
            for j = y, y + sizeY - 1 do
                if state.city.creepManager:IsAffect(i, j) then
                    return i, j
                end
            end
        end
    end
    return -1, -1
end

---@param state CityState
---@param x number
---@param y number
function CityStateHelper.TryShowCreepToast(state, x, y)
    local status = state.city.creepManager.area:Get(x, y)
    if status == CreepStatus.ACTIVE or status == CreepStatus.INACTIVE then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
    end
end

---@param state CityState
---@param expeditionId number
---@param presetIndex number
---@param hideExitBtn boolean
---@return number,number|nil @CityConst.TransToSeStateResult, waitExpeditionId
function CityStateHelper.ExitToFocusOnBattle(state, expeditionId, presetIndex, hideExitBtn, hudHidePart)
    if not expeditionId or expeditionId == 0 then return CityConst.TransToSeStateResult.NoNeed,nil end
    ---@type wds.Expedition
    local expedition = g_Game.DatabaseManager:GetEntity(expeditionId, DBEntityType.Expedition)
    if not expedition then return CityConst.TransToSeStateResult.WaitExpeditionEntity, expeditionId end
    local spawnerId = expedition.ExpeditionInfo.SpawnerId
    if spawnerId == 0 then return CityConst.TransToSeStateResult.NoNeed,nil end
    local myCity = state.city
    ---@type CityElementSpawner
    local spawner = myCity.elementManager:GetElementById(spawnerId)
	local st = myCity.stateMachine
	st:WriteBlackboard("presetIndex", presetIndex)
    if spawner then
        st:WriteBlackboard("x", spawner.x)
	    st:WriteBlackboard("y", spawner.y)
        st:WriteBlackboard("spawner", spawner)
    end
    st:WriteBlackboard("hideExitBtn", hideExitBtn)
    st:WriteBlackboard("hudHidePart", hudHidePart)
	st:ChangeState(CityConst.STATE_CITY_SE_BATTLE_FOCUS)
    return CityConst.TransToSeStateResult.Success,nil
end

---@param state CityState
---@param scenePlayerId number
---@param presetIndex number
---@return number @CityConst.TransToSeStateResult
function CityStateHelper.ExitToFocusSeExplorer(state, scenePlayerId, presetIndex, hudHidePart, needEnterCameraZoom)
    local st = state.stateMachine
    st:WriteBlackboard("ScenePlayerId", scenePlayerId)
    st:WriteBlackboard("PresetIndex", presetIndex)
    st:WriteBlackboard("hudHidePart", hudHidePart)
    st:WriteBlackboard("needEnterCameraZoom", needEnterCameraZoom)
    st:ChangeState(CityConst.STATE_CITY_SE_EXPLORER_FOCUS)
    return CityConst.TransToSeStateResult.Success, nil
end

---@param entity wds.ScenePlayer
---@return  wds.ScenePlayerPresetBasisInfo|nil, wds.ScenePlayerPresetBasisInfo|nil
function CityStateHelper.GetScenePlayerInExplorerAndinFocusPreset(entity)
    ---@type  wds.ScenePlayerPresetBasisInfo
    local inExplorerPreset = nil
    ---@type  wds.ScenePlayerPresetBasisInfo
    local inFocusBattlePreset = nil
    local scenePresetList = entity.ScenePlayerPreset.PresetList
    for _, preset in pairs(scenePresetList) do
        if not inExplorerPreset and preset.InExplore then
            inExplorerPreset = preset
            if preset.InBattle then
                inFocusBattlePreset = preset
            end
        end
        if not inFocusBattlePreset and preset.InBattle and preset.Focus then
            inFocusBattlePreset = preset
        end
    end
    return inExplorerPreset, inFocusBattlePreset
end

---@param state CityState
---@param entity wds.ScenePlayer
---@return number,number|nil @CityConst.TransToSeStateResult, waitExpeditionId
function CityStateHelper.OnScenePlayerPresetChanged(state, entity, _)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return CityConst.TransToSeStateResult.NoNeed,nil
    end
    local inExplorerPreset,inFocusBattlePreset = CityStateHelper.GetScenePlayerInExplorerAndinFocusPreset(entity)
    -- if (not inExplorerPreset and inFocusBattlePreset) or (inExplorerPreset and inExplorerPreset == inFocusBattlePreset) then
    --     return CityStateHelper.JumpToCityStateSeBattle(state, inFocusBattlePreset, inExplorerPreset == inFocusBattlePreset, nil, nil)
    -- elseif inExplorerPreset and not inFocusBattlePreset then
    --     return CityStateHelper.JumpToCityStateSeExplorerFocus(state, inExplorerPreset, entity.ID, nil, true), nil
    -- end
    if inExplorerPreset then
        return CityStateHelper.JumpToCityStateSeExplorerFocus(state, inExplorerPreset, entity.ID, nil, true), nil
    end
    return CityConst.TransToSeStateResult.NoNeed,nil
end

---@param state CityState
---@return number,number|nil @CityConst.TransToSeStateResult, waitExpeditionId
function CityStateHelper.CheckAndJumpToSeExplorerState(state)
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    ---@type table<number, wds.ScenePlayer>
    local scenePlayers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    if not scenePlayers then return CityConst.TransToSeStateResult.NoNeed,nil end
    for _, scenePlayer in pairs(scenePlayers) do
        if scenePlayer.Owner.PlayerID == myPlayerId then
            return CityStateHelper.OnScenePlayerPresetChanged(state, scenePlayer)
        end
    end
    return CityConst.TransToSeStateResult.NoNeed,nil
end

---@param state CityState
---@param scenePreset wds.ScenePlayerPresetBasisInfo
---@return number,number|nil @CityConst.TransToSeStateResult, waitExpeditionId
function CityStateHelper.JumpToCityStateSeBattle(state, scenePreset, hideExitBtn, hudHidePart)
    return CityStateHelper.ExitToFocusOnBattle(state, scenePreset.BattleEntityId, scenePreset.PresetIndex, hideExitBtn, hudHidePart)
end

---@param state CityState
---@param scenePreset wds.ScenePlayerPresetBasisInfo
---@return number @CityConst.TransToSeStateResult
function CityStateHelper.JumpToCityStateSeExplorerFocus(state, scenePreset, scenePlayerId, hudHidePart, needEnterCameraZoom)
    return CityStateHelper.ExitToFocusSeExplorer(state, scenePlayerId, scenePreset.PresetIndex, hudHidePart, needEnterCameraZoom)
end

return CityStateHelper