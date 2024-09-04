local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")

local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateWaitEnterSeBattle:CityExplorerTeamState
---@field super CityExplorerTeamState
local CityExplorerTeamStateWaitEnterSeBattle = class("CityExplorerTeamStateWaitEnterSeBattle", CityExplorerTeamState)

function CityExplorerTeamStateWaitEnterSeBattle:Enter()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChange))
    local preset = self._team._teamData:GetScenePlayerPreset()
    if preset and preset.InBattle then
        self.stateMachine:ChangeState("CityExplorerTeamStateWaitSeBattleEnd")
    end
end

function CityExplorerTeamStateWaitEnterSeBattle:Exit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChange))
end

---@param entity wds.ScenePlayer
function CityExplorerTeamStateWaitEnterSeBattle:OnPresetChange(entity, _)
    if not entity or entity.ID ~= self._team._teamData._scenePlayerId then
        return
    end
    local preset = self._team._teamData:GetScenePlayerPreset()
    if not preset or not preset.InBattle then
        return
    end
    self.stateMachine:ChangeState("CityExplorerTeamStateWaitSeBattleEnd")
end

return CityExplorerTeamStateWaitEnterSeBattle