local State = require("State")
local ModuleRefer = require('ModuleRefer')

---@class KingdomSceneState:State
---@field new fun():KingdomSceneState
---@field kingdomScene KingdomScene
local KingdomSceneState = class("KingdomSceneState", State)

function KingdomSceneState:ctor(kingdomScene)
    self.kingdomScene = kingdomScene
end

---@return string
function KingdomSceneState:GetName()
    if self.__class ~= nil then
        return self.__class.__cname
    end

    if self.__cname ~= nil then
        return self.__cname;
    end
    
    return ""
end

function KingdomSceneState:Enter()

end

function KingdomSceneState:Exit()
    
end

function KingdomSceneState:IsLoaded()
    return false
end

function KingdomSceneState:CanLightRestart()
    return false
end

function KingdomSceneState:OnLightRestart()
    
end

function KingdomSceneState:OnLightRestartFailed()
    
end

return KingdomSceneState