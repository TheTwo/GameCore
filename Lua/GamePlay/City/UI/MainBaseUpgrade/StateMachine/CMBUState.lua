local State = require("State")
---@class CMBUState:State
---@field new fun():CMBUState
local CMBUState = class("CMBUState", State)

---@param uiMediator CityMainBaseUpgradeUIMediator
function CMBUState:ctor(uiMediator)
    self.uiMediator = uiMediator
end

function CMBUState:OnContinueClick()
    ---Override Me
end

return CMBUState