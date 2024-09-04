local State = require("State")
local KingdomScene = require('KingdomScene')
local SdkCrashlytics = require("SdkCrashlytics")

---@class KingdomState : State
local KingdomState = class("KingdomState", State)

KingdomState.Name = "KingdomState"

function KingdomState:Enter()
    if SdkCrashlytics then
        SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_ENTER")
    end
    g_Game.SceneManager:EnterScene(KingdomScene.Name)
end

function KingdomState:Exit()
    g_Game.SceneManager:ExitScene(KingdomScene.Name)
    if SdkCrashlytics then
        SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_EXIT")
    end
end

function KingdomState:GetName()
    return KingdomState.Name
end

return KingdomState
