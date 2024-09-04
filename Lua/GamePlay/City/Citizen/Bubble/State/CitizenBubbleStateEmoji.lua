
local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateEmoji:CitizenBubbleState
---@field new fun():CitizenBubbleStateEmoji
---@field super CitizenBubbleState
local CitizenBubbleStateEmoji = class('CitizenBubbleStateEmoji', CitizenBubbleState)

function CitizenBubbleStateEmoji:Enter()
    self._bubble = self._bubbleMgr:QueryBubble(2)
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        self._bubble:SetupEmoji(self._host._emoji)
    end
end

function CitizenBubbleStateEmoji:Exit()
    self._host._emoji = false
    CitizenBubbleStateEmoji.super.Exit(self)
end

return CitizenBubbleStateEmoji