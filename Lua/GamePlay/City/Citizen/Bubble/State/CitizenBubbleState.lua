local State = require("State")

---@class CitizenBubbleState:State
---@field new fun(citizen:CityUnitCitizen,host:CitizenBubbleStateMachine):CitizenBubbleState
---@field super State
local CitizenBubbleState = class('CitizenBubbleState', State)

---@param citizen CityUnitCitizen
---@param host CitizenBubbleStateMachine
function CitizenBubbleState:ctor(citizen, host)
    self._host = host
    self._citizen = citizen
    self._citizenMgr = citizen._data._mgr
    self._bubbleMgr = citizen._data._mgr._bubbleMgr
    ---@type CityCitizenBubbleHandle
    self._bubble = nil
end

function CitizenBubbleState:Tick(dt)
    if self._bubble then
        if self._bubble:Tick(dt) then
            self.stateMachine:ChangeState("CitizenBubbleStateNone")
        end
    end
end

function CitizenBubbleState:Exit()
    self._bubbleMgr:ReleaseBubble(self._bubble)
    self._bubble = nil
end

---@return CS.UnityEngine.Transform
function CitizenBubbleState:GetCurrentBubbleTrans()
    return nil
end

function CitizenBubbleState:OnClickIcon()
end

return CitizenBubbleState