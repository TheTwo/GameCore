local GMHeader = require("GMHeader")

---@class GMHeaderKingdomSceneState:GMHeader
---@field new fun():GMHeaderKingdomSceneState
---@field super GMHeader
local GMHeaderKingdomSceneState = class('GMHeaderKingdomSceneState', GMHeader)

function GMHeaderKingdomSceneState:Init(panel)
    GMHeader.Init(self, panel)
    self._kingdomScene = require("KingdomMapUtils").GetKingdomScene()
end

function GMHeaderKingdomSceneState:DoText()
    if self._kingdomScene then
        if self._kingdomScene.stateMachine and self._kingdomScene.stateMachine.currentName then
            return self._kingdomScene.stateMachine.currentName
        end
    end
    return nil
end

function GMHeaderKingdomSceneState:Release()
    self._kingdomScene = nil
    GMHeader.Release(self) 
end

return GMHeaderKingdomSceneState

