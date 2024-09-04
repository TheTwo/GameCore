local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")

local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateIndicator:CitizenBubbleState
---@field new fun():CitizenBubbleStateIndicator
---@field super CitizenBubbleState
local CitizenBubbleStateIndicator = class('CitizenBubbleStateIndicator', CitizenBubbleState)

function CitizenBubbleStateIndicator:Enter()
    self._delayExit = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:CitizenIndicatorPopFadeTime())
    self._bubble = self._bubbleMgr:QueryBubble(2)
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        self._bubble:SetupIndicatorChange(self._host._indicator[1])
    end
end

function CitizenBubbleStateIndicator:Tick(dt)
    CitizenBubbleStateIndicator.super.Tick(self, dt)
    self._delayExit = self._delayExit - dt
    if self._delayExit <= 0 then
         table.remove(self._host._indicator, 1)
    end
end

return CitizenBubbleStateIndicator