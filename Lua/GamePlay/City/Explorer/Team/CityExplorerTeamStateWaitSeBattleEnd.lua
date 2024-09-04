
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")

local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateWaitSeBattleEnd:CityExplorerTeamState
---@field super CityExplorerTeamState
local CityExplorerTeamStateWaitSeBattleEnd = class("CityExplorerTeamStateWaitSeBattleEnd", CityExplorerTeamState)

function CityExplorerTeamStateWaitSeBattleEnd:Enter()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChange))
    local preset = self._team._teamData:GetScenePlayerPreset()
    if preset and not preset.InBattle then
        self._team._teamData:ResetTarget()
        -- self._team._mgr:ReSetHomeSeTroopExpectSpawnerId(self._team._teamPresetIdx, 0)
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
    end
end

function CityExplorerTeamStateWaitSeBattleEnd:Exit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChange))
end

---@param entity wds.ScenePlayer
function CityExplorerTeamStateWaitSeBattleEnd:OnPresetChange(entity, _)
    if not entity or entity.ID ~= self._team._teamData._scenePlayerId then
        return
    end
    local preset = self._team._teamData:GetScenePlayerPreset()
    if preset and not preset.InBattle then
        self._team._teamData:ResetTarget()
        -- self._team._mgr:ReSetHomeSeTroopExpectSpawnerId(self._team._teamPresetIdx, 0)
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
    end
end

return CityExplorerTeamStateWaitSeBattleEnd