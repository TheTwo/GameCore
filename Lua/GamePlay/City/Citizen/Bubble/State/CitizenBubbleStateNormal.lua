local ConfigRefer = require("ConfigRefer")

local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateNormal:CitizenBubbleState
---@field new fun():CitizenBubbleStateNormal
---@field super CitizenBubbleState
local CitizenBubbleStateNormal = class('CitizenBubbleStateNormal', CitizenBubbleState)

function CitizenBubbleStateNormal:ctor(citizen)
    CitizenBubbleStateNormal.super.ctor(self, citizen)
    self._config = nil
end

function CitizenBubbleStateNormal:Enter()
    self:NextTryTipTime()
end

function CitizenBubbleStateNormal:Tick(dt)
    CitizenBubbleStateNormal.super.Tick(self, dt)
    if not self._citizen._assetReady then
        return
    end
    if self._nextTryTipTime then
        self._nextTryTipTime = self._nextTryTipTime - dt
        if self._nextTryTipTime <= 0 then
            self:RequestBubble()
            self:NextTryTipTime()
        end
    end
end

function CitizenBubbleStateNormal:NextTryTipTime()
    local tipTimeMin = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(1)
    local tipTimeMax = ConfigRefer.CityConfig:CitizenIdleBubbleIntervalRange(2)
    self._nextTryTipTime = math.random(tipTimeMin, tipTimeMax)
end

function CitizenBubbleStateNormal:RequestBubble()
    self._bubble,self._config = self._bubbleMgr:QueryBubble(0)
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        self._bubble:SetupBubbleConfig(self._config)
    end
end

return CitizenBubbleStateNormal