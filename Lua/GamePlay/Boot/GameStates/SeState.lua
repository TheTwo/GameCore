local State = require("State")
local SeScene = require("SeScene")
local SeJumpScene = require("SeJumpScene")
local SdkCrashlytics = require("SdkCrashlytics")

---@class SeState
local SeState = class("SeState", State)

SeState.Name = "SeState"
function SeState:Enter()
    if SdkCrashlytics then
        SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_ENTER")
    end
    g_Game.SceneManager:EnterScene(SeScene.Name)

    -- 关闭不在SE中显示的UI
    g_Game.UIAsyncManager:ClearDoNotShowInSEMediators()
end

function SeState:Exit()
    g_Game.SceneManager:ExitScene(SeScene.Name)
    g_Game.SceneManager:ExitScene(SeJumpScene.Name)
    if SdkCrashlytics then
        SdkCrashlytics.RecordCrashlyticsLog("GAME_STATE_MACHINE_[".. tostring(self.Name) .."]_EXIT")
    end
end

function SeState:Tick(dt)
    
end

function SeState:GetName()
    return SeState.Name
end

return SeState