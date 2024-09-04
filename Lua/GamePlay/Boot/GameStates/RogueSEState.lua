local State = require("State")
---@class RogueSEState:State
local RogueSEState = class("RogueSEState", State)
local RogueSEScene = require("RogueSEScene")
local SdkCrashlytics = require("SdkCrashlytics")
RogueSEState.Name = "RogueSEState"

function RogueSEState:Enter()
    SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_ENTER")
    g_Game.SceneManager:EnterScene(RogueSEScene.Name)
end

function RogueSEState:Exit()
    g_Game.SceneManager:ExitScene(RogueSEScene.Name)
    SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_EXIT")
end

function RogueSEState:GetName()
    return self.Name
end

return RogueSEState