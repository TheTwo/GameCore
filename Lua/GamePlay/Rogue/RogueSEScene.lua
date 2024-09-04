local Scene = require("Scene")
---@class RogueSEScene:Scene
---@field new fun():RogueSEScene
local RogueSEScene = class("RogueSEScene", Scene)
RogueSEScene.Name = "RogueSEScene"

local ModuleRefer = require("ModuleRefer")
local SEEnvironment = require("SEEnvironment")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local RogueSEStage = require("RogueSEStage")
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility

function RogueSEScene:GetTagName()
    return self.Name
end

function RogueSEScene:EnterScene()
    self.instId = 0 --TODO:
    self.presetIndex = 0 --TODO:
    self.waitStart = nil
    self:LoadScene()
    ModuleRefer.PerformanceModule:AddTag(self:GetTagName())
end

function RogueSEScene:ExitScene()
    self:UnloadStageAndDisposeEnv()
    self:UnloadScene()
    ModuleRefer.PerformanceModule:RemoveTag(self:GetTagName())
end

function RogueSEScene:Tick(dt)
    if not self.waitStart then return end

    self.waitStart = nil
    self:SetupEnvAndLoadStage()
end

function RogueSEScene:Release()

end

function RogueSEScene:IsLoaded()
    return self.loaded
end

function RogueSEScene:LoadScene()
    self.scenePath = "se_rogue"
    SceneLoadUtility.LoadSceneAsync(self.scenePath, function()
        self.waitStart = true
    end)
end

function RogueSEScene:UnloadScene()
    SceneLoadUtility.UnloadScene(self.scenePath)
    self.loaded = false
end

function RogueSEScene:SetupEnvAndLoadStage()
    local mapInfo = CS.SEMapInfo.GetInstance(0)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local camera = mapInfo:GetMainCamera()
    local mode = SEEnvironmentModeType.Roguelike
    local seEnv = SEEnvironment.Instance(true)
    seEnv:Init(self.instId, uiCamera, camera, mapInfo, self.presetIndex, mode)
    
    self.currentStage = self:CreateStage(seEnv)
    self.currentStage:LoadRoomsAsset()
end

function RogueSEScene:CreateStage(seEnv)
    local stage = RogueSEStage.new(self, seEnv)
    stage:InitRoom()
    return stage
end

function RogueSEScene:UnloadStageAndDisposeEnv()
    if self.currentStage then
        self.currentStage:Release()
        self.currentStage = nil
    end

    local ins = SEEnvironment.Instance()
    if ins then
        ins:Dispose()
    end
end

function RogueSEScene:CanLightRestart()
    return true
end

function RogueSEScene:OnLightRestartBegin()
    
end

function RogueSEScene:OnLightRestartEnd()
    
end

function RogueSEScene:OnLightRestartFailed()
    
end

return RogueSEScene