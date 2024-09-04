local KingdomSceneState = require("KingdomSceneState")
---@class KingdomSceneStateEntryToMap:KingdomSceneState
---@field new fun():KingdomSceneStateEntryToMap
local KingdomSceneStateEntryToMap = class("KingdomSceneStateEntryToMap", KingdomSceneState)
KingdomSceneStateEntryToMap.Name = "KingdomSceneStateEntryToMap"
local KingdomSceneStateMap = require("KingdomSceneStateMap")
local EventConst = require("EventConst")

function KingdomSceneStateEntryToMap:Enter()
    KingdomSceneState.Enter(self)

    self.stateMachine:ChangeState(KingdomSceneStateMap.Name)
end

function KingdomSceneStateEntryToMap:Exit()
    g_Logger.Log('KingdomSceneStateEntryToMap:Exit trigger SCENE_LOADED')
    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOADED)

    KingdomSceneState.Exit(self)
end

function KingdomSceneStateEntryToMap:IsLoaded()
    return true
end

return KingdomSceneStateEntryToMap