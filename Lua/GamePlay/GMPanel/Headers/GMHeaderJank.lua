local Time = CS.UnityEngine.Time

local GMHeader = require("GMHeader")

---@class GMHeaderJank:GMHeader
local GMHeaderJank = class('GMHeaderJank', GMHeader)

local TwoMovieFrameTime = 1.0 / 24 * 2
local ThreeMovieFrameTime = 1.0 / 24 * 2

function GMHeaderJank:ctor()
    GMHeader.ctor(self)

    self._jank = 0
    self._bigJank = 0
    self._lastFrameTime = nil
    self._lastFramesTime = {}
    self._avgLastThreeFrameTime = nil
end

function GMHeaderJank:DoText()
    return string.format(" Jank:%d, Big Jank:%d", self._jank, self._bigJank)
end

function GMHeaderJank:Tick()
    local timeNow = Time.realtimeSinceStartupAsDouble
    self:UpdateJankCount(timeNow)
end

function GMHeaderJank:UpdateJankCount(timeNow)
    if not self._lastFrameTime then
        self._lastFrameTime = timeNow
        return
    end
    local currentFrameTime = timeNow - self._lastFrameTime
    self._lastFrameTime = timeNow
    if not self._lastFramesTime[1] then
        self._lastFramesTime[1] = currentFrameTime
        return
    end
    local t = self._lastFramesTime[1]
    self._lastFramesTime[1] = currentFrameTime
    if not self._lastFramesTime[2] then
        self._lastFramesTime[2] = t
        return
    end
    t = self._lastFramesTime[2]
    self._lastFramesTime[2] = self._lastFramesTime[1]
    if not self._lastFramesTime[3] then
        self._lastFramesTime[3] = t
        return
    end
    self._lastFramesTime[3] = t
    if not self._avgLastThreeFrameTime then
        self._avgLastThreeFrameTime = (self._lastFramesTime[3] + self._lastFramesTime[2] + self._lastFramesTime[1]) / 3.0
        return
    end
    if currentFrameTime > (self._avgLastThreeFrameTime * 2) then
        if currentFrameTime > TwoMovieFrameTime then
            self._jank = self._jank + 1
        end
        if currentFrameTime > ThreeMovieFrameTime then
            self._bigJank = self._bigJank + 1
        end
    end
    self._avgLastThreeFrameTime = (self._lastFramesTime[3] + self._lastFramesTime[2] + self._lastFramesTime[1]) / 3.0
end

return GMHeaderJank