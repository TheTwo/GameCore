
local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateEscape:CitizenBubbleState
---@field new fun():CitizenBubbleStateEscape
---@field super CitizenBubbleState
local CitizenBubbleStateEscape = class('CitizenBubbleStateEscape', CitizenBubbleState)

function CitizenBubbleStateEscape:Enter()
    self._bubble = self._bubbleMgr:QueryBubble(2)
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        self._bubble:SetupEscape()
    end
end

return CitizenBubbleStateEscape