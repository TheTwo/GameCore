---@class SETeamManager
---@field new fun():SETeamManager
local SETeamManager = class("SETeamManager")
local SETeam = require("SETeam")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")

---@param env SEEnvironment
function SETeamManager:ctor(env)
    self._env = env

    ---@type table<number, SETeam>
    self._mainPlayerTeam = {}
    self._pooledCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("SETeam")
    self._teamMoveSpeed = ConfigRefer.ConstSe:CitySeCameraMoveSpeed()
    if self._teamMoveSpeed == 0 then
        g_Logger.ErrorChannel("SETeamManager", "CitySeCameraMoveSpeed Cfg is 0, set to 5")
        self._teamMoveSpeed = 5
    end
    self._singleTeamVxRadius = ConfigRefer.ConstSe:SeFormationCircle1HeroVXRadius()
    if self._singleTeamVxRadius == 0 then
        g_Logger.ErrorChannel("SETeamManager", "SeFormationCircle1HeroVXRadius Cfg is 0, set to 1")
        self._singleTeamVxRadius = 5
    end
    self._doubleTeamVxRadius = ConfigRefer.ConstSe:SeFormationCircle2HeroesVXRadius()
    if self._doubleTeamVxRadius == 0 then
        g_Logger.ErrorChannel("SETeamManager", "SeFormationCircle2HeroesVXRadius Cfg is 0, set to 1")
        self._doubleTeamVxRadius = 6
    end
    self._tripleTeamVxRadius = ConfigRefer.ConstSe:SeFormationCircle3HeroesVXRadius()
    if self._tripleTeamVxRadius == 0 then
        g_Logger.ErrorChannel("SETeamManager", "SeFormationCircle3HeroesVXRadius Cfg is 0, set to 1")
        self._tripleTeamVxRadius = 7
    end
end

function SETeamManager:GetEnvironment()
    return self._env
end

---@param scenePlayer wds.ScenePlayer
function SETeamManager:CreateOrUpdateTeam(scenePlayer)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        g_Logger.ErrorChannel("SETeamManager", "Player is nil")
        return
    end
    local validPresetIdx = {}
    for _, preset in pairs(scenePlayer.ScenePlayerPreset.PresetList) do
        local presetIdx = preset.PresetIndex
        validPresetIdx[presetIdx] = true
        if not self._mainPlayerTeam[presetIdx] then
            self._mainPlayerTeam[presetIdx] = SETeam.new(self, presetIdx, player.SceneInfo.CastleBriefId)
            self._mainPlayerTeam[presetIdx]:Initialize()
        else
            self._mainPlayerTeam[presetIdx]:Update()
        end
    end
    for presetIdx, seTeam in pairs(self._mainPlayerTeam) do
        if not validPresetIdx[presetIdx] then
            self._mainPlayerTeam[presetIdx] = nil
            seTeam:Dispose()
        end
    end
end

function SETeamManager:DestroyTeam(scenePlayer)
    for presetIdx, seTeam in pairs(self._mainPlayerTeam) do
        self._mainPlayerTeam[presetIdx] = nil
        seTeam:Dispose()
    end
end

---@return SETeam
function SETeamManager:GetOperatingTeam()
    for _, team in pairs(self._mainPlayerTeam) do
        if team:IsOperatingTeam() then
            return team
        end
    end
    return nil
end

---@param scenePlayer wds.ScenePlayer
function SETeamManager:UpdateTeamCenter(scenePlayer)
    for presetIdx, info in pairs(scenePlayer.ScenePlayerCenterPoint.Infos) do
        if info.LastClientMoveStickOpType == wrpc.MoveStickOpType.MoveStickOpType_Move then
            goto continue
        end

        if self._mainPlayerTeam[presetIdx] then
            self._mainPlayerTeam[presetIdx]:UpdateCenter(info)
        end
        ::continue::
    end
end

---@param scenePlayer wds.ScenePlayer
function SETeamManager:UpdateTeamCaptain(scenePlayer)
    for presetIdx, info in pairs(scenePlayer.ScenePlayerHero.Infos) do
        if self._mainPlayerTeam[presetIdx] then
            self._mainPlayerTeam[presetIdx]:UpdateCaptain(info)
        end
    end
end

function SETeamManager:Dispose()
    self:GetEnvironment():UpdateTeamCenterPosToRangeEvent(nil)
    for _, team in pairs(self._mainPlayerTeam) do
        team:Dispose()
    end
    table.clear(self._mainPlayerTeam)
    self._pooledCreateHelper:DeleteAll()
end

function SETeamManager:Update(delta)
    local operateTeam = self:GetOperatingTeam()
    for _, team in pairs(self._mainPlayerTeam) do
        team:Tick(delta)
        if team:IsOperatingTeam() then
            operateTeam = team
        end
    end
    local centerPos = operateTeam and operateTeam:GetFormationCenterPos()
    self:GetEnvironment():UpdateTeamCenterPosToRangeEvent(centerPos)
end

---@param unit SEUnit
function SETeamManager:IsUnitControlByTeam(unit)
    for _, team in pairs(self._mainPlayerTeam) do
        if team:IsUnitInTeam(unit) and team:IsControlUnit() then
            return true
        end
    end
    return false
end

function SETeamManager:GetPooledObjectCreateHelper()
    return self._pooledCreateHelper
end

function SETeamManager:GetCenterMoveSpeed()
    return self._teamMoveSpeed
end

function SETeamManager:GetTeamVXRadius(aliveHeroCount)
    if aliveHeroCount == 2 then
        return self._doubleTeamVxRadius
    elseif aliveHeroCount == 3 then
        return self._tripleTeamVxRadius
    end
    return self._singleTeamVxRadius
end

return SETeamManager